import '../../../books/data/services/api_service.dart';
import '../../../books/data/utils/google_books_utils.dart';
import '../models/home_book_model.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._api, {this.lang = 'tr'});

  final ApiService _api;
  final String lang;

  static String subjectQueryTerm(String genreKey) {
    return genreKey.trim().replaceAll('"', ' ').replaceAll('_', ' ');
  }

  Map<String, dynamic> _listParams({
    required String q,
    int maxResults = 30,
    String? orderBy,
  }) {
    return <String, dynamic>{
      'q': q,
      ...GoogleBooksUtils.baseListParams(
        lang: lang,
        maxResults: maxResults,
        orderBy: orderBy,
      ),
    };
  }

  List<HomeBookModel> _parseVolumeItems(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? <dynamic>[];
    final parsed = <HomeBookModel>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      try {
        parsed.add(HomeBookModel.fromGoogleVolume(item));
      } catch (_) {
        // Skip malformed volume payloads; one bad item should not fail the row.
      }
    }
    return parsed;
  }

  Future<List<HomeBookModel>> fetchBooksByGenre(
    String genre, {
    int maxResults = 30,
  }) async {
    final safeGenre = subjectQueryTerm(genre);
    if (safeGenre.isEmpty) return const <HomeBookModel>[];
    final q = GoogleBooksUtils.buildSubjectSearchQuery(safeGenre);
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(q: q, maxResults: maxResults),
    );
    return _parseVolumeItems(json);
  }

  Future<List<HomeBookModel>> fetchPopularBooks({int maxResults = 30}) async {
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(
        q: 'subject:fiction',
        maxResults: maxResults,
      ),
    );
    return _parseVolumeItems(json);
  }

  Future<List<HomeBookModel>> searchBooks(String query) async {
    final q = GoogleBooksUtils.buildTitleSearchQuery(query);
    if (q.isEmpty) return const <HomeBookModel>[];
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(q: q, maxResults: 30),
    );
    return _parseVolumeItems(json);
  }
}
