class GradingForecastResult {
  const GradingForecastResult({
    required this.schemaVersion,
    required this.grading,
    required this.market,
    required this.decisionSupport,
    required this.trace,
    required this.runtime,
  });
  final String schemaVersion;
  final GradingResult grading;
  final MarketResult market;
  final DecisionSupportResult decisionSupport;
  final Map<String, dynamic> trace;
  final RuntimeResult runtime;
  factory GradingForecastResult.fromJson(Map<String, dynamic> json) =>
      GradingForecastResult(
        schemaVersion: _string(json['schema_version']),
        grading: GradingResult.fromJson(_map(json['grading'])),
        market: MarketResult.fromJson(_map(json['market'])),
        decisionSupport: DecisionSupportResult.fromJson(
          _map(json['decision_support']),
        ),
        trace: _map(json['trace']),
        runtime: RuntimeResult.fromJson(_map(json['runtime'])),
      );
}

class GradingResult {
  const GradingResult({
    required this.status,
    required this.decision,
    this.grade,
    this.modelConfidence,
    this.detectionConfidence,
    this.classMargin,
    required this.qualityStatus,
    this.rejectionReason,
    required this.confidenceInterpretation,
  });
  final String status;
  final String decision;
  final String? grade;
  final double? modelConfidence;
  final double? detectionConfidence;
  final double? classMargin;
  final String qualityStatus;
  final String? rejectionReason;
  final String confidenceInterpretation;
  bool get isAccepted => status == 'ACCEPTED';
  factory GradingResult.fromJson(Map<String, dynamic> json) => GradingResult(
    status: _string(json['status']),
    decision: _string(json['decision']),
    grade: _nullableString(json['grade']),
    modelConfidence: _nullableDouble(json['model_confidence']),
    detectionConfidence: _nullableDouble(json['detection_confidence']),
    classMargin: _nullableDouble(json['class_margin']),
    qualityStatus: _string(json['quality_status']),
    rejectionReason: _nullableString(json['rejection_reason']),
    confidenceInterpretation: _string(json['confidence_interpretation']),
  );
}

class ForecastInterval {
  const ForecastInterval({
    required this.lower,
    required this.upper,
    required this.label,
  });
  final double lower;
  final double upper;
  final String label;
  factory ForecastInterval.fromJson(Map<String, dynamic> json) =>
      ForecastInterval(
        lower: _double(json['lower']),
        upper: _double(json['upper']),
        label: _string(json['label']),
      );
}

class MarketResult {
  const MarketResult({
    required this.status,
    this.source,
    this.priceGrade,
    this.latestReferenceDate,
    this.latestReferencePrice,
    this.forecastTargetDate,
    this.forecastReturn,
    this.forecastPrice,
    this.forecastDirection,
    this.forecastInterval,
    this.persistencePrice,
    this.modelVsPersistence,
    this.forecastSignal,
    this.evidencePartition,
  });
  final String status;
  final String? source;
  final String? priceGrade;
  final String? latestReferenceDate;
  final double? latestReferencePrice;
  final String? forecastTargetDate;
  final double? forecastReturn;
  final double? forecastPrice;
  final String? forecastDirection;
  final ForecastInterval? forecastInterval;
  final double? persistencePrice;
  final String? modelVsPersistence;
  final String? forecastSignal;
  final String? evidencePartition;
  bool get isAvailable => status == 'AVAILABLE';
  factory MarketResult.fromJson(Map<String, dynamic> json) => MarketResult(
    status: _string(json['status']),
    source: _nullableString(json['source']),
    priceGrade: _nullableString(json['price_grade']),
    latestReferenceDate: _nullableString(json['latest_reference_date']),
    latestReferencePrice: _nullableDouble(json['latest_reference_price']),
    forecastTargetDate: _nullableString(json['forecast_target_date']),
    forecastReturn: _nullableDouble(json['forecast_return']),
    forecastPrice: _nullableDouble(json['forecast_price']),
    forecastDirection: _nullableString(json['forecast_direction']),
    forecastInterval: json['forecast_interval'] == null
        ? null
        : ForecastInterval.fromJson(_map(json['forecast_interval'])),
    persistencePrice: _nullableDouble(json['persistence_price']),
    modelVsPersistence: _nullableString(json['model_vs_persistence']),
    forecastSignal: _nullableString(json['forecast_signal']),
    evidencePartition: _nullableString(json['evidence_partition']),
  );
}

class DecisionSupportResult {
  const DecisionSupportResult({
    required this.category,
    required this.summary,
    required this.limitations,
  });
  final String category;
  final String summary;
  final List<String> limitations;
  factory DecisionSupportResult.fromJson(Map<String, dynamic> json) =>
      DecisionSupportResult(
        category: _string(json['category']),
        summary: _string(json['summary']),
        limitations: _strings(json['limitations']),
      );
}

class RuntimeResult {
  const RuntimeResult({
    required this.grading,
    required this.price,
    required this.mobile,
    required this.tflite,
  });
  final String grading;
  final String price;
  final String mobile;
  final String tflite;
  factory RuntimeResult.fromJson(Map<String, dynamic> json) => RuntimeResult(
    grading: _string(json['grading']),
    price: _string(json['price']),
    mobile: _string(json['mobile']),
    tflite: _string(json['tflite']),
  );
}

String _string(Object? value) => value?.toString() ?? '';
String? _nullableString(Object? value) => value?.toString();
double _double(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
double? _nullableDouble(Object? value) => value == null ? null : _double(value);
Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((k, v) => MapEntry(k.toString(), v))
    : <String, dynamic>{};
List<String> _strings(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];
