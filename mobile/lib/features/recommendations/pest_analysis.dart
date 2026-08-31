/// Vision result of an AI pest analysis on a pepper-plant photo.
///
/// AI identifies and counts what it can see; it does NOT recommend any
/// pesticide — the [PestTreatmentEngine] owns treatment so an LLM can't suggest
/// an export-banned chemical or advise spraying below the economic threshold.
class PestAnalysis {
  /// False when the image isn't a pepper plant part → ask for a retake.
  final bool isPepperPlant;

  /// True when no pest / damage is present.
  final bool healthy;

  /// e.g. "Gynaikothrips karny", "Diconocoris distanti", "Other pest".
  final String pestType;

  /// leaf | stem | berry | unknown — pests differ by location.
  final String plantPart;

  /// Estimated pests visible in the frame.
  final int pestCount;

  /// Overall infestation severity, 0–100 (visual estimate incl. damage).
  final double severityPercentage;

  final double confidence;
  final String affectedRegions;
  final String summary;

  const PestAnalysis({
    required this.isPepperPlant,
    required this.healthy,
    required this.pestType,
    required this.plantPart,
    required this.pestCount,
    required this.severityPercentage,
    required this.confidence,
    required this.affectedRegions,
    required this.summary,
  });

  /// none | mild | moderate | severe.
  String get severityBand {
    if (healthy || severityPercentage <= 0) return 'none';
    if (severityPercentage <= 20) return 'mild';
    if (severityPercentage <= 50) return 'moderate';
    return 'severe';
  }

  factory PestAnalysis.fromJson(Map<String, dynamic> j) {
    double asDouble(Object? v) =>
        v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0);
    int asInt(Object? v) =>
        v is num ? v.round() : (int.tryParse('${v ?? ''}') ?? 0);
    return PestAnalysis(
      isPepperPlant: j['is_pepper_plant'] == true,
      healthy: j['healthy'] == true,
      pestType: (j['pest_type'] ?? 'Uncertain').toString(),
      plantPart: (j['plant_part'] ?? 'unknown').toString(),
      pestCount: asInt(j['pest_count']),
      severityPercentage: asDouble(j['severity_percentage']),
      confidence: asDouble(j['confidence']),
      affectedRegions: (j['affected_regions'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
    );
  }
}
