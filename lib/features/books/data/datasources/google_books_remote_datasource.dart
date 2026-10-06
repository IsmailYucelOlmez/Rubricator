import '../../../../core/i18n/fallback_strings.dart';
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

  /// Below this result count, a search is considered "thin" and eligible for
  /// widening fallbacks (bare-query, langRestrict-less retry).
  static const int _thinResultThreshold = 5;

  int _clampedLimit(int limit) {
    if (limit < 1) return 1;
    return limit > _maxPageSize ? _maxPageSize : limit;
  }

  Map<String, dynamic> _listParams({
    required String q,
    required int maxResults,
    String? orderBy,
    int? startIndex,
    bool restrictLanguage = true,
  }) {
    return <String, dynamic>{
      'q': q,
      ...GoogleBooksUtils.baseListParams(
        lang: lang,
        maxResults: maxResults,
        orderBy: orderBy,
        startIndex: startIndex,
        restrictLanguage: restrictLanguage,
      ),
    };
  }

  /// Fetches one `/volumes` page, returning an empty list on failure instead
  /// of throwing — used for best-effort widening fallbacks that should never
  /// break a search that already has primary results.
  Future<List<BookModel>> _tryFetchRaw({
    required String q,
    required int maxResults,
    int? startIndex,
    bool restrictLanguage = true,
  }) async {
    try {
      final json = await _api.getJsonWithRetry(
        '/volumes',
        queryParameters: _listParams(
          q: q,
          maxResults: maxResults,
          startIndex: startIndex,
          restrictLanguage: restrictLanguage,
        ),
      );
      return _parseItemsRaw(json);
    } catch (_) {
      return <BookModel>[];
    }
  }

  List<BookModel> _parseItemsRaw(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromGoogleBooksVolume)
        .toList();
  }

  List<BookModel> _parseItems(Map<String, dynamic> json, {String? query}) {
    return GoogleBooksUtils.postProcess(_parseItemsRaw(json), query: query);
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

    // Combined title+author input (e.g. "suç ve ceza dostoyevski") can miss
    // both field-restricted queries, and Google Books answers field-only
    // queries with zero items anyway; widen with a bare-query fallback.
    if (merged.length < _thinResultThreshold) {
      final plain = GoogleBooksUtils.buildPlainSearchQuery(query);
      if (plain.isNotEmpty && !queries.contains(plain)) {
        final batch = await _tryFetchRaw(
          q: plain,
          maxResults: safeLimit,
          startIndex: startIndex,
        );
        // Field-only queries come back empty, so this is often the only page.
        if (batch.length >= safeLimit) anyFullPage = true;
        merged.addAll(batch);
      }
    }

    // Turkish language metadata on Google Books is often missing/mistagged;
    // if langRestrict starved the result set, retry unrestricted and let
    // soft language-priority ranking (BookRepository) sort it out.
    if (lang == 'tr' && merged.length < _thinResultThreshold) {
      for (final q in queries) {
        merged.addAll(
          await _tryFetchRaw(
            q: q,
            maxResults: safeLimit,
            startIndex: startIndex,
            restrictLanguage: false,
          ),
        );
      }
    }

    final docs = GoogleBooksUtils.postProcess(merged, query: query);
    return GoogleBooksSearchPage(
      docs: docs,
      numFound: docs.length,
      start: startIndex,
      hasMore: anyFullPage,
    );
  }

  Future<BookModel> fetchVolume(String volumeId) async {
    final id = volumeId.trim();
    if (!GoogleBooksUtils.isFetchableVolumeId(id)) {
      throw StateError('Not a Google Books volume id: $id');
    }
    final json = await _api.getJson('/volumes/$id');
    return BookModel.fromGoogleBooksVolume(json);
  }

  Future<BookModel> fetchVolumeMerged(String volumeId, BookModel seed) async {
    final id = volumeId.trim();
    if (!GoogleBooksUtils.isFetchableVolumeId(id)) return seed;
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
        name: name.isNotEmpty ? name : FallbackStrings.unknownAuthor,
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
    // Google Books answers field-only queries with zero items, so the bare
    // quoted name goes right after the first `inauthor:` try; its hits are
    // narrowed to the author's own books by [GoogleBooksUtils.filterByAuthor].
    final queries = <String>[
      'inauthor:"${variants.first}"',
      '"${variants.first}"',
      'inauthor:${variants.first}',
      for (final name in variants.skip(1)) ...[
        'inauthor:"$name"',
        'inauthor:$name',
      ],
    ];
    List<BookModel> parse(Map<String, dynamic> json) =>
        GoogleBooksUtils.filterByAuthor(_parseItems(json, query: a), variants);

    for (final q in queries) {
      try {
        final json = await _api.getJsonWithRetry(
          '/volumes',
          queryParameters: _listParams(q: q, maxResults: maxResults),
        );
        final results = parse(json);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (_) {
        // Continue with the next variant to reduce flaky empty states.
      }
    }

    // All langRestrict'd variants came up empty — Turkish author metadata is
    // often missing/mistagged, so retry unrestricted as a last resort.
    if (lang == 'tr') {
      for (final q in queries) {
        try {
          final json = await _api.getJsonWithRetry(
            '/volumes',
            queryParameters: _listParams(
              q: q,
              maxResults: maxResults,
              restrictLanguage: false,
            ),
          );
          final results = parse(json);
          if (results.isNotEmpty) {
            return results;
          }
        } catch (_) {
          // Continue with the next variant.
        }
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
    for (final q in GoogleBooksUtils.buildSubjectSearchQueries('fiction')) {
      final json = await _api.getJsonWithRetry(
        '/volumes',
        queryParameters: _listParams(
          q: q,
          maxResults: safeLimit,
          orderBy: 'newest',
        ),
      );
      final results = _parseItems(json);
      if (results.isNotEmpty) return results;
    }
    return <BookModel>[];
  }

  /// Tries [queries] in order until one yields books. Google Books answers a
  /// `q` made only of field operators (`subject:…`, `inauthor:…`) with zero
  /// items, so callers end with a bare-term query;
  /// [GoogleBooksUtils.postProcess] ranks the looser matches back.
  Future<List<BookModel>> _fetchRelated({
    required List<String> queries,
    required String term,
    required String excludeVolumeId,
    required int limit,
    List<String>? authorNames,
  }) async {
    final exclude = excludeVolumeId.trim();
    for (final q in queries) {
      if (q.trim().isEmpty) continue;
      final json = await _api.getJsonWithRetry(
        '/volumes',
        queryParameters: _listParams(
          q: q,
          maxResults: _clampedLimit(limit + 5),
        ),
      );
      var parsed = _parseItems(json, query: term);
      if (authorNames != null) {
        parsed = GoogleBooksUtils.filterByAuthor(parsed, authorNames);
      }
      final out = <BookModel>[];
      for (final m in parsed) {
        if (m.workId == exclude) continue;
        out.add(m);
        if (out.length >= limit) break;
      }
      if (out.isNotEmpty) return out;
    }
    return <BookModel>[];
  }

  Future<List<BookModel>> fetchRelatedBySubject({
    required String subject,
    required String excludeVolumeId,
    int limit = 12,
  }) {
    final queries = GoogleBooksUtils.buildSubjectSearchQueries(subject);
    if (queries.isEmpty) return Future.value(<BookModel>[]);
    final term = subject.trim().replaceAll('"', ' ');
    return _fetchRelated(
      queries: [...queries, term],
      term: subject,
      excludeVolumeId: excludeVolumeId,
      limit: limit,
    );
  }

  Future<List<BookModel>> fetchRelatedByAuthor({
    required String author,
    required String excludeVolumeId,
    int limit = 12,
  }) {
    final q = GoogleBooksUtils.buildAuthorSearchQuery(author);
    if (q.isEmpty) return Future.value(<BookModel>[]);
    final name = author.trim().replaceAll('"', ' ');
    return _fetchRelated(
      queries: [q, '"$name"'],
      term: author,
      authorNames: [name],
      excludeVolumeId: excludeVolumeId,
      limit: limit,
    );
  }
}
