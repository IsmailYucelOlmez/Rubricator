class SemanticSearchRequest {
  const SemanticSearchRequest({
    required this.query,
    this.mode = SemanticSearchMode.simple,
    this.category = 'All',
    this.tone = 'All',
    this.limit = 16,
    this.language,
    this.relevantIsbns = const [],
    this.irrelevantIsbns = const [],
  });

  /// The API rejects more than this many ISBNs per side with a 422.
  static const maxRefinementIsbns = 5;

  final String query;
  final SemanticSearchMode mode;
  final String category;
  final String tone;
  final int limit;
  final String? language;

  /// Books the user marked in this search's earlier results. The API pulls
  /// the query toward [relevantIsbns] and away from [irrelevantIsbns], and
  /// leaves the irrelevant ones out of the results.
  final List<String> relevantIsbns;
  final List<String> irrelevantIsbns;

  bool get isRefined => relevantIsbns.isNotEmpty || irrelevantIsbns.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'query': query,
    'mode': mode.name,
    'category': category,
    'tone': tone,
    'limit': limit,
    if (language != null) 'language': language,
    if (isRefined)
      'feedback': {
        'relevant': relevantIsbns.take(maxRefinementIsbns).toList(),
        'irrelevant': irrelevantIsbns.take(maxRefinementIsbns).toList(),
      },
  };
}

enum SemanticSearchMode { simple, advanced }
