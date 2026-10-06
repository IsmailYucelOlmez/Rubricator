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

  /// Queries for [subject] to try in order (see
  /// [GoogleBooksUtils.buildSubjectSearchQueries]), each with the Turkish
  /// genre word of [genreKey] appended on the Turkish app.
  List<String> _genreQueries(String subject, String genreKey) {
    final turkishTerm = turkishGenreQueries[genreKey];
    return [
      for (final q in GoogleBooksUtils.buildSubjectSearchQueries(subject))
        lang == 'tr' && turkishTerm != null ? '$q $turkishTerm' : q,
    ];
  }

  /// Returns the first non-empty result of [queries].
  Future<List<HomeBookModel>> _fetchFirstNonEmpty(
    List<String> queries,
    int maxResults,
  ) async {
    for (final q in queries) {
      final json = await _api.getJsonWithRetry(
        '/volumes',
        queryParameters: _listParams(q: q, maxResults: maxResults),
      );
      final books = _filterByLanguage(_parseVolumeItems(json));
      if (books.isNotEmpty) return books;
    }
    return const <HomeBookModel>[];
  }

  Future<List<HomeBookModel>> fetchBooksByGenre(
    String genre, {
    int maxResults = 30,
  }) async {
    final safeGenre = subjectQueryTerm(genre);
    if (safeGenre.isEmpty) return const <HomeBookModel>[];
    return _fetchFirstNonEmpty(_genreQueries(safeGenre, genre), maxResults);
  }

  Future<List<HomeBookModel>> fetchPopularBooks({int maxResults = 30}) {
    return _fetchFirstNonEmpty(
      _genreQueries('fiction', 'popular_fiction'),
      maxResults,
    );
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
