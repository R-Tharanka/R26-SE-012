import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/grading_forecast_result.dart';

class GradingForecastApiException implements Exception {
  GradingForecastApiException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'GradingForecastApiException($statusCode): $message';
}

class GradingForecastApiService {
  GradingForecastApiService({String? baseUrlOverride})
      : _baseUrl = _sanitizeBaseUrl(baseUrlOverride ?? _defaultBaseUrl());

  static const _envKey = 'PEPPER_API_BASE_URL';
  static const _timeout = Duration(seconds: 30);

  final String _baseUrl;

  String get baseUrl => _baseUrl;

  Future<GradingForecastResult> analyze(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/api/v1/grading-forecast/analyze');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GradingForecastApiException(
          statusCode: response.statusCode,
          message: _bestEffortErrorMessage(response.body, response.statusCode),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map) {
        throw GradingForecastApiException(
          statusCode: response.statusCode,
          message: 'Unexpected response format from server.',
        );
      }

      return GradingForecastResult.fromJson(decoded.cast<String, dynamic>());
    } on TimeoutException catch (e) {
      throw GradingForecastApiException(
        message: 'The server is taking too long. Please try again.',
        cause: e,
      );
    } on SocketException catch (e) {
      throw GradingForecastApiException(
        message: 'Cannot reach the backend. Check your connection and try again.',
        cause: e,
      );
    } on GradingForecastApiException {
      rethrow;
    } catch (e) {
      throw GradingForecastApiException(
        message: 'Something went wrong while analyzing the image. Please try again.',
        cause: e,
      );
    }
  }

  Future<RecommendationResult> recommend({
    required String grade,
    required String trend,
    double? qualityScore,
    int? currentPriceLkrPerKg,
    int? predictedPriceLkrPerKg,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/grading-forecast/recommend');

    final payload = <String, dynamic>{
      'grade': grade,
      'trend': trend,
    };

    if (qualityScore != null) {
      payload['quality_score'] = qualityScore;
    }
    if (currentPriceLkrPerKg != null) {
      payload['current_price_lkr_per_kg'] = currentPriceLkrPerKg;
    }
    if (predictedPriceLkrPerKg != null) {
      payload['predicted_price_lkr_per_kg'] = predictedPriceLkrPerKg;
    }

    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GradingForecastApiException(
          statusCode: response.statusCode,
          message: _bestEffortErrorMessage(response.body, response.statusCode),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map) {
        throw GradingForecastApiException(
          statusCode: response.statusCode,
          message: 'Unexpected response format from server.',
        );
      }

      final recommendationJson = decoded['recommendation'];
      if (recommendationJson is! Map) {
        throw GradingForecastApiException(
          statusCode: response.statusCode,
          message: 'Unexpected response format from server.',
        );
      }

      return RecommendationResult.fromJson(Map<String, dynamic>.from(recommendationJson));
    } on TimeoutException catch (e) {
      throw GradingForecastApiException(
        message: 'The server is taking too long. Please try again.',
        cause: e,
      );
    } on SocketException catch (e) {
      throw GradingForecastApiException(
        message: 'Cannot reach the backend. Check your connection and try again.',
        cause: e,
      );
    } on GradingForecastApiException {
      rethrow;
    } catch (e) {
      throw GradingForecastApiException(
        message: 'Something went wrong while updating the recommendation. Please try again.',
        cause: e,
      );
    }
  }

  static String _bestEffortErrorMessage(String body, int statusCode) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'Request failed (HTTP $statusCode).';

    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail.trim();
        if (detail is List) {
          final messages = detail
              .map((e) => e is Map ? e['msg']?.toString() : null)
              .where((e) => e != null && e.trim().isNotEmpty)
              .cast<String>()
              .toList();
          if (messages.isNotEmpty) return messages.join('\n');
        }
        if (detail is Map) {
          final msg = detail['msg']?.toString();
          if (msg != null && msg.trim().isNotEmpty) return msg.trim();
        }
      }
    } catch (_) {
      // ignore JSON parse errors
    }

    return 'Request failed (HTTP $statusCode).';
  }

  static String _defaultBaseUrl() {
    const defined = String.fromEnvironment(_envKey);
    if (defined.trim().isNotEmpty) return defined.trim();

    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  static String _sanitizeBaseUrl(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
