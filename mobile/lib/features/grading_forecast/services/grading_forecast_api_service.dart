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
  GradingForecastApiService({String? baseUrlOverride, http.Client? client})
    : _baseUrl = _resolveBaseUrl(baseUrlOverride),
      _client = client ?? http.Client(),
      _ownsClient = client == null;
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const Duration requestTimeout = Duration(seconds: 120);
  final String _baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  String get baseUrl => _baseUrl;
  Future<GradingForecastResult> analyzeBytes(
    Uint8List bytes,
    String filename,
  ) async {
    if (bytes.isEmpty) {
      throw const GradingForecastApiException('The selected image is empty.');
    }
    if (bytes.length > maxImageBytes) {
      throw const GradingForecastApiException(
        'The selected image exceeds the 10 MB upload limit.',
        statusCode: 413,
      );
    }
    final endpoint = Uri.tryParse('$_baseUrl/api/v1/grading-forecast/analyze');
    if (endpoint == null ||
        !endpoint.hasScheme ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https')) {
      throw const GradingForecastApiException(
        'The research backend address is invalid.',
      );
    }
    final request =
        http.MultipartRequest(
            'POST',
            endpoint,
          )
          ..files.add(
            http.MultipartFile.fromBytes('image', bytes, filename: filename),
          );
    try {
      final streamed = await _client.send(request).timeout(requestTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(requestTimeout);
      Object? decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = json.decode(response.body);
        } on FormatException {
          if (response.statusCode >= 200 && response.statusCode < 300) {
            rethrow;
          }
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = _responseDetail(decoded);
        throw GradingForecastApiException(
          detail ?? _messageForStatus(response.statusCode),
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

  void close() {
    if (_ownsClient) _client.close();
  }

  static String? _responseDetail(Object? decoded) {
    if (decoded is! Map) return null;
    final detail = decoded['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      return 'The request was rejected because one or more fields are invalid.';
    }
    return null;
  }

  static String _messageForStatus(int statusCode) => switch (statusCode) {
    400 => 'The selected file is not a readable image.',
    413 => 'The selected image exceeds the safe upload or processing limit.',
    415 => 'Use a non-animated JPEG, PNG, or WEBP image.',
    422 => 'The image request is malformed.',
    429 => 'The hosted service is busy. Please wait and retry.',
    502 || 503 || 504 =>
      'The research backend is temporarily unavailable. Please retry later.',
    _ => 'Analysis failed on the research backend.',
  };

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
