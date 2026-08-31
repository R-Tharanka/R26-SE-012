import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_config.dart';
import 'ai_leaf_service.dart' show LeafAnalysisException;
import 'pest_analysis.dart';

/// Sends a pepper-plant photo to AI for pest *vision*: identify the pest,
/// count how many are visible, judge infestation severity, and note the plant
/// part. Treatment is NOT requested — the [PestTreatmentEngine] owns it.
class AiPestService {
  static const List<String> _pestVocab = [
    'Healthy',
    'Diconocoris distanti',
    'Gynaikothrips karny',
    'Pterolopha annulata',
    'Other pest',
    'Uncertain',
  ];

  static const List<String> _plantParts = ['leaf', 'stem', 'berry', 'unknown'];

  late final GenerativeModel _model = GenerativeModel(
    model: AiConfig.model,
    apiKey: AiConfig.apiKey,
    systemInstruction: Content.system(_systemPrompt),
    generationConfig: GenerationConfig(
      temperature: 0.2,
      responseMimeType: 'application/json',
      responseSchema: _schema,
    ),
  );

  Future<PestAnalysis> analyze(Uint8List jpegBytes) async {
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
      throw LeafAnalysisException('AI returned no result.');
    }
    try {
      return PestAnalysis.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      throw LeafAnalysisException('Could not parse AI response:\n$text');
    }
  }

  static const String _systemPrompt = '''
You are an expert entomologist specialising in black pepper (Piper nigrum)
pests. You look at ONE photo of a pepper plant part (leaf, stem, or berry) and
report what you can see.

Rules:
- First decide if the image really shows a pepper plant part. If not, set
  is_pepper_plant to false and do not invent findings.
- Identify the pest. Choose pest_type from the allowed list only; use "Other
  pest" for a clear pest outside the list and "Uncertain" if unsure. Note that
  the pest insect may be small or hidden — you may infer presence from
  characteristic damage, but say so in affected_regions.
- pest_count is the number of pest individuals you can actually see (0 if only
  damage is visible).
- severity_percentage is the overall infestation severity including damage,
  0-100 (0 if healthy).
- plant_part: which part the photo shows.
- DO NOT recommend any pesticide, chemical, brand, dosage, or spraying. The
  application decides treatment. Only describe what you observe.
- Be honest about confidence; small pests are hard to judge from one photo.
''';

  static const String _taskPrompt =
      'Inspect this pepper plant photo for pests and return the JSON result. '
      'Do not suggest any treatment or chemical.';

  static final Schema _schema = Schema.object(
    properties: {
      'is_pepper_plant': Schema.boolean(
        description: 'True only if the image clearly shows a pepper plant part.',
      ),
      'healthy': Schema.boolean(description: 'True if no pest/damage is present.'),
      'pest_type': Schema.enumString(
        enumValues: _pestVocab,
        description: 'Best-matching pest label from the allowed list.',
      ),
      'plant_part': Schema.enumString(
        enumValues: _plantParts,
        description: 'Which plant part the photo shows.',
      ),
      'pest_count': Schema.integer(
        description: 'Number of pest individuals actually visible (0 if only damage).',
      ),
      'severity_percentage': Schema.number(
        description: 'Infestation severity including damage, 0-100.',
      ),
      'confidence': Schema.number(description: 'Confidence 0.0-1.0.'),
      'affected_regions': Schema.string(
        description: 'Short description of the pest/damage seen.',
      ),
      'summary': Schema.string(description: 'One plain sentence for the farmer.'),
    },
    requiredProperties: [
      'is_pepper_plant',
      'healthy',
      'pest_type',
      'plant_part',
      'pest_count',
      'severity_percentage',
      'confidence',
      'affected_regions',
      'summary',
    ],
  );
}
