import '../../../books/data/services/api_service.dart';
import '../../../books/data/utils/google_books_utils.dart';
import '../models/home_book_model.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._api, {this.lang = 'tr'});

  final ApiService _api;
  final String lang;

  /// Google Books' `subject:` taxonomy is effectively English-only, so
  /// `subject:fantasy&langRestrict=tr` still matches the English catalog and
  /// `langRestrict` doesn't meaningfully narrow it — Turkish results end up
  /// identical to English ones. Anding the English subject with the Turkish
  /// genre word as a plain keyword keeps genre precision while biasing
  /// toward actually-Turkish matches; [_filterByLanguage] then double-checks
  /// each result's own language field. A bare Turkish keyword alone (no
  /// `subject:` anchor) matches Google's full-text index too broadly —
  /// generic single words like "roman" or "korku" pull in unrelated
  /// non-fiction and other senses of the word.
  static const Map<String, String> turkishGenreQueries = <String, String>{
    'popular_fiction': 'roman',
    'fantasy': 'fantastik',
    'science_fiction': 'bilim kurgu',
    'romance': 'aşk romanı',
    'mystery': 'polisiye',
    'thriller': 'gerilim',
    'horror': 'korku',
  };

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

  /// Keeps only books whose own `volumeInfo.language` actually matches
  /// [lang] — `langRestrict` alone isn't trustworthy for subject-taxonomy
  /// queries, so this is the real language gate. Falls back to the
  /// unfiltered list only if filtering would empty it out entirely.
  List<HomeBookModel> _filterByLanguage(List<HomeBookModel> models) {
    final relevant = models
        .where((m) => m.languages?.any((l) => l.startsWith(lang)) ?? false)
        .toList();
    return relevant.isNotEmpty ? relevant : models;
  }

  String _genreQuery(String genre) {
    final safeGenre = subjectQueryTerm(genre);
    if (safeGenre.isEmpty) return '';
    final subjectQuery = GoogleBooksUtils.buildSubjectSearchQuery(safeGenre);
    final turkishTerm = turkishGenreQueries[genre];
    if (lang == 'tr' && turkishTerm != null) {
      return '$subjectQuery $turkishTerm';
    }
    return subjectQuery;
  }

  Future<List<HomeBookModel>> fetchBooksByGenre(
    String genre, {
    int maxResults = 30,
  }) async {
    final q = _genreQuery(genre);
    if (q.isEmpty) return const <HomeBookModel>[];
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(q: q, maxResults: maxResults),
    );
    return _filterByLanguage(_parseVolumeItems(json));
  }

  Future<List<HomeBookModel>> fetchPopularBooks({int maxResults = 30}) async {
    final turkishTerm = turkishGenreQueries['popular_fiction'];
    final q = lang == 'tr' && turkishTerm != null
        ? 'subject:fiction $turkishTerm'
        : 'subject:fiction';
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(q: q, maxResults: maxResults),
    );
    return _filterByLanguage(_parseVolumeItems(json));
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
