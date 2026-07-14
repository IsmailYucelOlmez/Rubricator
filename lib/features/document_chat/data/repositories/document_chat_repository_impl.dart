import '../../domain/entities/document_session.dart';
import '../../domain/repositories/document_chat_repository.dart';
import '../datasources/document_chat_api_datasource.dart';

class DocumentChatRepositoryImpl implements DocumentChatRepository {
  const DocumentChatRepositoryImpl(this._remote);

  final DocumentChatApiDataSource _remote;

  @override
  Future<DocumentSession> createSession({
    required String filePath,
    required String filename,
  }) async {
    final model = await _remote.createSession(
      filePath: filePath,
      filename: filename,
    );
    return model.toEntity();
  }

  @override
  Future<DocumentSession> getSessionStatus(String sessionId) async {
    final model = await _remote.getSessionStatus(sessionId);
    return model.toEntity();
  }

  @override
  Future<DocumentChatAnswer> askQuestion({
    required String sessionId,
    required String question,
  }) async {
    final model = await _remote.askQuestion(
      sessionId: sessionId,
      question: question,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteSession(String sessionId) {
    return _remote.deleteSession(sessionId);
  }
}
