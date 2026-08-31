import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_config.dart';
import 'leaf_analysis.dart';

/// Thrown when analysis can't run or AI returns something unusable.
class LeafAnalysisException implements Exception {
  final String message;
  LeafAnalysisException(this.message);
  @override
  String toString() => message;
}

/// Sends a captured black-pepper leaf photo to AI and returns a structured
/// [LeafAnalysis] (disease type, severity, treatments).
///
/// AI is constrained with a JSON response schema so the output is reliable
/// to parse, and with a domain system-prompt so it behaves like a pepper
/// agronomist rather than a generic chatbot.
class AiLeafService {
  // The disease vocabulary AI must choose from — the app's known leaf
  // classes plus the common non-fungal cases and safe fallbacks.
  static const List<String> _diseaseVocab = [
    'Healthy leaves',
    'Leaf Blight',
    'Little Leaf',
    'Quick Wilt',
    'Nutrient deficiency',
    'Other disease',
    'Uncertain',
  ];

  static const List<String> _severityBands = ['none', 'mild', 'moderate', 'severe'];

  // Configure the Gemini Generative AI model
  // The system prompt tells the AI to behave like a black pepper agronomist
  late final GenerativeModel _model = GenerativeModel(
    model: AiConfig.model,
    apiKey: AiConfig.apiKey,
    systemInstruction: Content.system(_systemPrompt),
    generationConfig: GenerationConfig(
      temperature: 0.2, // deterministic, factual
      responseMimeType: 'application/json',
      responseSchema: _schema,
    ),
  );

  Future<LeafAnalysis> analyze(Uint8List jpegBytes) async {
    if (!AiConfig.hasKey) {
      throw LeafAnalysisException(
        'No AI API key. Run with --dart-define=GEMINI_API_KEY=your_key',
      );
    }

    final GenerateContentResponse res;
    try {
      res = await _model.generateContent([
        Content.multi([
          TextPart(_taskPrompt),
          DataPart('image/jpeg', jpegBytes),
        ]),
      ]);
    } on Exception catch (e) {
      throw LeafAnalysisException('AI request failed: $e');
    }

    final text = res.text?.trim();
    if (text == null || text.isEmpty) {
      throw LeafAnalysisException(
        'AI returned no result (possibly blocked or empty).',
      );
    }

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return LeafAnalysis.fromJson(json);
    } catch (_) {
      throw LeafAnalysisException('Could not parse AI response:\n$text');
    }
  }

  // ---- prompts & schema ----

  static const String _systemPrompt = '''
You are an expert agronomist specialising in black pepper (Piper nigrum) leaf
diseases. You analyse a single close-up photo of a pepper leaf and report the
disease, an estimate of how much of the leaf area is affected, and practical
treatment steps a smallholder farmer can follow.

Rules:
- First decide if the image really shows a black pepper leaf. If it shows soil,
  a hand, a different plant, or is too blurry/dark to judge, set is_pepper_leaf
  to false and do not invent a diagnosis.
- Choose disease_type from the allowed list only. Use "Uncertain" if you cannot
  tell, "Other disease" for a clear disease outside the list, and
  "Nutrient deficiency" for diffuse discoloration rather than lesions.
- severity_percentage is computed by AREA: estimate the affected leaf area
  (lesions, spots, blight, discoloration) as a fraction of the WHOLE leaf area,
  then express it 0-100. Compare the damaged area against the total leaf, e.g. a
  leaf with roughly a third of its surface affected is ~33%. For a healthy leaf
  use 0.
- Map severity to a band: none (0), mild (1-15), moderate (16-40), severe (>40).
- treatments: 2-5 concrete, ordered, low-cost steps. Prefer cultural/organic
  measures first, then chemical options with the active ingredient named. Do
  NOT give exact dosages. Keep each step to one short sentence.
- Be honest about confidence. A single photo has limits.
''';

  static const String _taskPrompt =
      'Analyse this black pepper leaf photo and return the JSON result.';

  static final Schema _schema = Schema.object(
    properties: {
      'is_pepper_leaf': Schema.boolean(
        description: 'True only if the image clearly shows a black pepper leaf.',
      ),
      'healthy': Schema.boolean(
        description: 'True if the leaf shows no disease or deficiency.',
      ),
      'disease_type': Schema.enumString(
        enumValues: _diseaseVocab,
        description: 'The single best-matching label from the allowed list.',
      ),
      'severity_percentage': Schema.number(
        description: 'Percent of leaf area affected, 0-100.',
      ),
      'severity_band': Schema.enumString(
        enumValues: _severityBands,
        description: 'Severity bucket derived from the percentage.',
      ),
      'confidence': Schema.number(
        description: 'Confidence in the diagnosis, 0.0-1.0.',
      ),
      'affected_regions': Schema.string(
        description: 'Short description of where/what the symptoms are.',
      ),
      'treatments': Schema.array(
        items: Schema.string(),
        description: '2-5 ordered treatment steps.',
      ),
      'summary': Schema.string(
        description: 'One plain-language sentence for the farmer.',
      ),
    },
    requiredProperties: [
      'is_pepper_leaf',
      'healthy',
      'disease_type',
      'severity_percentage',
      'severity_band',
      'confidence',
      'affected_regions',
      'treatments',
      'summary',
    ],
  );
}
