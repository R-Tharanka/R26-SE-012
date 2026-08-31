import 'dart:convert';
import 'dart:typed_data';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';

import 'ai_config.dart';

/// One cropped object to classify, tagged with a stable id. [prior] is an
/// optional hint from the on-device trained model, e.g. "local model: Leaf
/// Blight 82%", shown to Claude alongside the crop.
class ClaudeCrop {
  final int id;
  final Uint8List jpeg;
  final String prior;

  const ClaudeCrop(this.id, this.jpeg, {this.prior = ''});
}

/// A labeled reference exemplar, optionally annotated with distinguishing cues.
class ClaudeExemplar {
  final String label;
  final Uint8List jpeg;
  final String note;

  const ClaudeExemplar(this.label, this.jpeg, {this.note = ''});
}

/// One question asked about every crop. Single-label domains use one aspect;
/// the combined leaf/pest domain uses separate disease and pest aspects.
class ClaudeAspect {
  final String key;
  final String noun;
  final List<String> classes;
  final String hints;

  const ClaudeAspect({
    required this.key,
    required this.noun,
    required this.classes,
    this.hints = '',
  });
}

/// Claude's verdict for one aspect of one crop.
class ClaudeVerdict {
  final String label;
  final double confidence;

  const ClaudeVerdict(this.label, this.confidence);

  bool get isNone => label.toLowerCase() == 'none';
  bool get isUncertain => label.toLowerCase() == 'uncertain';
  bool get isPositive => !isNone && !isUncertain;
}

/// Second-stage classifier. It is optional: absent keys or thrown errors leave
/// the caller on the first-stage labels.
class ClaudeClassifierService {
  Future<Map<int, Map<String, ClaudeVerdict>>> classify({
    required Uint8List overviewJpeg,
    required List<ClaudeCrop> crops,
    required List<ClaudeExemplar> exemplars,
    required List<ClaudeAspect> aspects,
    required String objectNoun,
  }) async {
    if (!AiConfig.hasClaudeKey || crops.isEmpty || aspects.isEmpty) {
      return const {};
    }

    final client = AnthropicClient(apiKey: AiConfig.claudeApiKey);
    final blocks = <Block>[
      const Block.text(
        text:
            'You are grading a black pepper plant. Below are annotated reference '
            'photos of each class, then the full photo for context, then individual '
            'cropped objects numbered by id. Study the references and their notes '
            'feature-by-feature before deciding.',
      ),
      const Block.text(text: 'Reference examples:'),
    ];

    for (var i = 0; i < exemplars.length; i++) {
      final e = exemplars[i];
      final isLast = i == exemplars.length - 1;
      blocks.add(
        Block.text(
          text: 'Reference - ${e.label}${e.note.isEmpty ? '' : ': ${e.note}'}',
        ),
      );
      blocks.add(_img(e.jpeg, cache: isLast));
    }

    blocks
      ..add(
        const Block.text(
          text:
              'Full photo for context. Do not classify it directly, but use it '
              'to judge each crop size and shape relative to surrounding leaves. '
              'A leaf clearly smaller than its neighbours is a strong Little Leaf '
              'signal; if the photo shows only one leaf with nothing to compare '
              'against, no crop can be Little Leaf:',
        ),
      )
      ..add(_img(overviewJpeg))
      ..add(
        Block.text(
          text:
              'Now assess each cropped $objectNoun below. Each crop is one object.',
        ),
      );

    for (final c in crops) {
      blocks
        ..add(
          Block.text(
            text: 'Object id ${c.id}${c.prior.isEmpty ? '' : ' - ${c.prior}'}:',
          ),
        )
        ..add(_img(c.jpeg));
    }
    blocks.add(Block.text(text: _instruction(aspects)));

    try {
      final res = await client.createMessage(
        request: CreateMessageRequest(
          model: Model.modelId(AiConfig.claudeModel),
          maxTokens: 6000,
          temperature: 0.1,
          messages: [
            Message(
              role: MessageRole.user,
              content: MessageContent.blocks(blocks),
            ),
          ],
        ),
      );
      return _parse(res.content.text, aspects);
    } finally {
      client.endSession();
    }
  }

  static Block _img(Uint8List jpeg, {bool cache = false}) => Block.image(
        source: ImageBlockSource(
          data: base64Encode(jpeg),
          mediaType: ImageBlockSourceMediaType.imageJpeg,
          type: ImageBlockSourceType.base64,
        ),
        cacheControl: cache ? const CacheControlEphemeral() : null,
      );

  static String _instruction(List<ClaudeAspect> aspects) {
    final b = StringBuffer()
      ..writeln('For each object id, answer every question below:');
    for (final a in aspects) {
      b.writeln('- "${a.key}": which ${a.noun} is present? Choose one of '
          '[${a.classes.join(", ")}], or "None" if this object shows no '
          '${a.noun}.');
      if (a.hints.isNotEmpty) b.writeln('  cues:\n${_indent(a.hints)}');
    }
    b
      ..writeln()
      ..writeln('An object can be positive for more than one question, so answer '
          'each question independently. Use "Uncertain" only if you genuinely '
          'cannot tell.')
      ..writeln('Match against the reference photos, not prior assumptions; '
          'judge each crop on its own.')
      ..writeln('Some objects include a suggestion from an on-device model '
          'trained on these exact classes. Treat it as a strong hint when the '
          'crop is ambiguous, but override it if the crop and reference photos '
          'clearly disagree.')
      ..writeln()
      ..writeln('Respond with only a JSON object, no prose, no markdown fences:');
    final shape = aspects
        .map((a) => '"${a.key}":{"label":"<class or None>","confidence":0.0}')
        .join(',');
    b.writeln('{"results":[{"id":1,$shape}]}');
    return b.toString();
  }

  static String _indent(String s) =>
      s.split('\n').map((line) => '    $line').join('\n');

  static Map<int, Map<String, ClaudeVerdict>> _parse(
    String? text,
    List<ClaudeAspect> aspects,
  ) {
    if (text == null || text.trim().isEmpty) return const {};
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }

    final list = (json['results'] as List?) ?? const [];
    final lookups = {
      for (final aspect in aspects)
        aspect.key: {
          for (final className in aspect.classes) className.toLowerCase(): className,
        },
    };
    final out = <int, Map<String, ClaudeVerdict>>{};

    for (final raw in list) {
      if (raw is! Map) continue;
      final id = raw['id'];
      if (id is! num) continue;

      final perAspect = <String, ClaudeVerdict>{};
      for (final aspect in aspects) {
        final cell = raw[aspect.key];
        if (cell is! Map) continue;

        final rawLabel = (cell['label'] ?? '').toString().trim();
        final lower = rawLabel.toLowerCase();
        final label = lookups[aspect.key]![lower] ??
            (lower == 'none'
                ? 'None'
                : lower == 'uncertain'
                    ? 'Uncertain'
                    : rawLabel);
        final confidence = cell['confidence'];
        perAspect[aspect.key] = ClaudeVerdict(
          label,
          confidence is num
              ? confidence.toDouble().clamp(0.0, 1.0).toDouble()
              : 0.8,
        );
      }

      if (perAspect.isNotEmpty) {
        out[id.toInt()] = perAspect;
      }
    }

    return out;
  }
}
