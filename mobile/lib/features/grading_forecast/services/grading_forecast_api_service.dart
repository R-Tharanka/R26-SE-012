import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/grading_forecast_result.dart';

class GradingForecastApiException implements Exception {
  const GradingForecastApiException(
    this.message, {
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
    : _baseUrl = _resolveBaseUrl(baseUrlOverride);
  final String _baseUrl;
  String get baseUrl => _baseUrl;
  Future<GradingForecastResult> analyzeBytes(
    Uint8List bytes,
    String filename,
  ) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/api/v1/grading-forecast/analyze'),
          )
          ..files.add(
            http.MultipartFile.fromBytes('image', bytes, filename: filename),
          );
    try {
      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 120)),
      );
      final decoded = response.body.isEmpty ? null : json.decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map ? decoded['detail']?.toString() : null;
        throw GradingForecastApiException(
          detail ?? 'Analysis failed.',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map) {
        throw const GradingForecastApiException('Unexpected response format.');
      }
      return GradingForecastResult.fromJson(decoded.cast<String, dynamic>());
    } on GradingForecastApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw GradingForecastApiException(
        'Analysis timed out. Please retry.',
        cause: e,
      );
    } on SocketException catch (e) {
      throw GradingForecastApiException(
        'Cannot reach the research backend.',
        cause: e,
      );
    } on http.ClientException catch (e) {
      throw GradingForecastApiException(
        'Cannot reach the research backend.',
        cause: e,
      );
    } on FormatException catch (e) {
      throw GradingForecastApiException(
        'Backend returned malformed data.',
        cause: e,
      );
    }
  }

  static String _resolveBaseUrl(String? override) {
    if (override != null && override.trim().isNotEmpty) {
      return override.replaceAll(RegExp(r'/$'), '');
    }
    const configured = String.fromEnvironment('PEPPER_API_BASE_URL');
    if (configured.isNotEmpty) return configured.replaceAll(RegExp(r'/$'), '');
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
