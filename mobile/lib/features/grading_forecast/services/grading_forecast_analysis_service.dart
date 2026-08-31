import 'dart:typed_data';

import '../models/grading_forecast_result.dart';
import 'grading_forecast_api_service.dart';
import 'offline_grading_forecast_service.dart';

class GradingForecastAnalysisService {
  GradingForecastAnalysisService({
    GradingForecastApiService? apiService,
    OfflineGradingForecastService? offlineService,
  })  : _apiService = apiService ?? GradingForecastApiService(),
        _offlineService = offlineService ?? OfflineGradingForecastService();

  static const _mode = String.fromEnvironment(
    'PEPPER_ANALYSIS_MODE',
    defaultValue: 'offline',
  );

  final GradingForecastApiService _apiService;
  final OfflineGradingForecastService _offlineService;

  bool get isOffline => _mode.toLowerCase() != 'api';

  Future<GradingForecastResult> analyzeBytes(
    Uint8List imageBytes,
    String filename,
  ) {
    if (isOffline) {
      return _offlineService.analyzeBytes(imageBytes, filename);
    }
    return _apiService.analyzeBytes(imageBytes, filename);
  }

  Future<RecommendationResult> recommend({
    required String grade,
    required String trend,
    double? qualityScore,
    int? currentPriceLkrPerKg,
    int? predictedPriceLkrPerKg,
  }) {
    if (isOffline) {
      return _offlineService.recommend(
        grade: grade,
        trend: trend,
        qualityScore: qualityScore,
        currentPriceLkrPerKg: currentPriceLkrPerKg,
        predictedPriceLkrPerKg: predictedPriceLkrPerKg,
      );
    }
    return _apiService.recommend(
      grade: grade,
      trend: trend,
      qualityScore: qualityScore,
      currentPriceLkrPerKg: currentPriceLkrPerKg,
      predictedPriceLkrPerKg: predictedPriceLkrPerKg,
    );
  }

  Future<void> dispose() => _offlineService.dispose();
}
