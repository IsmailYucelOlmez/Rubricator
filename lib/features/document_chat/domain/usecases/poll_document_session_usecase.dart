import '../entities/document_session.dart';
import '../repositories/document_chat_repository.dart';

class PollDocumentSessionUseCase {
  const PollDocumentSessionUseCase(this._repository);

  final DocumentChatRepository _repository;

  Future<DocumentSession> call(String sessionId) {
    return _repository.getSessionStatus(sessionId);
  }
}
