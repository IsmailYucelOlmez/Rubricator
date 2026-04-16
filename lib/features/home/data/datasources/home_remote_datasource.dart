import '../../../../services/api_service.dart';
import '../models/home_book_model.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._api);

  final ApiService _api;

  static String subjectQueryTerm(String genreKey) {
    return genreKey.trim().replaceAll('"', ' ').replaceAll('_', ' ');
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
    final q = safeGenre.contains(' ')
        ? 'subject:"$safeGenre"'
        : 'subject:$safeGenre';
    final json = await _api.getJson(
      '/volumes',
      queryParameters: <String, dynamic>{'q': q, 'maxResults': maxResults},
    );
    return _parseVolumeItems(json);
  }

  Future<List<HomeBookModel>> fetchPopularBooks({int maxResults = 30}) async {
    final json = await _api.getJson(
      '/volumes',
      queryParameters: <String, dynamic>{
        'q': 'subject:fiction',
        'maxResults': maxResults,
      },
    );
    return _parseVolumeItems(json);
  }

  Future<List<HomeBookModel>> searchBooks(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const <HomeBookModel>[];
    final json = await _api.getJson(
      '/volumes',
      queryParameters: <String, dynamic>{'q': q, 'maxResults': 30},
    );
    final items = json['items'] as List<dynamic>? ?? <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(HomeBookModel.fromGoogleVolume)
        .toList();
  }
}
