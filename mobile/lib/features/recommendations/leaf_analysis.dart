/// Structured result of an AI leaf-disease analysis.
///
/// Mirrors the spec's output contract but adds the fields that make the result
/// trustworthy in the field: an out-of-distribution gate ([isPepperLeaf]), a
/// human-readable severity [band], the affected-region explanation, and the
/// treatment recommendations.
class LeafAnalysis {
  /// False when AI judges the photo is not actually a black pepper leaf
  /// (soil, a hand, another plant, too blurry/dark). The UI should ask for a
  /// retake instead of showing a bogus diagnosis.
  final bool isPepperLeaf;

  /// True when the leaf looks healthy (no disease / deficiency).
  final bool healthy;

  /// e.g. "Leaf Blight", "Quick Wilt", "Little Leaf", "Nutrient deficiency".
  final String diseaseType;

  /// Estimated infected leaf area, 0–100. Null when not applicable (healthy).
  final double? severityPercentage;

  /// none | mild | moderate | severe
  final String severityBand;

  /// Model's confidence in the diagnosis, 0–1.
  final double confidence;

  /// Where/what the symptoms are (for the explainability overlay text).
  final String affectedRegions;

  /// Ordered, actionable treatment steps.
  final List<String> treatments;

  /// One-line plain-language summary for the farmer.
  final String summary;

// Constructor used to create a LeafAnalysis object with all required analysis values
  const LeafAnalysis({
    required this.isPepperLeaf,
    required this.healthy,
    required this.diseaseType,
    required this.severityPercentage,
    required this.severityBand,
    required this.confidence,
    required this.affectedRegions,
    required this.treatments,
    required this.summary,
  });

  /// A disease is valid only when the image contains a pepper leaf that is not healthy.
  bool get diseaseDetected => isPepperLeaf && !healthy;

  factory LeafAnalysis.fromJson(Map<String, dynamic> j) {
    double? asDouble(Object? v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    // Converts the AI response into a typed analysis with safe fallback values.
    return LeafAnalysis(
      isPepperLeaf: j['is_pepper_leaf'] == true,
      healthy: j['healthy'] == true,
      diseaseType: (j['disease_type'] ?? 'Unknown').toString(),
      severityPercentage: asDouble(j['severity_percentage']),
      severityBand: (j['severity_band'] ?? 'none').toString(),
      confidence: asDouble(j['confidence']) ?? 0.0,
      affectedRegions: (j['affected_regions'] ?? '').toString(),
      treatments: (j['treatments'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          const [],
      summary: (j['summary'] ?? '').toString(),
    );
  }
}
