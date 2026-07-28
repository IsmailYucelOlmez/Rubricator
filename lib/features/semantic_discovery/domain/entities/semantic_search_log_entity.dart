import '../entities/semantic_search_request.dart';

class SemanticSearchLogEntity {
  const SemanticSearchLogEntity({
    required this.query,
    required this.mode,
    this.category,
    this.tone,
    required this.resultCount,
  });

  final String query;
  final SemanticSearchMode mode;
  final String? category;
  final String? tone;
  final int resultCount;
}
