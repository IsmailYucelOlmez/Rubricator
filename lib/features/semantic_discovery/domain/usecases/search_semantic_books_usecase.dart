import '../entities/semantic_book_result.dart';
import '../entities/semantic_search_log_entity.dart';
import '../entities/semantic_search_request.dart';
import '../repositories/semantic_discovery_repository.dart';
import '../repositories/semantic_search_log_repository.dart';

class SearchSemanticBooksUseCase {
  const SearchSemanticBooksUseCase(
    this._repository, [
    this._logRepository,
  ]);

  final SemanticDiscoveryRepository _repository;
  final SemanticSearchLogRepository? _logRepository;

  Future<List<SemanticBookResult>> call(SemanticSearchRequest request) async {
    final results = await _repository.search(request);
    final logger = _logRepository;
    if (logger != null) {
      try {
        await logger.logSearch(
          SemanticSearchLogEntity(
            query: request.query,
            mode: request.mode,
            category: request.category,
            tone: request.tone,
            resultCount: results.length,
          ),
        );
      } catch (_) {}
    }
    return results;
  }
}
