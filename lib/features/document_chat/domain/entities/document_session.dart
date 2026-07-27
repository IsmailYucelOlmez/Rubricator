enum DocumentSessionStatus { processing, ready, failed }

class DocumentSession {
  const DocumentSession({
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

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());
  bool get isReady => status == DocumentSessionStatus.ready;
  bool get isProcessing => status == DocumentSessionStatus.processing;
  bool get isFailed => status == DocumentSessionStatus.failed;

  double? get embedProgress {
    if (chunksTotal <= 0) return null;
    return (chunksEmbedded / chunksTotal).clamp(0.0, 1.0);
  }

  DocumentSession copyWith({
    String? sessionId,
    String? format,
    String? filename,
    DateTime? expiresAt,
    DocumentSessionStatus? status,
    int? chunkCount,
    int? questionsRemaining,
    int? pageCount,
    int? chapterCount,
    int? wordCount,
    bool? truncated,
    String? errorMessage,
    int? chunksEmbedded,
    int? chunksTotal,
    int? questionCount,
  }) {
    return DocumentSession(
      sessionId: sessionId ?? this.sessionId,
      format: format ?? this.format,
      filename: filename ?? this.filename,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      chunkCount: chunkCount ?? this.chunkCount,
      questionsRemaining: questionsRemaining ?? this.questionsRemaining,
      pageCount: pageCount ?? this.pageCount,
      chapterCount: chapterCount ?? this.chapterCount,
      wordCount: wordCount ?? this.wordCount,
      truncated: truncated ?? this.truncated,
      errorMessage: errorMessage ?? this.errorMessage,
      chunksEmbedded: chunksEmbedded ?? this.chunksEmbedded,
      chunksTotal: chunksTotal ?? this.chunksTotal,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}
