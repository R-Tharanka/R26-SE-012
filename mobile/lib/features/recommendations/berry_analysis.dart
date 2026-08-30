/// Vision result of an AI pepper-berry spike analysis.
///
/// The AI judges damage SEVERITY visually — how much of the spike looks damaged
/// overall — and reports it directly as a 0–100 percentage. The safety-critical
/// remediation comes from the deterministic [RemediationEngine].
class BerryAnalysis {
  /// False when the photo isn't a pepper berry spike → ask for a retake.
  final bool isBerryCluster;

  /// True when the spike looks healthy / export-clean.
  final bool healthy;

  /// e.g. "Lace bug damage", "Healthy", "Other damage", "Uncertain".
  final String problemType;

  /// Visual damage severity, 0–100, as judged by the AI from what it sees.
  final double severityPercentage;

  /// Model confidence, 0–1.
  final double confidence;

  final String affectedRegions;
  final String summary;

  const BerryAnalysis({
    required this.isBerryCluster,
    required this.healthy,
    required this.problemType,
    required this.severityPercentage,
    required this.confidence,
    required this.affectedRegions,
    required this.summary,
  });

  /// none | mild | moderate | severe (70% cut = severe, per the client table).
  String get severityBand {
    final s = healthy ? 0 : severityPercentage;
    if (s <= 0) return 'none';
    if (s <= 30) return 'mild';
    if (s <= 70) return 'moderate';
    return 'severe';
  }

  factory BerryAnalysis.fromJson(Map<String, dynamic> j) {
    double asDouble(Object? v) =>
        v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0);
    final healthy = j['healthy'] == true;
    return BerryAnalysis(
      isBerryCluster: j['is_berry_cluster'] == true,
      healthy: healthy,
      problemType: (j['problem_type'] ?? 'Uncertain').toString(),
      severityPercentage:
          healthy ? 0 : asDouble(j['severity_percentage']).clamp(0, 100),
      confidence: asDouble(j['confidence']),
      affectedRegions: (j['affected_regions'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
    );
  }
}
