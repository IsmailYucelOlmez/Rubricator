import '../../domain/entities/semantic_book_result.dart';
import '../../domain/entities/semantic_search_request.dart';
import '../../domain/repositories/semantic_discovery_repository.dart';
import '../datasources/semantic_api_datasource.dart';

class SemanticDiscoveryRepositoryImpl implements SemanticDiscoveryRepository {
  const SemanticDiscoveryRepositoryImpl(this._remote);

  final SemanticApiDataSource _remote;

  @override
  Future<List<SemanticBookResult>> search(SemanticSearchRequest request) async {
    final models = await _remote.search(request);
    return models.map((model) => model.toEntity()).toList();
  }
}
