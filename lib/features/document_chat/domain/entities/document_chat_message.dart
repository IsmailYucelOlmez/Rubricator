import 'document_chat_source.dart';

class DocumentChatMessage {
  const DocumentChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.sources = const [],
    required this.createdAt,
  });

  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<DocumentChatSource> sources;
  final DateTime createdAt;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
