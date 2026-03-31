import '../../../../services/api_service.dart';
import '../models/home_book_model.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._api);

  final ApiService _api;

  Future<List<HomeBookModel>> fetchBooksByGenre(String genre) async {
    final safeGenre = genre.trim();
    if (safeGenre.isEmpty) return const <HomeBookModel>[];
    final json = await _api.getJson(
      '/subjects/$safeGenre.json',
      queryParameters: <String, dynamic>{'limit': 20},
    );
    final works = json['works'] as List<dynamic>? ?? <dynamic>[];
    return works
        .whereType<Map<String, dynamic>>()
        .map(HomeBookModel.fromSubjectWork)
        .toList();
  }

  Future<List<HomeBookModel>> fetchPopularBooks() {
    return fetchBooksByGenre('fiction');
  }

  Future<List<HomeBookModel>> searchBooks(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const <HomeBookModel>[];
    final json = await _api.getJson(
      '/search.json',
      queryParameters: <String, dynamic>{'q': q, 'limit': 30},
    );
    final docs = json['docs'] as List<dynamic>? ?? <dynamic>[];
    return docs
        .whereType<Map<String, dynamic>>()
        .map(HomeBookModel.fromSearchDoc)
        .toList();
  }
}
