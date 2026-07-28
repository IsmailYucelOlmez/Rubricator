import 'package:dio/dio.dart';

import '../../../../core/env.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/semantic_book_result_model.dart';
import '../../domain/entities/semantic_search_request.dart';

class SemanticApiDataSource {
  SemanticApiDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.semanticApiBaseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 20),
                headers: _defaultHeaders(),
                validateStatus: (code) => code != null && code < 500,
              ),
            );

  final Dio _dio;

  static Map<String, String> _defaultHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final apiKey = Env.semanticApiKey.trim();
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  Future<List<SemanticBookResultModel>> search(SemanticSearchRequest request) async {
    if (!Env.hasSemanticApiConfig) {
      throw StateError(
        'Semantic API is not configured. Set SEMANTIC_API_BASE_URL in env.',
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
