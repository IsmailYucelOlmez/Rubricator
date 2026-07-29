import 'package:dio/dio.dart';

import '../../../../core/env.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/supabase_service.dart';
import '../models/semantic_book_result_model.dart';
import '../../domain/entities/semantic_search_request.dart';

/// Semantic FastAPI traffic goes through the `rubricatorApi` edge function so
/// the API key stays a Supabase secret, not a client bundle value.
class SemanticApiDataSource {
  SemanticApiDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: '${SupabaseService.url}/functions/v1/rubricatorApi',
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 20),
                headers: {
                  ...SupabaseService.edgeFunctionHeaders(),
                  'Content-Type': 'application/json',
                },
                validateStatus: (code) => code != null && code < 500,
              ),
            );

  final Dio _dio;

  Future<List<SemanticBookResultModel>> search(SemanticSearchRequest request) async {
    if (!Env.hasSemanticApiConfig) {
      throw StateError(
        'Semantic API is not configured. Supabase must be initialized.',
      );
    }

    AppLogger.info('semantic', 'POST /api/v1/semantic/search', data: request.toJson());
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/semantic/search',
        data: request.toJson(),
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception(
          'Semantic search returned ${response.statusCode}',
        );
      }
      final data = response.data ?? <String, dynamic>{};
      final rawResults = data['results'] as List<dynamic>? ?? const [];
      return rawResults
          .whereType<Map<String, dynamic>>()
          .map(SemanticBookResultModel.fromJson)
          .where((model) => model.isbn13.isNotEmpty)
          .toList();
    } on DioException catch (error, stackTrace) {
      await AppLogger.error('semantic', 'Search failed', error, stackTrace);
      rethrow;
    }
  }
}
