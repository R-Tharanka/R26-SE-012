import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      : _baseUrls = _resolveBaseUrls(baseUrlOverride);

  static const _envKey = 'PEPPER_API_BASE_URL';
  static const _fallbackEnvKey = 'PEPPER_API_FALLBACK_BASE_URL';
  static const _analyzeTimeout = Duration(seconds: 120);
  static const _recommendTimeout = Duration(seconds: 45);
  static const _maxAttemptsPerBaseUrl = 2;
  static const _retryDelay = Duration(seconds: 2);

  final List<String> _baseUrls;

  String get baseUrl => _baseUrls.first;

  List<String> get baseUrls => List.unmodifiable(_baseUrls);

  Future<GradingForecastResult> analyzeBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    GradingForecastApiException? lastConnectionError;

    for (final baseUrl in _baseUrls) {
      final uri = Uri.parse('$baseUrl/api/v1/grading-forecast/analyze');

      for (var attempt = 1; attempt <= _maxAttemptsPerBaseUrl; attempt += 1) {
        try {
          final request = http.MultipartRequest('POST', uri);
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              imageBytes,
              filename: filename,
            ),
          );

          final streamed = await request.send().timeout(_analyzeTimeout);
          final response = await http.Response.fromStream(streamed);

          if (response.statusCode < 200 || response.statusCode >= 300) {
            final exception = GradingForecastApiException(
              statusCode: response.statusCode,
              message: _bestEffortErrorMessage(response.body, response.statusCode),
            );

            if (_isRetryableStatus(response.statusCode) &&
                attempt < _maxAttemptsPerBaseUrl) {
              lastConnectionError = exception;
              await Future<void>.delayed(_retryDelay);
              continue;
            }

            if (_shouldTryFallback(response.statusCode, baseUrl)) {
              lastConnectionError = exception;
              break;
            }

            throw exception;
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
          lastConnectionError = GradingForecastApiException(
            message: 'The hosted backend is still processing the image. Please try again.',
            cause: e,
          );
          if (attempt < _maxAttemptsPerBaseUrl) {
            await Future<void>.delayed(_retryDelay);
            continue;
          }
        } on SocketException catch (e) {
          lastConnectionError = GradingForecastApiException(
            message: 'Cannot reach the backend. Check your connection and try again.',
            cause: e,
          );
          if (attempt < _maxAttemptsPerBaseUrl) {
            await Future<void>.delayed(_retryDelay);
            continue;
          }
        } on http.ClientException catch (e) {
          lastConnectionError = GradingForecastApiException(
            message: 'Cannot reach the backend. Check your connection and try again.',
            cause: e,
          );
          if (attempt < _maxAttemptsPerBaseUrl) {
            await Future<void>.delayed(_retryDelay);
            continue;
          }
        } on GradingForecastApiException {
          rethrow;
        } catch (e) {
          throw GradingForecastApiException(
            message: 'Something went wrong while analyzing the image. Please try again.',
            cause: e,
          );
        }
      }
    }

    throw lastConnectionError ??
        GradingForecastApiException(
          message: 'Cannot reach the backend. Check your connection and try again.',
        );
  }

  Future<RecommendationResult> recommend({
    required String grade,
    required String trend,
    double? qualityScore,
    int? currentPriceLkrPerKg,
    int? predictedPriceLkrPerKg,
  }) async {
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

    GradingForecastApiException? lastConnectionError;

    for (final baseUrl in _baseUrls) {
      final uri = Uri.parse('$baseUrl/api/v1/grading-forecast/recommend');

      for (var attempt = 1; attempt <= _maxAttemptsPerBaseUrl; attempt += 1) {
        try {
          final response = await http
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: json.encode(payload),
              )
              .timeout(_recommendTimeout);

          if (response.statusCode < 200 || response.statusCode >= 300) {
            final exception = GradingForecastApiException(
              statusCode: response.statusCode,
              message: _bestEffortErrorMessage(response.body, response.statusCode),
            );

            if (_isRetryableStatus(response.statusCode) &&
                attempt < _maxAttemptsPerBaseUrl) {
              lastConnectionError = exception;
              await Future<void>.delayed(_retryDelay);
              continue;
            }

            if (_shouldTryFallback(response.statusCode, baseUrl)) {
              lastConnectionError = exception;
              break;
            }

            throw exception;
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

          return RecommendationResult.fromJson(
            Map<String, dynamic>.from(recommendationJson),
          );
        } on TimeoutException catch (e) {
          lastConnectionError = GradingForecastApiException(
            message: 'The server is taking too long. Please try again.',
            cause: e,
          );
          if (attempt < _maxAttemptsPerBaseUrl) {
            await Future<void>.delayed(_retryDelay);
            continue;
          }
        } on SocketException catch (e) {
          lastConnectionError = GradingForecastApiException(
            message: 'Cannot reach the backend. Check your connection and try again.',
            cause: e,
          );
          if (attempt < _maxAttemptsPerBaseUrl) {
            await Future<void>.delayed(_retryDelay);
            continue;
          }
        } on http.ClientException catch (e) {
          lastConnectionError = GradingForecastApiException(
            message: 'Cannot reach the backend. Check your connection and try again.',
            cause: e,
          );
          if (attempt < _maxAttemptsPerBaseUrl) {
            await Future<void>.delayed(_retryDelay);
            continue;
          }
        } on GradingForecastApiException {
          rethrow;
        } catch (e) {
          throw GradingForecastApiException(
            message: 'Something went wrong while updating the recommendation. Please try again.',
            cause: e,
          );
        }
      }
    }

    throw lastConnectionError ??
        GradingForecastApiException(
          message: 'Cannot reach the backend. Check your connection and try again.',
        );
  }

  static String _bestEffortErrorMessage(String body, int statusCode) {
    if (statusCode == 429) {
      return 'The hosted backend is rate limited. Please wait a minute and try again.';
    }

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

  static List<String> _resolveBaseUrls(String? baseUrlOverride) {
    final urls = <String>[];

    void addUrl(String? value) {
      if (value == null || value.trim().isEmpty) return;
      final sanitized = _sanitizeBaseUrl(value);
      if (sanitized.isNotEmpty && !urls.contains(sanitized)) {
        urls.add(sanitized);
      }
    }

    addUrl(baseUrlOverride);

    const defined = String.fromEnvironment(_envKey);
    addUrl(defined);

    const fallbackDefined = String.fromEnvironment(_fallbackEnvKey);
    addUrl(fallbackDefined);

    if (urls.isEmpty) {
      addUrl(_platformDefaultBaseUrl());
    }

    return urls;
  }

  bool _shouldTryFallback(int statusCode, String failedBaseUrl) {
    return failedBaseUrl != _baseUrls.last && _isRetryableStatus(statusCode);
  }

  static bool _isRetryableStatus(int statusCode) {
    return statusCode == 408 || statusCode >= 500;
  }

  static String _platformDefaultBaseUrl() {
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
