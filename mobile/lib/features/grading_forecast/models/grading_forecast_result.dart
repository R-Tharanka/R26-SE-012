class GradingForecastResult {
  GradingForecastResult({
    required this.status,
    required this.component,
    required this.imageAnalysis,
    required this.grading,
    required this.forecast,
    required this.recommendation,
    required this.storage,
  });

  final String status;
  final String component;
  final ImageAnalysisResult imageAnalysis;
  final GradingResult grading;
  final ForecastResult forecast;
  final RecommendationResult recommendation;
  final StorageResult storage;

  factory GradingForecastResult.fromJson(Map<String, dynamic> json) {
    return GradingForecastResult(
      status: _asString(json['status']),
      component: _asString(json['component']),
      imageAnalysis: ImageAnalysisResult.fromJson(_asMap(json['image_analysis'])),
      grading: GradingResult.fromJson(_asMap(json['grading'])),
      forecast: ForecastResult.fromJson(_asMap(json['forecast'])),
      recommendation: RecommendationResult.fromJson(_asMap(json['recommendation'])),
      storage: StorageResult.fromJson(_asMap(json['storage'])),
    );
  }
}

class ImageAnalysisResult {
  ImageAnalysisResult({
    required this.imageId,
    required this.processed,
    required this.note,
  });

  final String imageId;
  final bool processed;
  final String note;

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(
      imageId: _asString(json['image_id']),
      processed: _asBool(json['processed']),
      note: _asString(json['note']),
    );
  }
}

class VisualFeatures {
  VisualFeatures({
    required this.colorUniformityScore,
    required this.darkBerryRatio,
    required this.lightBerryRatio,
    required this.textureScore,
    required this.defectRatio,
    required this.cleanlinessScore,
  });

  final double colorUniformityScore;
  final double darkBerryRatio;
  final double lightBerryRatio;
  final double textureScore;
  final double defectRatio;
  final double cleanlinessScore;

  factory VisualFeatures.fromJson(Map<String, dynamic> json) {
    return VisualFeatures(
      colorUniformityScore: _asDouble(json['color_uniformity_score']),
      darkBerryRatio: _asDouble(json['dark_berry_ratio']),
      lightBerryRatio: _asDouble(json['light_berry_ratio']),
      textureScore: _asDouble(json['texture_score']),
      defectRatio: _asDouble(json['defect_ratio']),
      cleanlinessScore: _asDouble(json['cleanliness_score']),
    );
  }
}

class SupportingLabels {
  SupportingLabels({
    required this.sizeQuality,
    required this.colorQuality,
    required this.textureQuality,
    required this.brokenLevel,
    required this.lightBerryLevel,
    required this.pinheadLevel,
    required this.foreignMatterVisible,
    required this.mouldVisible,
    required this.insectDamageVisible,
  });

  final String sizeQuality;
  final String colorQuality;
  final String textureQuality;
  final String brokenLevel;
  final String lightBerryLevel;
  final String pinheadLevel;
  final bool foreignMatterVisible;
  final bool mouldVisible;
  final bool insectDamageVisible;

  factory SupportingLabels.fromJson(Map<String, dynamic> json) {
    return SupportingLabels(
      sizeQuality: _asString(json['size_quality']),
      colorQuality: _asString(json['color_quality']),
      textureQuality: _asString(json['texture_quality']),
      brokenLevel: _asString(json['broken_level']),
      lightBerryLevel: _asString(json['light_berry_level']),
      pinheadLevel: _asString(json['pinhead_level']),
      foreignMatterVisible: _asBool(json['foreign_matter_visible']),
      mouldVisible: _asBool(json['mould_visible']),
      insectDamageVisible: _asBool(json['insect_damage_visible']),
    );
  }
}

class GradingResult {
  GradingResult({
    required this.predictedGrade,
    required this.qualityScore,
    required this.confidence,
    required this.visualFeatures,
    required this.supportingLabels,
    required this.explanation,
    required this.limitation,
  });

  final String predictedGrade;
  final double qualityScore;
  final double confidence;
  final VisualFeatures visualFeatures;
  final SupportingLabels supportingLabels;
  final List<String> explanation;
  final String limitation;

  factory GradingResult.fromJson(Map<String, dynamic> json) {
    return GradingResult(
      predictedGrade: _asString(json['predicted_grade']),
      qualityScore: _asDouble(json['quality_score']),
      confidence: _asDouble(json['confidence']),
      visualFeatures: VisualFeatures.fromJson(_asMap(json['visual_features'])),
      supportingLabels: SupportingLabels.fromJson(_asMap(json['supporting_labels'])),
      explanation: _asStringList(json['explanation']),
      limitation: _asString(json['limitation']),
    );
  }
}

class ForecastMetrics {
  ForecastMetrics({required this.mae, required this.rmse});

  final double? mae;
  final double? rmse;

  factory ForecastMetrics.fromJson(Map<String, dynamic> json) {
    return ForecastMetrics(
      mae: _asNullableDouble(json['mae']),
      rmse: _asNullableDouble(json['rmse']),
    );
  }
}

class ForecastResult {
  ForecastResult({
    required this.model,
    required this.currentPriceLkrPerKg,
    required this.predictedPriceLkrPerKg,
    required this.trend,
    required this.forecastPeriod,
    required this.metrics,
  });

  final String model;
  final int currentPriceLkrPerKg;
  final int predictedPriceLkrPerKg;
  final String trend;
  final String forecastPeriod;
  final ForecastMetrics metrics;

  factory ForecastResult.fromJson(Map<String, dynamic> json) {
    return ForecastResult(
      model: _asString(json['model']),
      currentPriceLkrPerKg: _asInt(json['current_price_lkr_per_kg']),
      predictedPriceLkrPerKg: _asInt(json['predicted_price_lkr_per_kg']),
      trend: _asString(json['trend']),
      forecastPeriod: _asString(json['forecast_period']),
      metrics: ForecastMetrics.fromJson(_asMap(json['metrics'])),
    );
  }
}

class RecommendationResult {
  RecommendationResult({
    required this.decision,
    required this.message,
    required this.explanation,
    required this.urgencyLevel,
    required this.suggestedAction,
    required this.limitationNote,
  });

  final String decision;
  final String message;
  final List<String> explanation;
  final String urgencyLevel;
  final String suggestedAction;
  final String limitationNote;

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    return RecommendationResult(
      decision: _asString(json['decision']),
      message: _asString(json['message']),
      explanation: _asStringList(json['explanation']),
      urgencyLevel: _asString(json['urgency_level']),
      suggestedAction: _asString(json['suggested_action']),
      limitationNote: _asString(json['limitation_note']),
    );
  }
}

class StorageResult {
  StorageResult({
    required this.savedToFirebase,
    required this.documentId,
  });

  final bool savedToFirebase;
  final String? documentId;

  factory StorageResult.fromJson(Map<String, dynamic> json) {
    return StorageResult(
      savedToFirebase: _asBool(json['saved_to_firebase']),
      documentId: json['document_id']?.toString(),
    );
  }
}

String _asString(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.trim().toLowerCase();
    if (s == 'true' || s == 'yes' || s == '1') return true;
    if (s == 'false' || s == 'no' || s == '0') return false;
  }
  return fallback;
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double _asDouble(Object? value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double? _asNullableDouble(Object? value) {
  if (value == null) return null;
  final parsed = _asDouble(value, fallback: double.nan);
  if (parsed.isNaN) return null;
  return parsed;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value.where((e) => e != null).map((e) => e.toString()).toList();
  }
  return <String>[];
}

