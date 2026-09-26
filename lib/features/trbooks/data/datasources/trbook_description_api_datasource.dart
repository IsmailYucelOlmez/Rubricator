import 'package:dio/dio.dart';

import '../../../../core/env.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/supabase_service.dart';

/// Generates a spoiler-free, non-copied Turkish book description via the
/// FastAPI backend's Gemini integration, reached through the same
/// `rubricatorApi` edge-function proxy used by semantic search — the Gemini
/// API key stays a server secret, never a client bundle value. See
/// [SemanticApiDataSource] for the identical proxy pattern.
class TrbookDescriptionApiDataSource {
  TrbookDescriptionApiDataSource({Dio? dio})
    : _dio =
          dio ??
                Dio(
                  BaseOptions(
                    baseUrl:
                        '${SupabaseService.url}/functions/v1/rubricatorApi',
                    connectTimeout: const Duration(seconds: 20),
                    receiveTimeout: const Duration(seconds: 30),
                    sendTimeout: const Duration(seconds: 20),
                    headers: {'Content-Type': 'application/json'},
                    validateStatus: (code) => code != null && code < 500,
                  ),
                )
            ..interceptors.add(SupabaseService.edgeFunctionAuthInterceptor());

  final Dio _dio;

  Future<String> generateDescription({
    required String title,
    required String author,
    required String isbn,
  }) async {
    if (!Env.hasSemanticApiConfig) {
      throw StateError(
        'Description generation API is not configured. Supabase must be initialized.',
      );
    }

    final payload = {
      'title': title,
      'author': author,
      'isbn': isbn,
      'language': 'tr',
    };
    AppLogger.info(
      'trbooks',
      'POST /api/v1/trbooks/generate-description',
      data: payload,
    );
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/trbooks/generate-description',
        data: payload,
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception(
          'Description generation returned ${response.statusCode}',
        );
      }
      final description = response.data?['description'] as String?;
      if (description == null || description.trim().isEmpty) {
        throw Exception('Description generation returned an empty result.');
      }
      return description.trim();
    } on DioException catch (error, stackTrace) {
      await AppLogger.error(
        'trbooks',
        'Description generation failed',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
