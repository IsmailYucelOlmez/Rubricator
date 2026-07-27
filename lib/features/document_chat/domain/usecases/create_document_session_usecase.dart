import '../entities/document_session.dart';
import '../repositories/document_chat_repository.dart';

class CreateDocumentSessionUseCase {
  const CreateDocumentSessionUseCase(this._repository);

  final DocumentChatRepository _repository;

  Future<DocumentSession> call({
    required String filePath,
    required String filename,
  }) {
    return _repository.createSession(
      filePath: filePath,
      filename: filename,
    );
  }
}
