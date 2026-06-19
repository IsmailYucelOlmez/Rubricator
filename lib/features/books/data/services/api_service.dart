import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/supabase_service.dart';

/// Google Books traffic goes through the `google-books` edge function so
/// [GOOGLE_BOOKS_API_KEY] stays a Supabase secret, not a client bundle value.
class ApiService {
  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: '${SupabaseService.url}/functions/v1/google-books',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: SupabaseService.edgeFunctionHeaders(),
          validateStatus: (code) => code != null && code < 500,
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _getJsonOnce(path, queryParameters: queryParameters);
  }

  /// Retries on 429 / 5xx with exponential backoff (1s, 2s, 4s).
  Future<Map<String, dynamic>> getJsonWithRetry(
    String path, {
    Map<String, dynamic>? queryParameters,
    int maxAttempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
      try {
        return await _getJsonOnce(path, queryParameters: queryParameters);
      } catch (e) {
        lastError = e;
        final message = e.toString();
        final isRetryable =
            message.contains('429') ||
            message.contains('502') ||
            message.contains('503') ||
            message.contains('504') ||
            message.contains('Network error');
        if (!isRetryable || attempt == maxAttempts - 1) {
          rethrow;
        }
      }
    }
    throw Exception('Request failed after retries: $lastError');
  }

  Future<Map<String, dynamic>> _getJsonOnce(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    AppLogger.info('api', 'GET $path', data: queryParameters);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final data = response.data;
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception(
          'Google Books proxy returned ${response.statusCode} for $path',
        );
      }
      AppLogger.info('api', 'GET $path OK', data: {'status': response.statusCode});
      return data ?? <String, dynamic>{};
    } on DioException catch (e, stackTrace) {
      await AppLogger.error('api', 'GET $path failed', e, stackTrace);
      final type = e.type.name;
      throw Exception(
        e.message != null && e.message!.isNotEmpty
            ? 'Network error ($type): ${e.message}'
            : 'Network error ($type)',
      );
    }
  }
}
