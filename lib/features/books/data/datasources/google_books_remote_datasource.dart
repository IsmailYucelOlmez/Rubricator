import '../../../../services/api_service.dart';
import '../models/author_model.dart';
import '../models/book_model.dart';

/// Raw search page from Google Books `/volumes`.
class GoogleBooksSearchPage {
  const GoogleBooksSearchPage({
    required this.docs,
    required this.numFound,
    required this.start,
  });

  final List<BookModel> docs;
  final int numFound;
  final int start;
}

/// Remote calls to Google Books API (no domain types).
class GoogleBooksRemoteDataSource {
  GoogleBooksRemoteDataSource(this._api);

  final ApiService _api;

  static const int _defaultLimit = 20;
  static const int _maxPageSize = 40;

  int _clampedLimit(int limit) {
    if (limit < 1) return 1;
    return limit > _maxPageSize ? _maxPageSize : limit;
  }

  Future<GoogleBooksSearchPage> searchBooks({
    required String query,
    int page = 1,
    int limit = _defaultLimit,
  }) async {
    final q = query.trim();
    final safePage = page < 1 ? 1 : page;
    final safeLimit = _clampedLimit(limit);
    final startIndex = (safePage - 1) * safeLimit;
    final json = await _api.getJson(
      '/volumes',
      queryParameters: <String, dynamic>{
        'q': q,
        'startIndex': startIndex,
        'maxResults': safeLimit,
      },
    );
    final itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
    final docs = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromGoogleBooksVolume)
        .toList();
    final numFound = (json['totalItems'] as num?)?.toInt() ?? 0;
    return GoogleBooksSearchPage(
      docs: docs,
      numFound: numFound,
      start: startIndex,
    );
  }

  Future<BookModel> fetchVolume(String volumeId) async {
    final id = volumeId.trim();
    final json = await _api.getJson('/volumes/$id');
    return BookModel.fromGoogleBooksVolume(json);
  }

  Future<BookModel> fetchVolumeMerged(String volumeId, BookModel seed) async {
    final json = await _api.getJson('/volumes/${volumeId.trim()}');
    return BookModel.fromGoogleBooksVolume(json, mergeFrom: seed);
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
        name,
      ],
    ];

    for (final q in queries) {
      final json = await _api.getJson(
        '/volumes',
        queryParameters: <String, dynamic>{
          'q': q,
          'maxResults': maxResults,
        },
      );
      final itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
      final results = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map(BookModel.fromGoogleBooksVolume)
          .toList();
      if (results.isNotEmpty) {
        return results;
      }
    }

    return <BookModel>[];
  }

  List<String> _authorSearchVariants(String input) {
    final base = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (base.isEmpty) return const <String>[];

    final variants = <String>[base];

    // Some sources may provide "Last, First" names.
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
    final json = await _api.getJson(
      '/volumes',
      queryParameters: <String, dynamic>{
        'q': 'subject:fiction',
        'orderBy': 'newest',
        'maxResults': safeLimit,
      },
    );
    final itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromGoogleBooksVolume)
        .toList();
  }

  Future<List<BookModel>> fetchRelatedBySubject({
    required String subject,
    required String excludeVolumeId,
    int limit = 12,
  }) async {
    final s = subject.trim().replaceAll('"', ' ');
    if (s.isEmpty) return <BookModel>[];
    final json = await _api.getJson(
      '/volumes',
      queryParameters: <String, dynamic>{
        'q': 'subject:"$s"',
        'maxResults': _clampedLimit(limit + 5),
      },
    );
    final itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
    final exclude = excludeVolumeId.trim();
    final out = <BookModel>[];
    for (final row in itemsRaw.whereType<Map<String, dynamic>>()) {
      final m = BookModel.fromGoogleBooksVolume(row);
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
    final a = author.trim().replaceAll('"', ' ');
    if (a.isEmpty) return <BookModel>[];
    final json = await _api.getJson(
      '/volumes',
      queryParameters: <String, dynamic>{
        'q': 'inauthor:"$a"',
        'maxResults': _clampedLimit(limit + 5),
      },
    );
    final itemsRaw = json['items'] as List<dynamic>? ?? <dynamic>[];
    final exclude = excludeVolumeId.trim();
    final out = <BookModel>[];
    for (final row in itemsRaw.whereType<Map<String, dynamic>>()) {
      final m = BookModel.fromGoogleBooksVolume(row);
      if (m.workId == exclude) continue;
      out.add(m);
      if (out.length >= limit) break;
    }
    return out;
  }
}
