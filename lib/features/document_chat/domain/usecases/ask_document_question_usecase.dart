import '../repositories/document_chat_repository.dart';

class AskDocumentQuestionUseCase {
  const AskDocumentQuestionUseCase(this._repository);

  final DocumentChatRepository _repository;

  Future<DocumentChatAnswer> call({
    required String sessionId,
    required String question,
  }) {
    return _repository.askQuestion(
      sessionId: sessionId,
      question: question,
    );
  }
}
