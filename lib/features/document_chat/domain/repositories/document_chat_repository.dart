import '../entities/document_chat_source.dart';
import '../entities/document_session.dart';

class DocumentChatAnswer {
  const DocumentChatAnswer({
    required this.answer,
    required this.sources,
    required this.sessionExpiresAt,
    required this.questionsRemaining,
  });

  final String answer;
  final List<DocumentChatSource> sources;
  final DateTime sessionExpiresAt;
  final int questionsRemaining;
}

abstract class DocumentChatRepository {
  Future<DocumentSession> createSession({
    required String filePath,
    required String filename,
  });

  Future<DocumentSession> getSessionStatus(String sessionId);

  Future<DocumentChatAnswer> askQuestion({
    required String sessionId,
    required String question,
  });

  Future<void> deleteSession(String sessionId);
}
