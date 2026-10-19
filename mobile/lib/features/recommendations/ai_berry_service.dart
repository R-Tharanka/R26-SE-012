// =============================================================================
// File: ai_berry_service.dart
// Purpose: Provides the ai berry service application service.
// =============================================================================
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/locale/app_locale.dart';
import 'berry_analysis.dart';
import 'ai_config.dart';
import 'ai_leaf_service.dart' show LeafAnalysisException;

/// Sends a pepper-berry cluster photo to AI for the *vision* task only:
/// judge damage severity visually, name the problem. Treatment is intentionally
/// NOT requested — the app's [RemediationEngine] owns that so an LLM can never
/// suggest an export-banned chemical.
class AiBerryService {
  static const List<String> _problemVocab = [
    'Healthy',
    'Lace bug damage',
    'Other damage',
    'Uncertain',
  ];

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

  Future<BerryAnalysis> analyze(Uint8List jpegBytes) async {
    // Analyze the selected image and return its result.
    if (!AiConfig.hasKey) {
      throw LeafAnalysisException(
        'No AI API key. Run with --dart-define=GEMINI_API_KEY=your_key',
      );
    }

    final GenerateContentResponse res;
    try {
      res = await _model.generateContent([
        Content.multi([
          TextPart(
            '$_taskPrompt\n\nWrite summary and affected_regions in '
            '${currentPromptLanguage()}. Keep problem_type exactly as the '
            'allowed English values.',
          ),
          DataPart('image/jpeg', jpegBytes), // PASSED THE IMAGE TO THE LLM
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
      return BerryAnalysis.fromJson(jsonDecode(text) as Map<String, dynamic>); //Severity passed to the berry_analysis.dart 
    } catch (_) {
      throw LeafAnalysisException('Could not parse AI response:\n$text');
    }
  }

  static const String _systemPrompt = '''
You are an expert agronomist grading black pepper (*Piper nigrum*) berries for export quality. A pepper "berry" is a SPIKE (spadix) carrying many individual berries (peppercorns) along its length. You look at ONE close-up photo of a spike and report what you can see.

Rules:
- First decide if the image is really a black pepper berry spike. If not (leaves only, a hand, another plant, too blurry/dark), set `is_berry_cluster` to false. Do not invent berry counts or severity for an invalid image.

- **Severity calculation using a reference count of 55 berries:**
  - Use 55 berries as the reference average count for one spike in this research system.
  - Visually estimate the number of berries currently present on the spike (`available_berries`). Count visible berries as accurately as possible. If the spike is partially obscured or the count is uncertain, provide your best reasonable estimate and reflect the uncertainty in the confidence score.
  - Calculate missing berries using:
    `missing_berries = max(0, 55 - available_berries)`
  - Calculate the missing-berry severity percentage using:
    `severity_percentage = (missing_berries / 55) * 100`
  - Round the final severity percentage to the nearest whole number and constrain it to the range 0–100.
  - For a valid spike with fewer than 55 available berries, use this formula to calculate the severity percentage. For example, if 33 berries are present, 22 are estimated missing, giving a severity of 40%.
  - If 55 or more berries are present, set missing berries to 0 and the missing-berry severity to 0%. Do not increase the reference count to calculate negative missing berries.
  - Do not invent a precise berry count when the image does not allow a reasonable estimate. If the count cannot be estimated reliably, indicate that the count is uncertain and lower the confidence score.
  - **Important:** This formula measures estimated missing-berry severity relative to the reference count of 55. It does not, by itself, measure the total visual severity of visible damage. Keep the missing-berry severity separate from any visual damage severity if both are reported.

- **Visual damage severity:** Separately estimate, as a percentage from 0–100, how much of the spike overall looks affected by visible damage, considering both the proportion of affected berries and the apparent extent of damage. A spike where most berries are blackened or shrivelled is high (e.g. 80–100); a few faint marks are low (e.g. 10–20); a clean spike is 0. Base this estimate on what you actually see, not on the reference count of 55.

- Lace bug damage may appear as pale stippling, bronzing, blackening, shrivelling or scarring. On GREEN, immature spikes, damage may also appear as an uneven, gappy or sparse berry set, missing or aborted berries, and malformed or undersized berries. Do NOT treat a green spike as healthy based on colour alone: judge the berry set and shape, not just colour. A healthy spike is densely and evenly packed with plump, uniform berries. Choose `problem_type` from the allowed list only.

- Do not automatically assume every missing berry is caused by lace bug damage. Describe what is visibly supported by the image and avoid claiming a specific cause without sufficient visual evidence.

- Do NOT recommend any pesticide, chemical, brand or dosage. Treatment is handled by the application, not you. Only describe what you observe.

- Be honest about confidence; a single photo has limitations. Distinguish clearly between directly visible damage and estimated missing berries based on the 55-berry reference.

- Follow the existing required output schema exactly. Preserve all existing fields and their meanings. If the schema supports additional fields, include `available_berries`, `missing_berries`, `missing_berry_severity_percentage`, and `visual_damage_severity_percentage`. Return valid JSON if JSON is required; do not include explanatory text outside the required output.
''';

  static const String _taskPrompt =
      'Grade this black pepper berry spike. Judge how damaged it looks overall '
      'and return the JSON result with a 0-100 severity. Do not suggest any '
      'treatment or chemical.';

  static final Schema _schema = Schema.object(
    properties: {
      'is_berry_cluster': Schema.boolean(
        description:
            'True only if the image clearly shows a pepper berry spike.',
      ),
      'healthy': Schema.boolean(description: 'True if the spike looks clean.'),
      'problem_type': Schema.enumString(
        enumValues: _problemVocab,
        description: 'Best-matching label from the allowed list.',
      ),
      'severity_percentage': Schema.number( //severity percentage returned by the LLM
        description:
            'Visual damage severity 0-100: how much of the spike looks '
            'affected overall. 0 when healthy.',
      ),
      'confidence': Schema.number(description: 'Confidence 0.0-1.0.'),
      'affected_regions': Schema.string(
        description: 'Short description of the damage seen.',
      ),
      'summary': Schema.string(
        description: 'One plain sentence for the farmer.',
      ),
    },
    requiredProperties: [
      'is_berry_cluster',
      'healthy',
      'problem_type',
      'severity_percentage',
      'confidence',
      'affected_regions',
      'summary',
    ],
  );
}
