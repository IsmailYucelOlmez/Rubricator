import '../../domain/entities/document_session.dart';
import 'json_parsers.dart';

class CreateSessionResponseModel {
  const CreateSessionResponseModel({
    required this.sessionId,
    required this.format,
    required this.filename,
    required this.expiresAt,
    required this.status,
    required this.chunkCount,
    required this.questionsRemaining,
    this.pageCount,
    this.chapterCount,
    this.wordCount = 0,
    this.truncated = false,
    this.errorMessage,
    this.chunksEmbedded = 0,
    this.chunksTotal = 0,
    this.questionCount = 0,
  });

  final String sessionId;
  final String format;
  final String filename;
  final DateTime expiresAt;
  final DocumentSessionStatus status;
  final int chunkCount;
  final int questionsRemaining;
  final int? pageCount;
  final int? chapterCount;
  final int wordCount;
  final bool truncated;
  final String? errorMessage;
  final int chunksEmbedded;
  final int chunksTotal;
  final int questionCount;

  factory CreateSessionResponseModel.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'];
    final remaining = limits is Map<String, dynamic>
        ? parseInt(limits['maxQuestionsRemaining'], 10)
        : parseInt(json['questionsRemaining'], 10);

    return CreateSessionResponseModel(
      sessionId: json['sessionId']?.toString() ?? '',
      format: json['format']?.toString() ?? 'pdf',
      filename: json['filename']?.toString() ?? '',
      expiresAt: parseApiDateTime(json['expiresAt']) ??
          DateTime.now().toUtc().add(const Duration(minutes: 45)),
      status: parseDocumentSessionStatus(json['status']?.toString()),
      chunkCount: parseInt(json['chunkCount']),
      questionsRemaining: remaining,
      pageCount: parseOptionalInt(json['pageCount']),
      chapterCount: parseOptionalInt(json['chapterCount']),
      wordCount: parseInt(json['wordCount']),
      truncated: parseBool(json['truncated']),
      errorMessage: json['errorMessage']?.toString(),
      chunksEmbedded: parseInt(json['chunksEmbedded']),
      chunksTotal: parseInt(json['chunksTotal']),
      questionCount: parseInt(json['questionCount']),
    );
  }

  DocumentSession toEntity() {
    return DocumentSession(
      sessionId: sessionId,
      format: format,
      filename: filename,
      expiresAt: expiresAt,
      status: status,
      chunkCount: chunkCount,
      questionsRemaining: questionsRemaining,
      pageCount: pageCount,
      chapterCount: chapterCount,
      wordCount: wordCount,
      truncated: truncated,
      errorMessage: errorMessage,
      chunksEmbedded: chunksEmbedded,
      chunksTotal: chunksTotal,
      questionCount: questionCount,
    );
  }
}
