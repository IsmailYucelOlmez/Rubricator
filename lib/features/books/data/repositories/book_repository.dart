import '../datasources/google_books_cache_datasource.dart';
import '../datasources/google_books_remote_datasource.dart';
import '../services/api_service.dart';
import '../utils/google_books_utils.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../models/book_model.dart';

class BookRepository {
  BookRepository(
    ApiService api, {
    required GoogleBooksCacheDataSource cache,
    String preferredLanguageCode = 'en',
  }) : _cache = cache,
       _preferredLanguageCode = preferredLanguageCode,
       _ds = GoogleBooksRemoteDataSource(
         api,
         lang: preferredLanguageCode,
       );

  final GoogleBooksRemoteDataSource _ds;
  final GoogleBooksCacheDataSource _cache;
  final String _preferredLanguageCode;

  static const int _searchPageSize = 20;

  static final RegExp _latinRegex = RegExp(
    r'^[a-zA-Z0-9\s\-\.,:;\x27\x22!?()]+$',
  );

  int _getLanguageScore(BookModel book) {
    final langs = book.languages;
    if (langs != null) {
      final preferred = _preferredLanguageCode.toLowerCase();
      final preferredCodes = preferred == 'tr'
          ? const {'tur', 'tr'}
          : const {'eng', 'en'};
      final secondaryCodes = preferred == 'tr'
          ? const {'eng', 'en'}
          : const {'tur', 'tr'};

      if (langs.any(preferredCodes.contains)) return 4;
      if (langs.any(secondaryCodes.contains)) return 3;
    }

    final title = book.title.trim();
    if (title.isNotEmpty && _latinRegex.hasMatch(title)) {
      return 2;
    }

    return 1;
  }

  List<BookModel> _prioritizeModels(List<BookModel> models) {
    if (models.isEmpty) return const <BookModel>[];
    if (models.length == 1) return models;

    final scored = List<_ScoredBookModel>.generate(models.length, (i) {
      final m = models[i];
      return _ScoredBookModel(
        model: m,
        score: _getLanguageScore(m),
        index: i,
      );
    });

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.index.compareTo(b.index);
    });

    final highQuality = scored.where((s) => s.score >= 3).toList();
    final chosen = highQuality.isNotEmpty ? highQuality : scored;
    return chosen.map((s) => s.model).toList();
  }

  Future<List<Book>> trendingBooks() async {
    final models = await _ds.fetchTrendingWorks();
    final prioritized = _prioritizeModels(models);
    return prioritized.map((m) => m.toEntity()).toList();
  }

  /// Paginated search (`page` is 1-based). Empty [query] returns no results.
  Future<BookSearchPageResult> searchBooks({
    required String query,
    int page = 1,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const BookSearchPageResult(
        books: [],
        hasMore: false,
        totalFound: 0,
      );
    }

    final cacheKey = GoogleBooksUtils.searchCacheKey(
      query: trimmed,
      lang: _preferredLanguageCode,
      page: page,
      limit: _searchPageSize,
    );
    final cached = await _cache.getCachedBooks(cacheKey);
    if (cached != null) {
      final books = _prioritizeModels(cached).map((m) => m.toEntity()).toList();
      return BookSearchPageResult(
        books: books,
        hasMore: books.length >= _searchPageSize,
        totalFound: books.length,
      );
    }

    final raw = await _ds.searchBooks(
      query: trimmed,
      page: page,
      limit: _searchPageSize,
    );
    final prioritized = _prioritizeModels(raw.docs);
    if (prioritized.isNotEmpty) {
      await _cache.saveBooks(
        cacheKey: cacheKey,
        cacheType: 'search',
        books: prioritized,
      );
    }
    final books = prioritized.map((m) => m.toEntity()).toList();
    final hasMore = raw.hasMore || raw.docs.length >= _searchPageSize;
    return BookSearchPageResult(
      books: books,
      hasMore: hasMore,
      totalFound: books.length,
    );
  }

  Future<Book> getBookByWorkId(String workId) async {
    final model = await _ds.fetchVolume(workId.trim());
    return model.toEntity();
  }

  Future<Book> getBookDetail(Book book) async {
    final seed = BookModel.fromEntity(book);
    final model = await _ds.fetchVolumeMerged(book.id, seed);
    return model.toEntity();
  }

  Future<Author> getAuthor(String authorId) async {
    final model = await _ds.fetchAuthor(authorId);
    return model.toEntity();
  }

  Future<List<Book>> getBooksByAuthorId(String authorId) async {
    final authorName = _authorNameFromId(authorId);
    if (authorName.isEmpty) return const <Book>[];
    return getBooksByAuthorName(authorName);
  }

  Future<List<Book>> getBooksByAuthorName(String authorName) async {
    final normalizedAuthorName = authorName.trim();
    if (normalizedAuthorName.isEmpty) return const <Book>[];

    const limit = 20;
    final cacheKey = GoogleBooksUtils.authorCacheKey(
      authorName: normalizedAuthorName,
      lang: _preferredLanguageCode,
      limit: limit,
    );
    final cached = await _cache.getCachedBooks(cacheKey);
    if (cached != null) {
      return _prioritizeModels(cached).map((m) => m.toEntity()).toList();
    }

    final models = await _ds.fetchBooksByAuthor(
      author: normalizedAuthorName,
      limit: limit,
    );
    final prioritized = _prioritizeModels(models);
    if (prioritized.isNotEmpty) {
      await _cache.saveBooks(
        cacheKey: cacheKey,
        cacheType: 'author',
        books: prioritized,
      );
    }
    return prioritized.map((m) => m.toEntity()).toList();
  }

  String _authorNameFromId(String authorId) {
    final raw = authorId.trim();
    if (raw.startsWith('g:')) {
      try {
        return Uri.decodeComponent(raw.substring(2)).trim();
      } catch (_) {
        return raw.substring(2).trim();
      }
    }
    return raw;
  }

  Future<List<Book>> getRelatedBooks(Book book) async {
    List<BookModel> models = const <BookModel>[];
    final subject = book.subjectKeys.isNotEmpty ? book.subjectKeys.first : '';
    if (subject.isNotEmpty) {
      models = await _ds.fetchRelatedBySubject(
        subject: subject,
        excludeVolumeId: book.id,
      );
    }
    if (models.isEmpty && book.author.trim().isNotEmpty) {
      models = await _ds.fetchRelatedByAuthor(
        author: book.author,
        excludeVolumeId: book.id,
      );
    }
    final prioritized = _prioritizeModels(models);
    return prioritized.map((m) => m.toEntity()).toList();
  }
}

class _ScoredBookModel {
  const _ScoredBookModel({
    required this.model,
    required this.score,
    required this.index,
  });

  final BookModel model;
  final int score;
  final int index;
}

class BookSearchPageResult {
  const BookSearchPageResult({
    required this.books,
    required this.hasMore,
    required this.totalFound,
  });

  final List<Book> books;
  final bool hasMore;
  final int totalFound;
}
