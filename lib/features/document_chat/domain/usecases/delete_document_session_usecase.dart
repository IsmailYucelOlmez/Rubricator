import '../repositories/document_chat_repository.dart';

class DeleteDocumentSessionUseCase {
  const DeleteDocumentSessionUseCase(this._repository);

  final DocumentChatRepository _repository;

  Future<void> call(String sessionId) {
    return _repository.deleteSession(sessionId);
  }
}
