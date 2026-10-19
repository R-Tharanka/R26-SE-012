// =============================================================================
// File: offline_grading_forecast_service.dart
// Purpose: Provides the offline grading forecast service application service.
// =============================================================================
import 'dart:typed_data';
import '../models/grading_forecast_result.dart';

/// Retained only as an explicit compatibility boundary.
///
/// The bundled legacy MobileNet TFLite model is not the frozen V3 YOLO model
/// and must not be used for Phase 7 decisions.
class OfflineGradingForecastService {
  /// Always fails explicitly so the legacy APK model cannot be mistaken for
  /// the frozen V3 ONNX grading model used by the research workflow.
  Future<GradingForecastResult> analyzeBytes(
    Uint8List _,
    String __,
  ) => Future<GradingForecastResult>.error(
    UnsupportedError(
      'Phase 7 uses verified backend ONNX inference; V3 TFLite is unavailable.',
    ),
  );
  // Release controllers, listeners, and other owned resources.
  Future<void> dispose() async {}
}
