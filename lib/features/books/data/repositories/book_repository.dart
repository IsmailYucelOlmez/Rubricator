import '../../../../services/api_service.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../datasources/google_books_remote_datasource.dart';
import '../models/book_model.dart';

class BookRepository {
  BookRepository(ApiService api) : _ds = GoogleBooksRemoteDataSource(api);

  final GoogleBooksRemoteDataSource _ds;

  /// In-memory cache for [getBooksByAuthorId] to avoid repeat API calls when
  /// revisiting an author or when the UI rebuilds with the same logical author.
  final Map<String, _AuthorBooksCacheEntry> _authorBooksCache =
      <String, _AuthorBooksCacheEntry>{};

  static const Duration _authorBooksCacheTtl = Duration(days: 7);

  static final RegExp _latinRegex = RegExp(
    r'^[a-zA-Z0-9\s\-\.,:;\x27\x22!?()]+$',
  );

  int _getLanguageScore(BookModel book) {
    final langs = book.languages;
    if (langs != null &&
        (langs.contains('eng') ||
            langs.contains('en') ||
            langs.contains('tur') ||
            langs.contains('tr'))) {
      return 3;
    }

    final title = book.title.trim();
    if (title.isNotEmpty && _latinRegex.hasMatch(title)) {
      return 2;
    }

    return 1;
  }

  /// Sort + (optional) filter based on [xdocs/bookapiopt.md].
  ///
  /// - Score >= 2 items are preferred when present.
  /// - If nothing matches >= 2, we fall back to the full sorted list.
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
      // Keep original order for ties.
      return a.index.compareTo(b.index);
    });

    final highQuality = scored.where((s) => s.score >= 2).toList();
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
    final raw = await _ds.searchBooks(query: trimmed, page: page);
    final prioritized = _prioritizeModels(raw.docs);
    final books = prioritized.map((m) => m.toEntity()).toList();
    final end = raw.start + raw.docs.length;
    final hasMore = end < raw.numFound && raw.docs.isNotEmpty;
    return BookSearchPageResult(
      books: books,
      hasMore: hasMore,
      totalFound: raw.numFound,
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

    final cacheKey = _authorBooksCacheKey(normalizedAuthorName);
    final cached = _authorBooksCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _authorBooksCacheTtl) {
      return List<Book>.from(cached.books);
    }

    final models = await _ds.fetchBooksByAuthor(author: normalizedAuthorName);
    final prioritized = _prioritizeModels(models);
    final books = prioritized.map((m) => m.toEntity()).toList();
    // Avoid caching empty states so temporary API misses can recover on retry.
    if (books.isNotEmpty) {
      _authorBooksCache[cacheKey] = _AuthorBooksCacheEntry(
        books: books,
        fetchedAt: DateTime.now(),
      );
    }
    return List<Book>.from(books);
  }

  String _authorBooksCacheKey(String authorName) =>
      authorName.toLowerCase().trim();

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

class _AuthorBooksCacheEntry {
  const _AuthorBooksCacheEntry({
    required this.books,
    required this.fetchedAt,
  });

  final List<Book> books;
  final DateTime fetchedAt;
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
