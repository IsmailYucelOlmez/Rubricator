import '../entities/semantic_search_log_entity.dart';
import '../repositories/semantic_search_log_repository.dart';

class LogSemanticSearchUseCase {
  const LogSemanticSearchUseCase(this._repository);

  final SemanticSearchLogRepository _repository;

  Future<void> call(SemanticSearchLogEntity entry) => _repository.logSearch(entry);
}
