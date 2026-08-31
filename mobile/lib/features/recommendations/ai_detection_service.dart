import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

import '../../core/services/yolo_detector.dart' show DetectionResult;
import '../../shared/models/detection.dart';
import '../../shared/models/scanner_model_config.dart';
import 'ai_config.dart';
import 'ai_leaf_service.dart' show LeafAnalysisException;
import 'claude_classifier_service.dart';

/// Runs multi-object detection with the AI: given a captured photo it finds
/// every object (e.g. each leaf), draws a box, and classifies it — returning a
/// [DetectionResult] that drops straight into the existing overlay/result view.
///
/// Per-class reference images from assets/data are sent as labeled exemplars so
/// the classification is grounded in real examples of each class.
class AiDetectionService {
  // domain id -> ordered [className, reference folder]. Class names match the
  // ScannerModelConfig class lists so labels/colors line up.
  static const Map<String, List<List<String>>> _refs = {
    'leaf': [
      ['Leaf Blight', 'assets/data/leaf/blight/'],
      ['Quick Wilt', 'assets/data/leaf/quick/'],
      ['Little Leaf', 'assets/data/leaf/little/'],
      ['Healthy leaves', 'assets/data/leaf/healthy/'],
    ],
    'berry': [
      ['lace_bug_damage', 'assets/data/berry/lace/'],
      ['healthy_berry', 'assets/data/berry/healthy/'],
    ],
    'pest': [
      ['Diconocoris distanti', 'assets/data/phest/diconocoris/'],
      ['Gynaikothrips karny', 'assets/data/phest/gynaikothrips/'],
      ['Pterolopha annulata', 'assets/data/phest/pterolopha/'],
      ['healthy', 'assets/data/phest/healthy/'],
    ],
    // Combined leaf + pest domain: the AI decides leaf-vs-pest, then the class.
    'plant': [
      ['Leaf Blight', 'assets/data/leaf/blight/'],
      ['Quick Wilt', 'assets/data/leaf/quick/'],
      ['Little Leaf', 'assets/data/leaf/little/'],
      ['Healthy leaves', 'assets/data/leaf/healthy/'],
      ['Diconocoris distanti', 'assets/data/phest/diconocoris/'],
      ['Gynaikothrips karny', 'assets/data/phest/gynaikothrips/'],
      ['Pterolopha annulata', 'assets/data/phest/pterolopha/'],
      ['healthy', 'assets/data/phest/healthy/'],
    ],
  };

  // Combined-domain class sets + colors (used when config.id == 'plant').
  static const List<String> leafClasses = [
    'Healthy leaves',
    'Leaf Blight',
    'Little Leaf',
    'Quick Wilt',
  ];
  static const List<String> pestClasses = [
    'Diconocoris distanti',
    'Gynaikothrips karny',
    'Pterolopha annulata',
    'healthy',
  ];
  static const Map<String, Color> _plantColors = {
    'Healthy leaves': Color(0xFF2ECC71),
    'Leaf Blight': Color(0xFFE74C3C),
    'Little Leaf': Color(0xFFE67E22),
    'Quick Wilt': Color(0xFF9B59B6),
    'Diconocoris distanti': Color(0xFFE74C3C),
    'Gynaikothrips karny': Color(0xFFE67E22),
    'Pterolopha annulata': Color(0xFF9B59B6),
    'healthy': Color(0xFF2ECC71),
  };

  /// True if [className] is one of the pest classes (vs a leaf-disease class).
  static bool isPestClass(String className) => pestClasses.contains(className);

  // Cache of resized reference exemplars per domain, loaded once.
  static final Map<String, List<_Exemplar>> _cache = {};

  /// Detects and classifies every object in [jpegBytes] for [config].
  ///
  /// [yoloPriors] are detections from the on-device trained model (normalized to
  /// the same upright frame). When present, each is matched to a crop by overlap
  /// and passed to the Claude classifier as a domain-trained second opinion.
  Future<DetectionResult> detect(
    Uint8List jpegBytes,
    ScannerModelConfig config, {
    List<Detection> yoloPriors = const [],
  }) async {
    if (!AiConfig.hasKey) {
      throw LeafAnalysisException('No AI key configured.');
    }

    final decoded = img.decodeImage(jpegBytes);
    if (decoded == null) {
      throw LeafAnalysisException('Could not read the captured photo.');
    }
    final upright = img.bakeOrientation(decoded);
    final frameSize = Size(upright.width.toDouble(), upright.height.toDouble());
    final shot = _resizedJpeg(upright, 1024);

    final isPlant = config.id == 'plant';
    final classNames = isPlant ? [...leafClasses, ...pestClasses] : config.classNames;
    final objectNoun = isPlant ? 'pepper leaf or pest' : config.label.toLowerCase();

    final exemplars = await _exemplars(config.id);

    final model = GenerativeModel(
      model: AiConfig.model,
      apiKey: AiConfig.apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
        responseSchema: _schema(classNames),
      ),
    );

    final parts = <Part>[
      TextPart('Reference examples of each class:'),
      for (final e in exemplars) ...[
        TextPart('Example — ${e.label}:'),
        DataPart('image/jpeg', e.bytes),
      ],
      TextPart(
        isPlant
            ? 'The photo below shows a black pepper plant. First decide, per '
                'object, whether it is a LEAF (disease) or a PEST, then give each '
                'object a bounding box (normalized 0-1000 as ymin,xmin,ymax,xmax) '
                'and the single best-matching class from: ${classNames.join(", ")}.'
            : 'Now find and classify EVERY $objectNoun object in the photo below. '
                'Return one detection per object with a bounding box (normalized '
                '0-1000 as ymin,xmin,ymax,xmax) and the best-matching class from: '
                '${classNames.join(", ")}.',
      ),
      DataPart('image/jpeg', shot),
    ];

    final sw = Stopwatch()..start();
    final GenerateContentResponse res;
    try {
      res = await model.generateContent([Content.multi(parts)]);
    } on Exception catch (e) {
      throw LeafAnalysisException('AI request failed: $e');
    }
    sw.stop();

    final text = res.text?.trim();
    if (text == null || text.isEmpty) {
      throw LeafAnalysisException('AI returned no result.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw LeafAnalysisException('Could not parse AI response.');
    }

    // Out-of-distribution gate: if the photo isn't a pepper plant of this type
    // (a dog, another plant, an object…), block it — return nothing rather than
    // force a bogus classification.
    if (json['is_relevant'] == false) {
      return DetectionResult(const [], frameSize, sw.elapsedMilliseconds);
    }

    final list = (json['detections'] as List?) ?? const [];
    final dets = <Detection>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final label = (raw['label'] ?? '').toString();
      int classId = classNames.indexOf(label);
      if (classId < 0) classId = 0;
      final resolvedLabel = label.isEmpty ? classNames[classId] : label;
      final color = isPlant
          ? (_plantColors[resolvedLabel] ?? const Color(0xFFE67E22))
          : config.colorFor(classId);
      double n(Object? v) =>
          (v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0) / 1000.0;
      final l = n(raw['xmin']).clamp(0.0, 1.0);
      final t = n(raw['ymin']).clamp(0.0, 1.0);
      final r = n(raw['xmax']).clamp(0.0, 1.0);
      final b = n(raw['ymax']).clamp(0.0, 1.0);
      if (r <= l || b <= t) continue;
      final conf = raw['confidence'];
      dets.add(Detection(
        classId: classId,
        className: resolvedLabel,
        score: conf is num ? conf.toDouble() : 0.9,
        rect: Rect.fromLTRB(l, t, r, b),
        color: color,
      ));
    }

    // Second stage: re-classify each detected crop with Claude for higher
    // fine-grained accuracy. Gemini keeps ownership of the boxes + OOD gate;
    // Claude only refines the labels. Any failure → keep Gemini's labels.
    var result = dets;
    if (AiConfig.hasClaudeKey && dets.isNotEmpty) {
      try {
        result = await _refineWithClaude(
          upright,
          dets,
          config,
          isPlant,
          classNames,
          exemplars,
          yoloPriors,
        );
      } catch (_) {
        result = dets;
      }
    }

    return DetectionResult(result, frameSize, sw.elapsedMilliseconds);
  }

  // ---- Claude crop refinement ----
  Future<List<Detection>> _refineWithClaude(
    img.Image upright,
    List<Detection> dets,
    ScannerModelConfig config,
    bool isPlant,
    List<String> classNames,
    List<_Exemplar> exemplars,
    List<Detection> yoloPriors,
  ) async {
    const maxCrops = 20;
    // If a photo has a huge number of objects, classify the largest ones and
    // leave the rest on Gemini's labels (keeps the payload/latency bounded).
    final ordered = [...dets]
      ..sort((a, b) => _area(b.rect).compareTo(_area(a.rect)));
    final chosen = ordered.take(maxCrops).toList();
    final indexOf = {for (var i = 0; i < dets.length; i++) dets[i]: i};

    final crops = <ClaudeCrop>[];
    for (final d in chosen) {
      final id = indexOf[d]! + 1; // 1-based id shared with the prompt
      final crop = _cropJpeg(upright, d.rect, pad: 0.06, maxDim: 448);
      if (crop != null) {
        crops.add(ClaudeCrop(id, crop, prior: _priorFor(d.rect, yoloPriors)));
      }
    }
    if (crops.isEmpty) return dets;

    // Plant domain asks two independent questions (disease + pest) so a leaf
    // with both is labeled for each; other domains ask a single class question.
    final aspects = isPlant
        ? const [_diseaseAspect, _pestAspect]
        : [
            ClaudeAspect(
              key: 'class',
              noun: config.label.toLowerCase(),
              classes: classNames,
              hints: _classHints(config.id),
            ),
          ];

    final results = await ClaudeClassifierService().classify(
      overviewJpeg: _resizedJpeg(upright, 1024),
      crops: crops,
      exemplars: [
        for (final e in exemplars)
          ClaudeExemplar(e.label, e.bytes, note: _captions[e.label] ?? '')
      ],
      aspects: aspects,
      objectNoun: isPlant ? 'pepper leaf' : config.label.toLowerCase(),
    );
    if (results.isEmpty) return dets;

    final out = <Detection>[];
    for (var i = 0; i < dets.length; i++) {
      final det = dets[i];
      final r = results[i + 1];
      if (r == null) {
        out.add(det); // not sent / no answer → keep Gemini label
        continue;
      }
      if (isPlant) {
        final disease = r['disease'];
        final pest = r['pest'];
        var added = false;
        if (disease != null && disease.isPositive) {
          out.add(_plantDet(det, disease.label, disease.confidence));
          added = true;
        }
        if (pest != null && pest.isPositive) {
          out.add(_plantDet(det, pest.label, pest.confidence));
          added = true;
        }
        if (!added) {
          final bothUncertain = (disease?.isUncertain ?? true) &&
              (pest?.isUncertain ?? true);
          if (bothUncertain) continue; // can't tell → drop rather than mislabel
          out.add(_plantDet(det, 'Healthy leaves', 0.9)); // no problem found
        }
      } else {
        final v = r['class'];
        if (v == null) {
          out.add(det);
          continue;
        }
        if (v.isUncertain) continue;
        int classId = classNames.indexOf(v.label);
        if (classId < 0) classId = det.classId;
        out.add(Detection(
          classId: classId,
          className: v.label,
          score: v.confidence,
          rect: det.rect,
          color: config.colorFor(classId),
        ));
      }
    }
    return out;
  }

  // Builds a plant-domain detection (leaf disease or pest) for [det]'s box.
  Detection _plantDet(Detection det, String label, double conf) {
    final all = [...leafClasses, ...pestClasses];
    int classId = all.indexOf(label);
    if (classId < 0) classId = det.classId;
    return Detection(
      classId: classId,
      className: label,
      score: conf,
      rect: det.rect,
      color: _plantColors[label] ?? const Color(0xFFE67E22),
    );
  }

  static const _diseaseAspect = ClaudeAspect(
    key: 'disease',
    noun: 'leaf disease',
    classes: ['Leaf Blight', 'Little Leaf', 'Quick Wilt'],
    hints: _diseaseHints,
  );
  static const _pestAspect = ClaudeAspect(
    key: 'pest',
    noun: 'pest or pest damage',
    classes: [
      'Diconocoris distanti',
      'Gynaikothrips karny',
      'Pterolopha annulata',
    ],
    hints: _pestHints,
  );

  static double _area(Rect r) => r.width * r.height;

  // Best-overlapping trained-model detection for [rect], as a short hint string
  // ("local model: Leaf Blight 0.82"), or '' if nothing overlaps enough.
  static String _priorFor(Rect rect, List<Detection> priors) {
    Detection? best;
    var bestIou = 0.30; // require a meaningful overlap
    for (final p in priors) {
      final i = _iou(rect, p.rect);
      if (i > bestIou) {
        bestIou = i;
        best = p;
      }
    }
    if (best == null) return '';
    return 'local model: ${best.className} '
        '${(best.score.clamp(0.0, 1.0) * 100).round()}%';
  }

  static double _iou(Rect a, Rect b) {
    final x1 = a.left > b.left ? a.left : b.left;
    final y1 = a.top > b.top ? a.top : b.top;
    final x2 = a.right < b.right ? a.right : b.right;
    final y2 = a.bottom < b.bottom ? a.bottom : b.bottom;
    final iw = x2 - x1, ih = y2 - y1;
    if (iw <= 0 || ih <= 0) return 0;
    final inter = iw * ih;
    final union = _area(a) + _area(b) - inter;
    return union <= 0 ? 0 : inter / union;
  }

  // Crops [rect] (normalized 0..1) from [src] with a little padding and returns
  // a resized JPEG, or null if the region is degenerate.
  static Uint8List? _cropJpeg(img.Image src, Rect rect,
      {double pad = 0.06, int maxDim = 448}) {
    final w = src.width, h = src.height;
    final l = ((rect.left - pad) * w).clamp(0, w - 1).round();
    final t = ((rect.top - pad) * h).clamp(0, h - 1).round();
    final r = ((rect.right + pad) * w).clamp(1, w).round();
    final b = ((rect.bottom + pad) * h).clamp(1, h).round();
    final cw = r - l, ch = b - t;
    if (cw < 8 || ch < 8) return null;
    final cropped = img.copyCrop(src, x: l, y: t, width: cw, height: ch);
    return _resizedJpeg(cropped, maxDim);
  }

  // ---- reference exemplars ----
  Future<List<_Exemplar>> _exemplars(String domainId) async {
    if (_cache.containsKey(domainId)) return _cache[domainId]!;
    final spec = _refs[domainId] ?? const [];
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    // Send up to 6 exemplars per class so subtle look-alikes (e.g. Quick Wilt
    // vs Leaf Blight) are well grounded. These reference blocks are prompt-cached
    // by the Claude classifier, so the extra images are only paid for once.
    const perClass = 6;

    final out = <_Exemplar>[];
    for (final entry in spec) {
      final label = entry[0];
      final folder = entry[1];
      final matches = assets.where((a) => a.startsWith(folder) && _isImage(a))
          .toList()
        ..sort();
      for (final match in matches.take(perClass)) {
        final data = await rootBundle.load(match);
        final decoded = img.decodeImage(data.buffer.asUint8List());
        if (decoded == null) continue;
        out.add(
            _Exemplar(label, _resizedJpeg(img.bakeOrientation(decoded), 384)));
      }
    }
    _cache[domainId] = out;
    return out;
  }

  static bool _isImage(String a) {
    final l = a.toLowerCase();
    return l.endsWith('.jpg') || l.endsWith('.jpeg') || l.endsWith('.png');
  }

  static Uint8List _resizedJpeg(img.Image src, int maxDim) {
    final longest = src.width > src.height ? src.width : src.height;
    final scaled = longest > maxDim
        ? img.copyResize(src,
            width: src.width >= src.height ? maxDim : null,
            height: src.height > src.width ? maxDim : null)
        : src;
    return Uint8List.fromList(img.encodeJpg(scaled, quality: 85));
  }

  static const String _systemPrompt = '''
You are a plant vision system for black pepper. You are shown labeled reference
photos of each class, then a target photo.

First decide if the target photo actually shows the expected black pepper part
(leaf, berry cluster, or pest on a pepper plant). If it does NOT — a different
plant, an animal, a person, an object, or an unclear/blank image — set
is_relevant to false and return an empty detections list. Never classify a
non-pepper subject.

If it is relevant, set is_relevant to true and detect EVERY matching object
(there may be several — classify all of them), giving each a tight bounding box
and the single best-matching class from the allowed list.

Be accurate — study the reference photos closely and compare symptoms
feature-by-feature before deciding. Distinguishing cues:
- Leaf Blight: DISCRETE brown/black spots or lesions on an otherwise firm, green
  leaf — often ringed by a yellow halo or with concentric rings. The leaf's shape
  and turgor look normal apart from the spots.
- Quick Wilt (Phytophthora foot rot): the WHOLE leaf/vine is unhealthy —
  drooping, dull, yellowing or browning broadly, with dark water-soaked lesions
  that spread from the leaf tip or margin with a feathery / frilled (fimbriate)
  advancing edge, and rapid defoliation. Judge overall leaf health, not one spot.
- Little Leaf: abnormally small, narrow or deformed leaves (a growth disorder).
- Healthy leaves: uniform green, no lesions, normal shape.
- Pests: a visible insect, OR its damage — fine pale stippling, bronzing or
  scarring. Only choose a pest class if that evidence is present.

Leaf Blight vs Quick Wilt tie-breaker (a common confusion): localized spots on a
healthy-looking, turgid leaf = Leaf Blight; broad wilting / yellow-brown collapse
or a spreading feathery margin lesion = Quick Wilt. When the two are close, weight
the reference photos of each class heavily and match the OVERALL pattern, not a
single dark patch.
A photo usually contains MANY leaves — return a SEPARATE detection (its own box
and class) for EVERY distinct leaf you can see, including partially visible,
background and overlapping ones. Do not merge several leaves into one box and do
not report only the main/front leaf; aim to cover them all.

A single leaf can also have BOTH a disease and pest damage — return a separate
detection for each. Match reference symptoms carefully; do not guess. Return
only the structured result.
''';

  // Single-class cues for non-plant domains (berry). The combined leaf+pest
  // domain uses _diseaseHints / _pestHints via its two aspects instead.
  static String _classHints(String domainId) {
    if (domainId == 'berry') return _berryHints;
    return '';
  }

  static const String _berryHints = '''
- lace_bug_damage: damage from pepper lace bug (Diconocoris) feeding on the spike.
  IMPORTANT: this shows on GREEN, still-immature spikes too — do NOT assume a
  green spike is healthy. Signs at ANY colour stage: an uneven / gappy / SPARSE
  berry set, missing or aborted berries leaving bare stretches of axis, berries
  that are malformed, undersized, wrinkled, flattened or lopsided, small brown or
  black feeding spots / stippling / scarring on otherwise green berries, and
  (later) blackening, drying or shrivelling. ANY of these = lace_bug_damage.
- healthy_berry: a spike DENSELY and EVENLY packed with plump, round, uniform
  berries of consistent size along an intact axis — NO gaps, NO missing/aborted
  berries, NO deformity, NO spots — whether green or ripening.
Tie-breaker: judge the BERRY SET and berry SHAPE, not the colour. A green spike
with irregular spacing, gaps, bare axis, or misshapen/undersized berries is
lace_bug_damage, NOT healthy. Green does not mean healthy.''';

  static const String _diseaseHints = '''
- Leaf Blight (anthracnose, Colletotrichum): well-defined angular-to-circular
  lesions that begin as pale-green/yellow spots and merge; the centre turns brown
  and PAPERY, ringed by a yellow (chlorotic) halo, sometimes with concentric
  rings and tiny black dots (fungal acervuli) at the centre. The leaf is
  otherwise firm, turgid and normal in shape; it does NOT wilt or collapse.
- Quick Wilt (Phytophthora capsici foot rot): lesions start as dark, WATER-SOAKED
  patches that enlarge FAST into large dark-brown blotches with a FIMBRIATE
  (frayed / feathery / fringed) advancing margin, sometimes a greyish or pale
  whitish centre and faint concentric zoning. It comes WITH whole-leaf trouble —
  broad yellowing, flaccid drooping/wilting and defoliation. Judge the overall
  collapse, not a single spot.
- Little Leaf (phytoplasma): judged mainly by SIZE RELATIVE TO OTHER LEAVES — the
  affected leaf is clearly SMALLER and narrower than the mature leaves around it,
  usually with shortened internodes and small, crinkled/cupped/deformed, pale or
  yellow-green leaves clustered bushily. ALWAYS compare it against the
  neighbouring leaves in the full context photo before deciding.
  HARD RULE: if the photo shows only ONE leaf (no other leaves visible to compare
  against), it can NEVER be Little Leaf — choose another disease or None instead.
  Only call Little Leaf when clearly larger leaves are present to compare with.
- None: a FLAT, smooth, full-sized normal-green leaf — no papery/haloed spots,
  no water-soaked fringed lesion, no puckering/shrinkage.
Tie-breakers:
- Leaf Blight vs Quick Wilt: Blight = crisp spot(s) with a PAPERY brown centre +
  yellow halo on a firm, un-wilted leaf; Quick Wilt = WATER-SOAKED, fast-spreading
  dark patch with a FRINGED margin PLUS overall yellowing / drooping / wilting.
- Little Leaf vs None: COMPARE SIZES — a leaf clearly smaller than its
  neighbours (with crinkling/deformity) = Little Leaf; a full-sized leaf, or a
  LONE leaf with nothing to compare against, = None (never Little Leaf on a
  single leaf).''';

  static const String _pestHints = '''
- Diconocoris distanti (pepper lace bug — a SUCKING bug): brown, irregular spots
  and blotches on leaves and spikes; on flower spikes / young berries a brown-to-
  black discoloration, wilting and greying, with spikes drying up and dropping and
  unfilled/empty seeds. The insect itself is a small grey-black bug with horn-like
  projections on its shoulders, or pale-brown spiny nymphs on the undersides.
- Gynaikothrips karny (gall / leaf thrips — SUCKING & rasping): leaves CURL or
  FOLD (often along the midrib) and form galls; fine silvery stippling and
  scratches with dark brown / reddish / purplish scarring, mainly on the
  undersides; foliage becomes distorted, curled and discoloured.
- Pterolopha annulata (a longhorn BEETLE — CHEWING): removed leaf tissue —
  irregular chewed holes and notched / ragged leaf margins; the adult is a
  mottled bark-brown beetle with long antennae, larvae may bore stems.
- None: no insect and no feeding damage — no holes, stippling, curling, galls or
  brown/black feeding discoloration.
Damage type tells them apart: brown spots/discoloration on leaf & spike = lace
bug; curling/folding, galls and silvery scarring = thrips; actual chewed holes /
notched margins = beetle. A leaf can show pest damage with no visible insect —
judge by the damage.''';

  // Short distinguishing notes attached to each reference exemplar image.
  static const Map<String, String> _captions = {
    'Leaf Blight': 'papery brown lesion centre + yellow halo on a firm leaf',
    'Quick Wilt': 'water-soaked dark patch, fringed margin + whole-leaf '
        'yellowing/wilting',
    'Little Leaf': 'small, crinkled/contracted, cupped blade, abnormally small '
        'vs neighbouring leaves',
    'Healthy leaves': 'flat, uniform green, no lesions, full size, normal shape',
    'Diconocoris distanti': 'lace bug; brown irregular spots/discoloration on '
        'leaf & spike',
    'Gynaikothrips karny': 'gall thrips; leaf curl/fold, silvery scarring',
    'Pterolopha annulata': 'longhorn beetle; chewed holes / notched leaf margins',
    'healthy': 'no pest and no feeding damage',
    'lace_bug_damage': 'uneven/gappy berry set, malformed or spotted berries — '
        'incl. GREEN spikes; not just black/dried',
    'healthy_berry': 'densely, evenly packed plump uniform berries, no gaps or '
        'deformity',
  };

  static Schema _schema(List<String> classNames) => Schema.object(
        properties: {
          'is_relevant': Schema.boolean(),
          'detections': Schema.array(
            items: Schema.object(
              properties: {
                'label': Schema.enumString(enumValues: classNames),
                'confidence': Schema.number(),
                'ymin': Schema.number(),
                'xmin': Schema.number(),
                'ymax': Schema.number(),
                'xmax': Schema.number(),
              },
              requiredProperties: [
                'label',
                'confidence',
                'ymin',
                'xmin',
                'ymax',
                'xmax',
              ],
            ),
          ),
        },
        requiredProperties: ['is_relevant', 'detections'],
      );
}

class _Exemplar {
  final String label;
  final Uint8List bytes;
  _Exemplar(this.label, this.bytes);
}
