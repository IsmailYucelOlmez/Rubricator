class SemanticSearchRequest {
  const SemanticSearchRequest({
    required this.query,
    this.mode = SemanticSearchMode.simple,
    this.category = 'All',
    this.tone = 'All',
    this.limit = 16,
    this.language,
  });

  final String query;
  final SemanticSearchMode mode;
  final String category;
  final String tone;
  final int limit;
  final String? language;

  Map<String, dynamic> toJson() => {
        'query': query,
        'mode': mode.name,
        'category': category,
        'tone': tone,
        'limit': limit,
        if (language != null) 'language': language,
      };
}

enum SemanticSearchMode { simple, advanced }
