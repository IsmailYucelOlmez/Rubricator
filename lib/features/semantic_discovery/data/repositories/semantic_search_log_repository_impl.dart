import '../../domain/entities/semantic_search_log_entity.dart';
import '../../domain/repositories/semantic_search_log_repository.dart';
import '../datasources/semantic_search_log_remote_datasource.dart';

class SemanticSearchLogRepositoryImpl implements SemanticSearchLogRepository {
  const SemanticSearchLogRepositoryImpl(this._remote);

  final SemanticSearchLogRemoteDataSource _remote;

  @override
  Future<void> logSearch(SemanticSearchLogEntity entry) {
    return _remote.logSearch(
      query: entry.query,
      mode: entry.mode.name,
      category: entry.category,
      tone: entry.tone,
      resultCount: entry.resultCount,
    );
  }
}
