import 'dart:typed_data';
import '../models/grading_forecast_result.dart';
import 'grading_forecast_api_service.dart';

class GradingForecastAnalysisService {
  GradingForecastAnalysisService({GradingForecastApiService? apiService})
    : _apiService = apiService ?? GradingForecastApiService();
  final GradingForecastApiService _apiService;
  bool get isOffline => false;
  Future<GradingForecastResult> analyzeBytes(
    Uint8List bytes,
    String filename,
  ) => _apiService.analyzeBytes(bytes, filename);
  Future<void> dispose() async => _apiService.close();
}
