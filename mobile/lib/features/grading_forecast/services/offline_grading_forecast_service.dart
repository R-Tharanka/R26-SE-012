import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/grading_forecast_result.dart';

class OfflineGradingForecastService {
  static const _component = 'berry_grading_export_price_forecasting';
  static const _modelAsset = 'assets/models/berry_mobilenetv2_v2_best.tflite';
  static const _classNamesAsset = 'assets/data/berry_grading_class_names.json';
  static const _priceCsvAsset = 'assets/data/national_grade1_average_weekly.csv';
  static const _metricsAsset = 'assets/data/naive_persistence_metrics.json';
  static const _gradeAdjustmentsAsset = 'assets/data/grade_price_adjustments.json';
  static const _inputSize = 224;
  static const _grade2AdjustedModel = 'naive_persistence_grade2_gap_adjusted_mobile';
  static const _grade3UnavailableModel = 'price_unavailable_grade3_mobile';

  Interpreter? _interpreter;
  List<String>? _classNames;
  ForecastMetrics? _metrics;
  int? _grade2Discount;

  Future<GradingForecastResult> analyzeBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw StateError('Uploaded image is invalid or unreadable.');
    }

    final prediction = await _predictGrade(decoded);
    final features = _extractVisualFeatures(decoded);
    final grading = _buildGrading(prediction, features);
    final forecast = await _buildForecast(grading.predictedGrade);
    final recommendation = _buildRecommendation(
      grade: grading.predictedGrade,
      trend: forecast.trend,
      qualityScore: grading.qualityScore,
      currentPriceLkrPerKg:
          forecast.predictedPriceLkrPerKg <= 0 ? null : forecast.currentPriceLkrPerKg,
      predictedPriceLkrPerKg:
          forecast.predictedPriceLkrPerKg <= 0 ? null : forecast.predictedPriceLkrPerKg,
    );

    return GradingForecastResult(
      status: 'success',
      component: _component,
      imageAnalysis: ImageAnalysisResult(
        imageId: filename.isEmpty ? 'mobile_image' : filename,
        processed: true,
        note: 'On-device visual analysis only',
      ),
      grading: grading,
      forecast: forecast,
      recommendation: recommendation,
      storage: StorageResult(savedToFirebase: false, documentId: null),
    );
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }

  Future<RecommendationResult> recommend({
    required String grade,
    required String trend,
    double? qualityScore,
    int? currentPriceLkrPerKg,
    int? predictedPriceLkrPerKg,
  }) async {
    return _buildRecommendation(
      grade: grade,
      trend: trend,
      qualityScore: qualityScore ?? 0,
      currentPriceLkrPerKg: currentPriceLkrPerKg,
      predictedPriceLkrPerKg: predictedPriceLkrPerKg,
    );
  }

  Future<_GradePrediction> _predictGrade(img.Image source) async {
    final interpreter = await _loadInterpreter();
    final classes = await _loadClassNames();
    final input = _buildInputTensor(source);

    interpreter.getInputTensor(0).setTo(input);
    interpreter.invoke();

    final outputTensor = interpreter.getOutputTensor(0);
    final outputBytes = outputTensor.data;
    final output = outputBytes.buffer.asFloat32List(
      outputBytes.offsetInBytes,
      outputBytes.lengthInBytes ~/ Float32List.bytesPerElement,
    );
    if (output.isEmpty) {
      throw StateError('Offline berry grading model returned no output.');
    }

    final probabilities = _probabilities(output);
    var bestIndex = 0;
    for (var i = 1; i < probabilities.length; i += 1) {
      if (probabilities[i] > probabilities[bestIndex]) {
        bestIndex = i;
      }
    }

    final grade =
        bestIndex < classes.length ? classes[bestIndex] : 'Grade ${bestIndex + 1}';
    return _GradePrediction(
      grade: grade,
      confidence: probabilities[bestIndex],
      probabilities: probabilities,
    );
  }

  Future<Interpreter> _loadInterpreter() async {
    final loaded = _interpreter;
    if (loaded != null) return loaded;

    final interpreter = await Interpreter.fromAsset(
      _modelAsset,
      options: InterpreterOptions()..threads = 4,
    );
    final inputShape = interpreter.getInputTensor(0).shape;
    if (inputShape.length != 4 ||
        inputShape[1] != _inputSize ||
        inputShape[2] != _inputSize ||
        inputShape[3] != 3) {
      throw StateError(
        'Unexpected offline model input shape $inputShape '
        '(expected [1, $_inputSize, $_inputSize, 3]).',
      );
    }
    interpreter.allocateTensors();
    _interpreter = interpreter;
    return interpreter;
  }

  Future<List<String>> _loadClassNames() async {
    final loaded = _classNames;
    if (loaded != null) return loaded;

    final raw = await rootBundle.loadString(_classNamesAsset);
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw StateError('Offline class names asset is invalid.');
    }
    final classes = decoded.map((item) => item.toString()).toList(growable: false);
    _classNames = classes;
    return classes;
  }

  Float32List _buildInputTensor(img.Image source) {
    final upright = source.convert(numChannels: 3);
    final scale = _inputSize / math.max(upright.width, upright.height);
    final scaledWidth = math.max(1, (upright.width * scale).round());
    final scaledHeight = math.max(1, (upright.height * scale).round());
    final resized = img.copyResize(
      upright,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.linear,
    );
    final canvas =
        img.Image(width: _inputSize, height: _inputSize, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
    img.compositeImage(
      canvas,
      resized,
      dstX: (_inputSize - scaledWidth) ~/ 2,
      dstY: (_inputSize - scaledHeight) ~/ 2,
    );

    final tensor = Float32List(_inputSize * _inputSize * 3);
    var i = 0;
    for (var y = 0; y < _inputSize; y += 1) {
      for (var x = 0; x < _inputSize; x += 1) {
        final px = canvas.getPixel(x, y);
        tensor[i++] = px.r.toDouble();
        tensor[i++] = px.g.toDouble();
        tensor[i++] = px.b.toDouble();
      }
    }
    return tensor;
  }

  List<double> _probabilities(Float32List output) {
    final values = output.take(3).map((value) => value.toDouble()).toList();
    final sum = values.fold<double>(0, (total, value) => total + value);
    if (sum.isFinite && sum > 0 && sum <= 1.2) {
      return values.map((value) => value / sum).toList(growable: false);
    }

    final maxValue = values.reduce(math.max);
    final exps = values.map((value) => math.exp(value - maxValue)).toList();
    final expSum = exps.fold<double>(0, (total, value) => total + value);
    return exps.map((value) => value / expSum).toList(growable: false);
  }

  VisualFeatures _extractVisualFeatures(img.Image source) {
    final sample = img.copyResize(
      source.convert(numChannels: 3),
      width: 160,
      interpolation: img.Interpolation.linear,
    );
    final total = math.max(1, sample.width * sample.height);

    var dark = 0;
    var light = 0;
    var clean = 0;
    var sum = 0.0;
    var sumSquares = 0.0;

    for (final px in sample) {
      final r = px.r.toDouble();
      final g = px.g.toDouble();
      final b = px.b.toDouble();
      final luminance = (0.299 * r) + (0.587 * g) + (0.114 * b);
      sum += luminance;
      sumSquares += luminance * luminance;
      if (luminance < 80) dark += 1;
      if (luminance > 160) light += 1;
      if ((r - g).abs() + (g - b).abs() < 120) clean += 1;
    }

    final mean = sum / total;
    final variance = math.max(0, (sumSquares / total) - (mean * mean));
    final std = math.sqrt(variance);
    final darkRatio = dark / total;
    final lightRatio = light / total;
    final colorUniformity = (1 - (std / 96)).clamp(0.0, 1.0).toDouble();
    final textureScore = (std / 64).clamp(0.0, 1.0).toDouble();
    final defectRatio = (lightRatio * 0.55 + (1 - colorUniformity) * 0.25)
        .clamp(0.0, 1.0)
        .toDouble();
    final cleanliness = (clean / total).clamp(0.0, 1.0).toDouble();

    return VisualFeatures(
      colorUniformityScore: _round3(colorUniformity),
      darkBerryRatio: _round3(darkRatio),
      lightBerryRatio: _round3(lightRatio),
      textureScore: _round3(textureScore),
      defectRatio: _round3(defectRatio),
      cleanlinessScore: _round3(cleanliness),
    );
  }

  GradingResult _buildGrading(_GradePrediction prediction, VisualFeatures features) {
    const anchors = {
      'Grade 1': 85.0,
      'Grade 2': 70.0,
      'Grade 3': 55.0,
    };
    const orderedGrades = ['Grade 1', 'Grade 2', 'Grade 3'];

    var expectedScore = 0.0;
    for (var i = 0;
        i < prediction.probabilities.length && i < orderedGrades.length;
        i += 1) {
      expectedScore += prediction.probabilities[i] * anchors[orderedGrades[i]]!;
    }

    final supportingLabels = SupportingLabels(
      sizeQuality: prediction.grade == 'Grade 1'
          ? 'good'
          : prediction.grade == 'Grade 2'
              ? 'medium'
              : 'poor',
      colorQuality: _qualityBand(
        features.colorUniformityScore - (features.lightBerryRatio * 0.4),
        goodThreshold: 0.78,
        mediumThreshold: 0.62,
      ),
      textureQuality: _qualityBand(
        features.textureScore,
        goodThreshold: 0.76,
        mediumThreshold: 0.60,
      ),
      brokenLevel: _levelBand(
        features.defectRatio,
        lowThreshold: 0.10,
        mediumThreshold: 0.20,
      ),
      lightBerryLevel: _levelBand(
        features.lightBerryRatio,
        lowThreshold: 0.12,
        mediumThreshold: 0.22,
      ),
      pinheadLevel: features.lightBerryRatio <= 0.12
          ? 'low'
          : features.lightBerryRatio <= 0.22
              ? 'medium'
              : 'high',
      foreignMatterVisible: features.cleanlinessScore < 0.75,
      mouldVisible: features.defectRatio > 0.20 && features.lightBerryRatio > 0.15,
      insectDamageVisible: features.defectRatio > 0.18 && features.textureScore < 0.55,
    );

    return GradingResult(
      predictedGrade: prediction.grade,
      qualityScore: _round1(expectedScore.clamp(0.0, 100.0).toDouble()),
      confidence: _round2(prediction.confidence.clamp(0.0, 1.0).toDouble()),
      visualFeatures: features,
      supportingLabels: supportingLabels,
      explanation: [
        if (features.colorUniformityScore >= 0.80)
          'Good black colour uniformity improved the grade.'
        else if (features.colorUniformityScore >= 0.65)
          'Medium colour uniformity detected.'
        else
          'Poor colour uniformity reduced the visual quality score.',
        if (features.lightBerryRatio >= 0.22)
          'Higher light berry ratio reduced the visual quality score.',
        if (features.defectRatio >= 0.18)
          'Visible defects or abnormal regions reduced the grade.'
        else
          'Low visible defect level detected.',
        'Runtime model BERRY-V2-MNV2-TFLITE was used for on-device predicted grade.',
      ],
      limitation:
          'Camera-based visual estimate only. Chemical requirements and bulk density are not measured.',
    );
  }

  Future<ForecastResult> _buildForecast(String grade) async {
    final grade1Price = await _latestObservedPrice();
    final metrics = await _loadMetrics();
    final normalized = grade.trim();
    if (normalized == 'Grade 3') {
      return ForecastResult(
        model: _grade3UnavailableModel,
        currentPriceLkrPerKg: 0,
        predictedPriceLkrPerKg: 0,
        trend: 'stable',
        forecastPeriod: 'next_period',
        metrics: ForecastMetrics(mae: null, rmse: null),
      );
    }

    final price = normalized == 'Grade 2'
        ? math.max(0, grade1Price - await _loadGrade2Discount()).toInt()
        : grade1Price;
    return ForecastResult(
      model: normalized == 'Grade 2'
          ? _grade2AdjustedModel
          : 'naive_persistence_mobile',
      currentPriceLkrPerKg: price,
      predictedPriceLkrPerKg: price,
      trend: 'stable',
      forecastPeriod: 'next_period',
      metrics: normalized == 'Grade 2' ? ForecastMetrics(mae: null, rmse: null) : metrics,
    );
  }

  Future<int> _loadGrade2Discount() async {
    final loaded = _grade2Discount;
    if (loaded != null) return loaded;

    try {
      final raw = await rootBundle.loadString(_gradeAdjustmentsAsset);
      final decoded = json.decode(raw);
      if (decoded is Map) {
        final value = decoded['grade_2_discount_lkr_per_kg'];
        final parsed = value is num ? value.round() : int.tryParse(value.toString());
        if (parsed != null && parsed > 0) {
          _grade2Discount = parsed;
          return parsed;
        }
      }
    } catch (_) {
      // Fall through to the documented default below.
    }

    _grade2Discount = 113;
    return 113;
  }

  Future<int> _latestObservedPrice() async {
    final csv = await rootBundle.loadString(_priceCsvAsset);
    final lines = const LineSplitter()
        .convert(csv)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    for (final line in lines.reversed) {
      if (line.toLowerCase().startsWith('date,')) continue;
      final parts = line.split(',');
      if (parts.length < 2) continue;
      final parsed = double.tryParse(parts[1].trim());
      if (parsed != null && parsed.isFinite && parsed > 0) {
        return parsed.round();
      }
    }
    return 0;
  }

  Future<ForecastMetrics> _loadMetrics() async {
    final loaded = _metrics;
    if (loaded != null) return loaded;

    try {
      final raw = await rootBundle.loadString(_metricsAsset);
      final decoded = json.decode(raw);
      final metrics = decoded is Map ? decoded['metrics'] : null;
      if (metrics is Map) {
        final result = ForecastMetrics(
          mae: _nullableDouble(metrics['mae']),
          rmse: _nullableDouble(metrics['rmse']),
        );
        _metrics = result;
        return result;
      }
    } catch (_) {
      // Keep the offline path usable if metrics are absent.
    }
    final empty = ForecastMetrics(mae: null, rmse: null);
    _metrics = empty;
    return empty;
  }

  RecommendationResult _buildRecommendation({
    required String grade,
    required String trend,
    required double qualityScore,
    required int? currentPriceLkrPerKg,
    required int? predictedPriceLkrPerKg,
  }) {
    final decision = _decisionFor(grade, trend);
    return RecommendationResult(
      decision: decision,
      message: _messageFor(decision),
      explanation: [
        'Predicted grade: $grade. Forecast trend: $trend.',
        'Quality score: ${qualityScore.toStringAsFixed(1)}/100.',
        if (predictedPriceLkrPerKg != null && predictedPriceLkrPerKg > 0)
          'Predicted market price: $predictedPriceLkrPerKg LKR/kg.'
        else
          'Predicted market price is unavailable for $grade because grade-specific historical price data is not available.',
      ],
      urgencyLevel: _urgencyFor(decision),
      suggestedAction: _suggestedActionFor(decision),
      limitationNote:
          'Camera-based visual estimate only. Laboratory tests are required for full official quality certification.',
    );
  }

  String _decisionFor(String grade, String trend) {
    if (grade == 'Grade 1' && trend == 'upward') {
      return 'WAIT_OR_TARGET_EXPORT_BUYER';
    }
    if (grade == 'Grade 1' && trend == 'stable') return 'SELL_EXPORT';
    if (grade == 'Grade 1' && trend == 'downward') return 'SELL_SOON';
    if (grade == 'Grade 2' && trend == 'upward') return 'WAIT_SHORTLY';
    if (grade == 'Grade 2' && trend == 'stable') return 'MONITOR';
    if (grade == 'Grade 2' && trend == 'downward') return 'SELL_SOON';
    if (grade == 'Grade 3' && trend == 'upward') return 'SORT_OR_PROCESS';
    if (grade == 'Grade 3' && trend == 'stable') return 'PROCESS_LOCAL';
    if (grade == 'Grade 3' && trend == 'downward') {
      return 'PROCESS_OR_SELL_IMMEDIATELY';
    }
    return 'MONITOR';
  }

  String _messageFor(String decision) {
    return switch (decision) {
      'WAIT_OR_TARGET_EXPORT_BUYER' =>
        'Grade 1 and prices are rising. If storage is safe, wait a bit or target an export buyer.',
      'SELL_EXPORT' =>
        'Grade 1 and the price is stable. You can sell to an export buyer after lab checks.',
      'SELL_SOON' => 'The price trend is going down. Sell soon to reduce the risk of a lower price.',
      'WAIT_SHORTLY' => 'Prices are rising. Wait a short time if storage conditions are good.',
      'SORT_OR_PROCESS' =>
        'Grade 3 is not ideal for export. Sort/clean the batch or process it before selling.',
      'PROCESS_LOCAL' =>
        'Grade 3 is not ideal for export. Consider processing and selling in the local market.',
      'PROCESS_OR_SELL_IMMEDIATELY' =>
        'Grade 3 and prices are falling. Process or sell immediately to avoid further loss.',
      _ => 'The price is stable. Monitor the market and decide based on your storage capacity.',
    };
  }

  String _suggestedActionFor(String decision) {
    return switch (decision) {
      'WAIT_OR_TARGET_EXPORT_BUYER' => 'Wait if storage is safe; contact an export buyer.',
      'SELL_EXPORT' => 'Prepare for export sale and confirm required lab tests.',
      'SELL_SOON' => 'Sell soon, especially if storage is limited.',
      'WAIT_SHORTLY' => 'Wait briefly and recheck the price trend soon.',
      'SORT_OR_PROCESS' => 'Sort/clean and remove defects, then consider processing.',
      'PROCESS_LOCAL' => 'Process and sell locally for better value than raw selling.',
      'PROCESS_OR_SELL_IMMEDIATELY' => 'Process or sell immediately to reduce losses.',
      _ => 'Monitor prices weekly and decide based on storage.',
    };
  }

  String _urgencyFor(String decision) {
    return switch (decision) {
      'SELL_SOON' || 'PROCESS_OR_SELL_IMMEDIATELY' => 'HIGH',
      'SORT_OR_PROCESS' || 'PROCESS_LOCAL' || 'SELL_EXPORT' => 'MEDIUM',
      _ => 'LOW',
    };
  }

  String _qualityBand(
    double value, {
    required double goodThreshold,
    required double mediumThreshold,
  }) {
    if (value >= goodThreshold) return 'good';
    if (value >= mediumThreshold) return 'medium';
    return 'poor';
  }

  String _levelBand(
    double value, {
    required double lowThreshold,
    required double mediumThreshold,
  }) {
    if (value <= lowThreshold) return 'low';
    if (value <= mediumThreshold) return 'medium';
    return 'high';
  }

  double? _nullableDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _round1(double value) => (value * 10).roundToDouble() / 10;
  double _round2(double value) => (value * 100).roundToDouble() / 100;
  double _round3(double value) => (value * 1000).roundToDouble() / 1000;
}

class _GradePrediction {
  const _GradePrediction({
    required this.grade,
    required this.confidence,
    required this.probabilities,
  });

  final String grade;
  final double confidence;
  final List<double> probabilities;
}
