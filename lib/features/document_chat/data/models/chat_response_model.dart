import '../../domain/entities/document_chat_source.dart';
import '../../domain/repositories/document_chat_repository.dart';
import 'json_parsers.dart';

class ChatResponseModel {
  const ChatResponseModel({
    required this.answer,
    required this.sources,
    required this.sessionExpiresAt,
    required this.questionsRemaining,
  });

  final String answer;
  final List<DocumentChatSource> sources;
  final DateTime sessionExpiresAt;
  final int questionsRemaining;

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as List<dynamic>? ?? const [];
    return ChatResponseModel(
      answer: json['answer']?.toString() ?? '',
      sources: rawSources
          .whereType<Map<String, dynamic>>()
          .map(_sourceFromJson)
          .toList(),
      sessionExpiresAt: parseApiDateTime(json['sessionExpiresAt']) ??
          DateTime.now().toUtc().add(const Duration(minutes: 45)),
      questionsRemaining: parseInt(json['questionsRemaining']),
    );
  }

  DocumentChatAnswer toEntity() {
    return DocumentChatAnswer(
      answer: answer,
      sources: sources,
      sessionExpiresAt: sessionExpiresAt,
      questionsRemaining: questionsRemaining,
    );
  }

  static DocumentChatSource _sourceFromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    return DocumentChatSource(
      chunkIndex: parseInt(json['chunkIndex']),
      excerpt: json['excerpt']?.toString() ?? '',
      metadata: metadata is Map<String, dynamic>
          ? Map<String, dynamic>.from(metadata)
          : const <String, dynamic>{},
    );
  }
}
