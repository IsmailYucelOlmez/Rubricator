import '../../../../services/api_service.dart';
import '../models/author_model.dart';
import '../models/book_model.dart';

/// Raw search page from Open Library `/search.json`.
class OpenLibrarySearchPage {
  const OpenLibrarySearchPage({
    required this.docs,
    required this.numFound,
    required this.start,
  });

  final List<BookModel> docs;
  final int numFound;
  final int start;
}

/// Remote calls to Open Library (no domain types).
class OpenLibraryRemoteDataSource {
  OpenLibraryRemoteDataSource(this._api);

  final ApiService _api;

  static const int _defaultLimit = 20;

  Future<OpenLibrarySearchPage> searchBooks({
    required String query,
    int page = 1,
    int limit = _defaultLimit,
  }) async {
    final q = query.trim();
    final safePage = page < 1 ? 1 : page;
    final offset = (safePage - 1) * limit;
    final json = await _api.getJson(
      '/search.json',
      queryParameters: <String, dynamic>{
        'q': q,
        'limit': limit,
        'offset': offset,
      },
    );
    final docsRaw = json['docs'] as List<dynamic>? ?? <dynamic>[];
    final docs = docsRaw
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromSearchDoc)
        .toList();
    final numFound = (json['numFound'] as num?)?.toInt() ?? 0;
    final start = (json['start'] as num?)?.toInt() ?? offset;
    return OpenLibrarySearchPage(docs: docs, numFound: numFound, start: start);
  }

  Future<BookModel> fetchWork(String workId) async {
    final id = workId.trim();
    final json = await _api.getJson('/works/$id.json');
    return BookModel.fromWorkJson(json);
  }

  Future<BookModel> fetchWorkMerged(String workId, BookModel seed) async {
    final json = await _api.getJson('/works/${workId.trim()}.json');
    return BookModel.fromWorkJson(json, mergeFrom: seed);
  }

  Future<AuthorModel> fetchAuthor(String authorId) async {
    final id = authorId.replaceFirst(RegExp(r'^/authors/'), '').trim();
    final json = await _api.getJson('/authors/$id.json');
    return AuthorModel.fromJson(json);
  }

  Future<List<BookModel>> fetchTrendingWorks({int limit = 20}) async {
    final json = await _api.getJson(
      '/subjects/popular.json',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    final works = json['works'] as List<dynamic>? ?? <dynamic>[];
    return works
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromTrendingWork)
        .toList();
  }

  /// Related works via subject search (first subject string).
  Future<List<BookModel>> fetchRelatedBySubject({
    required String subject,
    required String excludeWorkId,
    int limit = 12,
  }) async {
    final s = subject.trim();
    if (s.isEmpty) return <BookModel>[];
    final json = await _api.getJson(
      '/search.json',
      queryParameters: <String, dynamic>{
        'q': 'subject:"$s"',
        'limit': limit + 5,
      },
    );
    final docsRaw = json['docs'] as List<dynamic>? ?? <dynamic>[];
    final exclude = excludeWorkId.trim();
    final out = <BookModel>[];
    for (final row in docsRaw.whereType<Map<String, dynamic>>()) {
      final m = BookModel.fromSearchDoc(row);
      if (m.workId == exclude) continue;
      out.add(m);
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<BookModel>> fetchRelatedByAuthor({
    required String author,
    required String excludeWorkId,
    int limit = 12,
  }) async {
    final a = author.trim();
    if (a.isEmpty) return <BookModel>[];
    final json = await _api.getJson(
      '/search.json',
      queryParameters: <String, dynamic>{'author': a, 'limit': limit + 5},
    );
    final docsRaw = json['docs'] as List<dynamic>? ?? <dynamic>[];
    final exclude = excludeWorkId.trim();
    final out = <BookModel>[];
    for (final row in docsRaw.whereType<Map<String, dynamic>>()) {
      final m = BookModel.fromSearchDoc(row);
      if (m.workId == exclude) continue;
      out.add(m);
      if (out.length >= limit) break;
    }
    return out;
  }
}
