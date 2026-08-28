import 'package:dio/dio.dart';

import '../../../../core/env.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/supabase_service.dart';
import '../models/chat_response_model.dart';
import '../models/create_session_response_model.dart';
import '../models/session_status_response_model.dart';
import 'document_chat_exception.dart';

/// Document-chat FastAPI traffic goes through the `rubricatorApi` edge function
/// so the API key stays a Supabase secret, not a client bundle value.
class DocumentChatApiDataSource {
  DocumentChatApiDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: '${SupabaseService.url}/functions/v1/rubricatorApi',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 90),
                sendTimeout: const Duration(seconds: 60),
                headers: SupabaseService.edgeFunctionHeaders(),
                validateStatus: (code) => code != null && code < 500,
              ),
            );

  final Dio _dio;

  void _ensureConfigured() {
    if (!Env.hasSemanticApiConfig) {
      throw StateError(
        'Semantic API is not configured. Supabase must be initialized.',
      );
    }
  }

  Future<CreateSessionResponseModel> createSession({
    required String filePath,
    required String filename,
  }) async {
    _ensureConfigured();
    AppLogger.info('document_chat', 'POST /api/v1/sessions', data: {
      'filename': filename,
      'baseUrl': _dio.options.baseUrl,
    });

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sessions',
        data: formData,
      );

      AppLogger.info(
        'document_chat',
        'POST /api/v1/sessions → ${response.statusCode}',
      );

      if (response.statusCode != 201) {
        throw DocumentChatException.fromResponse(response);
      }
      final raw = response.data;
      final json = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map? ?? const {});
      final model = CreateSessionResponseModel.fromJson(json);
      AppLogger.info('document_chat', 'Session created', data: {
        'sessionId': model.sessionId,
        'status': model.status.name,
        'filename': model.filename,
      });
      return model;
    } on DocumentChatException {
      rethrow;
    } on DioException catch (error, stackTrace) {
      await AppLogger.error('document_chat', 'Create session failed', error, stackTrace);
      throw DocumentChatException.fromDio(error);
    } catch (error, stackTrace) {
      await AppLogger.error('document_chat', 'Create session failed', error, stackTrace);
      rethrow;
    }
  }

  Future<SessionStatusResponseModel> getSessionStatus(String sessionId) async {
    _ensureConfigured();
    try {
      AppLogger.info('document_chat', 'GET /api/v1/sessions/$sessionId');
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/sessions/$sessionId',
      );
      if (response.statusCode != 200) {
        throw DocumentChatException.fromResponse(response);
      }
      final raw = response.data;
      final json = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map? ?? const {});
      final model = SessionStatusResponseModel.fromJson(json);
      AppLogger.info('document_chat', 'Session status', data: {
        'sessionId': sessionId,
        'status': model.status.name,
        'chunksEmbedded': model.chunksEmbedded,
        'chunksTotal': model.chunksTotal,
      });
      return model;
    } on DocumentChatException {
      rethrow;
    } on DioException catch (error, stackTrace) {
      await AppLogger.error('document_chat', 'Get session failed', error, stackTrace);
      throw DocumentChatException.fromDio(error);
    }
  }

  Future<ChatResponseModel> askQuestion({
    required String sessionId,
    required String question,
  }) async {
    _ensureConfigured();
    AppLogger.info('document_chat', 'POST /api/v1/sessions/$sessionId/chat');

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sessions/$sessionId/chat',
        data: {'question': question},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode != 200) {
        throw DocumentChatException.fromResponse(response);
      }
      return ChatResponseModel.fromJson(response.data ?? const {});
    } on DocumentChatException {
      rethrow;
    } on DioException catch (error, stackTrace) {
      await AppLogger.error('document_chat', 'Chat failed', error, stackTrace);
      throw DocumentChatException.fromDio(error);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    _ensureConfigured();
    try {
      await _dio.delete('/api/v1/sessions/$sessionId');
    } on DioException catch (error, stackTrace) {
      await AppLogger.error('document_chat', 'Delete session failed', error, stackTrace);
      // Best-effort cleanup; ignore network errors on dispose.
    }
  }
}
