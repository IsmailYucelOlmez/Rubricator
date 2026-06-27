import '../models/author_model.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../utils/google_books_utils.dart';

/// Raw search page from Google Books `/volumes`.
class GoogleBooksSearchPage {
  const GoogleBooksSearchPage({
    required this.docs,
    required this.numFound,
    required this.start,
    this.hasMore = false,
  });

  final List<BookModel> docs;
  final int numFound;
  final int start;
  final bool hasMore;
}

/// Remote calls to Google Books API (no domain types).
class GoogleBooksRemoteDataSource {
  GoogleBooksRemoteDataSource(this._api, {this.lang = 'tr'});

  final ApiService _api;
  final String lang;

  static const int _defaultLimit = 20;
  static const int _maxPageSize = 40;

  int _clampedLimit(int limit) {
    if (limit < 1) return 1;
    return limit > _maxPageSize ? _maxPageSize : limit;
  }

  Map<String, dynamic> _listParams({
    required String q,
    required int maxResults,
    String? orderBy,
    int? startIndex,
  }) {
    return <String, dynamic>{
      'q': q,
      ...GoogleBooksUtils.baseListParams(
        lang: lang,
        maxResults: maxResults,
        orderBy: orderBy,
        startIndex: startIndex,
      ),
    };
  }

  List<BookModel> _parseItemsRaw(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromGoogleBooksVolume)
        .toList();
  }

  List<BookModel> _parseItems(Map<String, dynamic> json) {
    return GoogleBooksUtils.postProcess(_parseItemsRaw(json));
  }

  Future<GoogleBooksSearchPage> searchBooks({
    required String query,
    int page = 1,
    int limit = _defaultLimit,
  }) async {
    final queries = GoogleBooksUtils.buildUnifiedSearchQueries(query);
    if (queries.isEmpty) {
      return const GoogleBooksSearchPage(docs: [], numFound: 0, start: 0);
    }
    final safePage = page < 1 ? 1 : page;
    final safeLimit = _clampedLimit(limit);
    final startIndex = (safePage - 1) * safeLimit;

    final responses = await Future.wait<Map<String, dynamic>>(
      queries.map(
        (q) => _api.getJsonWithRetry(
          '/volumes',
          queryParameters: _listParams(
            q: q,
            maxResults: safeLimit,
            startIndex: startIndex,
          ),
        ),
      ),
    );

    final merged = <BookModel>[];
    var anyFullPage = false;
    for (final json in responses) {
      final batch = _parseItemsRaw(json);
      if (batch.length >= safeLimit) anyFullPage = true;
      merged.addAll(batch);
    }

    final docs = GoogleBooksUtils.postProcess(merged);
    return GoogleBooksSearchPage(
      docs: docs,
      numFound: docs.length,
      start: startIndex,
      hasMore: anyFullPage,
    );
  }

  Future<BookModel> fetchVolume(String volumeId) async {
    final id = volumeId.trim();
    final json = await _api.getJson('/volumes/$id');
    return BookModel.fromGoogleBooksVolume(json);
  }

  Future<BookModel> fetchVolumeMerged(String volumeId, BookModel seed) async {
    final id = volumeId.trim();
    if (id.isEmpty) return seed;
    try {
      final json = await _api.getJson('/volumes/$id');
      return BookModel.fromGoogleBooksVolume(json, mergeFrom: seed);
    } catch (_) {
      return seed;
    }
  }

  /// Google Books has no author entity; [authorId] uses `g:` + URI-encoded name.
  Future<AuthorModel> fetchAuthor(String authorId) async {
    final raw = authorId.trim();
    if (raw.startsWith('g:')) {
      final name = Uri.decodeComponent(raw.substring(2));
      return AuthorModel(
        id: raw,
        name: name.isNotEmpty ? name : 'Unknown author',
        bio: '',
        birthDate: null,
        deathDate: null,
      );
    }
    return AuthorModel(
      id: raw,
      name: raw,
      bio: '',
      birthDate: null,
      deathDate: null,
    );
  }

  Future<List<BookModel>> fetchBooksByAuthor({
    required String author,
    int limit = 20,
  }) async {
    final a = author.trim().replaceAll('"', ' ');
    if (a.isEmpty) return <BookModel>[];

    final maxResults = _clampedLimit(limit);
    final variants = _authorSearchVariants(a);
    final queries = <String>[
      for (final name in variants) ...[
        'inauthor:"$name"',
        'inauthor:$name',
      ],
    ];

    for (final q in queries) {
      try {
        final json = await _api.getJsonWithRetry(
          '/volumes',
          queryParameters: _listParams(q: q, maxResults: maxResults),
        );
        final results = _parseItems(json);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (_) {
        // Continue with the next variant to reduce flaky empty states.
      }
    }

    return <BookModel>[];
  }

  List<String> _authorSearchVariants(String input) {
    final base = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (base.isEmpty) return const <String>[];

    final variants = <String>[base];

    if (base.contains(',')) {
      final parts = base
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        variants.add('${parts.sublist(1).join(' ')} ${parts.first}'.trim());
      }
    }

    final noDots = base.replaceAll('.', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (noDots.isNotEmpty) variants.add(noDots);

    final words = noDots.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      variants.add('${words.first} ${words.last}');
      variants.add(words.last);
    }

    final seen = <String>{};
    return variants.where((v) => seen.add(v.toLowerCase())).toList();
  }

  Future<List<BookModel>> fetchTrendingWorks({int limit = 20}) async {
    final safeLimit = _clampedLimit(limit);
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(
        q: 'subject:fiction',
        maxResults: safeLimit,
        orderBy: 'newest',
      ),
    );
    return _parseItems(json);
  }

  Future<List<BookModel>> fetchRelatedBySubject({
    required String subject,
    required String excludeVolumeId,
    int limit = 12,
  }) async {
    final q = GoogleBooksUtils.buildSubjectSearchQuery(subject);
    if (q.isEmpty) return <BookModel>[];
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(
        q: q,
        maxResults: _clampedLimit(limit + 5),
      ),
    );
    final exclude = excludeVolumeId.trim();
    final out = <BookModel>[];
    for (final m in _parseItems(json)) {
      if (m.workId == exclude) continue;
      out.add(m);
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<BookModel>> fetchRelatedByAuthor({
    required String author,
    required String excludeVolumeId,
    int limit = 12,
  }) async {
    final q = GoogleBooksUtils.buildAuthorSearchQuery(author);
    if (q.isEmpty) return <BookModel>[];
    final json = await _api.getJsonWithRetry(
      '/volumes',
      queryParameters: _listParams(
        q: q,
        maxResults: _clampedLimit(limit + 5),
      ),
    );
    final exclude = excludeVolumeId.trim();
    final out = <BookModel>[];
    for (final m in _parseItems(json)) {
      if (m.workId == exclude) continue;
      out.add(m);
      if (out.length >= limit) break;
    }
    return out;
  }
}
