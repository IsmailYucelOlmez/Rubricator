import '../entities/semantic_book_result.dart';
import '../entities/semantic_search_request.dart';

abstract class SemanticDiscoveryRepository {
  Future<List<SemanticBookResult>> search(SemanticSearchRequest request);
}
