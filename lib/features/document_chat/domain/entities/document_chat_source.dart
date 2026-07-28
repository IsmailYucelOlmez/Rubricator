class DocumentChatSource {
  const DocumentChatSource({
    required this.chunkIndex,
    required this.excerpt,
    required this.metadata,
  });

  final int chunkIndex;
  final String excerpt;
  final Map<String, dynamic> metadata;

  String? get pageLabel {
    final page = metadata['page'];
    if (page == null) return null;
    return 'p. $page';
  }

  String? get chapterLabel {
    final title = metadata['chapter_title'];
    if (title is String && title.trim().isNotEmpty) return title;
    return null;
  }
}
