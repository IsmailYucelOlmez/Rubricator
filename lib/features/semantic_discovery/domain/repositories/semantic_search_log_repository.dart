import '../entities/semantic_search_log_entity.dart';

abstract class SemanticSearchLogRepository {
  Future<void> logSearch(SemanticSearchLogEntity entry);
}
