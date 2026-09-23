import '../../../books/data/repositories/book_repository.dart';
import '../../../books/domain/entities/book.dart';
import '../../../trbooks/domain/repositories/trbooks_repository.dart';
import '../../domain/entities/home_book_entity.dart';
import '../../domain/entities/home_genre_section.dart';
import '../../domain/entities/home_page_snapshot.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_cache_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/home_book_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(
    this._remoteDataSource,
    this._cacheDataSource,
    this._bookRepository,
    this._trbooksRepository, {
    required this.lang,
  });

  final HomeRemoteDataSource _remoteDataSource;
  final HomeCacheDataSource _cacheDataSource;
  final BookRepository _bookRepository;
  final TrbooksRepository _trbooksRepository;
  final String lang;

  static const int _maxBooksPerHomeSection = 10;
  static const int _maxGoogleBooksFetchSize = 40;
  static const String _fallbackLang = 'en';

  static final RegExp _latinRegex = RegExp(
    r'^[a-zA-Z0-9\s\-\.,:;\x27\x22!?()]+$',
  );

  int _getLanguageScore(HomeBookModel book) {
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

  List<HomeBookModel> _prioritizeModels(List<HomeBookModel> models) {
    if (models.isEmpty) return const <HomeBookModel>[];
    if (models.length == 1) return models;

    final scored = List<_ScoredHomeBookModel>.generate(models.length, (i) {
      final m = models[i];
      return _ScoredHomeBookModel(
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

    final highQuality = scored.where((s) => s.score >= 2).toList();
    final chosen = highQuality.isNotEmpty ? highQuality : scored;
    return chosen.map((s) => s.model).toList();
  }

  /// Genre detail page: cache first, then client fetch when allowed.
  Future<({List<HomeBookModel> models, HomeGenreSectionLoadState sectionState})>
  _loadGenreModels(String genreKey, {required int maxResults}) async {
    final cachedRow = await _cacheDataSource.getGenreCache(
      genreKey,
      lang: lang,
    );
    final cachedBooks = _prioritizeModels(
      _cacheDataSource.parseCachedBooks(cachedRow),
    );
    if (cachedBooks.isNotEmpty) {
      return (
        models: cachedBooks,
        sectionState: HomeGenreSectionLoadState.ready,
      );
    }

    if (!_cacheDataSource.canAttemptFetchToday(cachedRow)) {
      return (
        models: const <HomeBookModel>[],
        sectionState: HomeGenreSectionLoadState.emptyUnavailable,
      );
    }

    return _fetchAndCacheModels(
      genreKey,
      maxResults: maxResults,
      cachedRow: cachedRow,
    );
  }

  Future<({List<HomeBookModel> models, HomeGenreSectionLoadState sectionState})>
  _fetchAndCacheModels(
    String genreKey, {
    required int maxResults,
    GenreCacheSnapshot? cachedRow,
    bool ignoreWeekdaySchedule = false,
  }) async {
    final row =
        cachedRow ?? await _cacheDataSource.getGenreCache(genreKey, lang: lang);
    if (!ignoreWeekdaySchedule && !_cacheDataSource.canAttemptFetchToday(row)) {
      return (
        models: const <HomeBookModel>[],
        sectionState: HomeGenreSectionLoadState.emptyUnavailable,
      );
    }

    Object? lastError;
    for (var i = 0; i < _cacheDataSource.maxRetryAttempts; i++) {
      try {
        final remote = await _remoteDataSource.fetchBooksByGenre(
          genreKey,
          maxResults: maxResults,
        );
        final prioritized = _prioritizeModels(remote);
        if (prioritized.isEmpty) {
          throw StateError('No books returned for genre: $genreKey');
        }
        await _cacheDataSource.saveFetchSuccess(
          genreKey: genreKey,
          lang: lang,
          books: prioritized,
        );
        return (
          models: prioritized,
          sectionState: HomeGenreSectionLoadState.ready,
        );
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      await _cacheDataSource.saveFetchFailure(
        genreKey: genreKey,
        lang: lang,
        error: lastError,
      );
    }
    return (
      models: const <HomeBookModel>[],
      sectionState: HomeGenreSectionLoadState.error,
    );
  }

  List<HomeBookEntity> _homeBooksFromModels(List<HomeBookModel> models) {
    return _prioritizeModels(models)
        .take(_maxBooksPerHomeSection)
        .map((item) => item.toEntity())
        .toList();
  }

  HomeGenreSection _homeSectionFromCacheRow(GenreCacheSnapshot? row) {
    final books = _homeBooksFromModels(
      _cacheDataSource.parseCachedBooks(row),
    );
    if (books.isNotEmpty) {
      return HomeGenreSection(
        books: books,
        loadState: HomeGenreSectionLoadState.ready,
      );
    }
    if (row?.lastFetchStatus == 'error') {
      return const HomeGenreSection(
        books: <HomeBookEntity>[],
        loadState: HomeGenreSectionLoadState.error,
      );
    }
    return const HomeGenreSection(
      books: <HomeBookEntity>[],
      loadState: HomeGenreSectionLoadState.emptyUnavailable,
    );
  }

  /// Reads the home cache for [lang]; genre keys with no (or empty) rows in
  /// that language fall back to [_fallbackLang] so a section is never blank
  /// just because the warm-cache job hasn't produced that language yet.
  Future<Map<String, GenreCacheSnapshot>> _loadHomeCacheWithFallback(
    List<String> cacheKeys,
  ) async {
    final cacheMap = await _cacheDataSource.getGenreCaches(
      cacheKeys,
      lang: lang,
    );
    if (lang == _fallbackLang) return cacheMap;

    final emptyKeys = cacheKeys
        .where((key) => _cacheDataSource.parseCachedBooks(cacheMap[key]).isEmpty)
        .toList();
    if (emptyKeys.isEmpty) return cacheMap;

    final fallbackMap = await _cacheDataSource.getGenreCaches(
      emptyKeys,
      lang: _fallbackLang,
    );
    final merged = <String, GenreCacheSnapshot>{...cacheMap};
    for (final key in emptyKeys) {
      final fallbackRow = fallbackMap[key];
      if (fallbackRow != null &&
          _cacheDataSource.parseCachedBooks(fallbackRow).isNotEmpty) {
        merged[key] = fallbackRow;
      }
    }
    return merged;
  }

  /// Turkish home sections prefer live-scraped `trbooks` rows tagged with
  /// the app's own genre taxonomy (see `search_trbooks_by_genre_key`) over
  /// the Google-Books-based cache; a genre with no scraped rows yet falls
  /// back to the cache row exactly as it did before this existed. English
  /// stays entirely on the cache path.
  Future<List<HomeBookEntity>> _trbooksHomeBooks(String genreKey) async {
    if (lang != 'tr') return const <HomeBookEntity>[];
    try {
      final books = await _trbooksRepository.byGenreKey(genreKey);
      return books.take(_maxBooksPerHomeSection).map(_homeBookFromBook).toList();
    } catch (_) {
      // A trbooks RPC failure must not break the home page; fall back below.
      return const <HomeBookEntity>[];
    }
  }

  HomeBookEntity _homeBookFromBook(Book book) {
    return HomeBookEntity(
      id: book.id,
      title: book.title,
      coverImageUrl: book.coverImageUrl,
      authorNames: book.author,
      description: book.description,
      sourceUrl: book.sourceUrl,
    );
  }

  @override
  Future<HomePageSnapshot> loadHomePage(List<String> genreKeys) async {
    final cacheKeys = <String>[
      HomeCacheDataSource.popularCacheKey,
      ...genreKeys,
    ];

    // Kick off the cache read and every trbooks RPC (popular + each genre)
    // together so they run concurrently instead of one-after-another — with
    // 5-6 network round trips, sequential awaits made the home page load as
    // slow as the sum of all of them instead of the slowest one.
    final cacheMapFuture = _loadHomeCacheWithFallback(cacheKeys);
    final popularTrbooksFuture = _trbooksHomeBooks(
      HomeCacheDataSource.popularCacheKey,
    );
    final genreTrbooksFutures = <String, Future<List<HomeBookEntity>>>{
      for (final genreKey in genreKeys) genreKey: _trbooksHomeBooks(genreKey),
    };

    final cacheMap = await cacheMapFuture;

    var popularBooks = await popularTrbooksFuture;
    if (popularBooks.isEmpty) {
      popularBooks = _homeBooksFromModels(
        _cacheDataSource.parseCachedBooks(
          cacheMap[HomeCacheDataSource.popularCacheKey],
        ),
      );
    }

    final genreSections = <String, HomeGenreSection>{};
    for (final genreKey in genreKeys) {
      final trbooksBooks = await genreTrbooksFutures[genreKey]!;
      genreSections[genreKey] = trbooksBooks.isNotEmpty
          ? HomeGenreSection(
              books: trbooksBooks,
              loadState: HomeGenreSectionLoadState.ready,
            )
          : _homeSectionFromCacheRow(cacheMap[genreKey]);
    }

    return HomePageSnapshot(
      popularBooks: popularBooks,
      genreSections: genreSections,
    );
  }

  @override
  Future<List<HomeBookEntity>> getBooksByGenre(String genre) async {
    try {
      final loaded = await _loadGenreModels(
        genre,
        maxResults: _maxGoogleBooksFetchSize,
      );
      final prioritized = _prioritizeModels(loaded.models);
      return prioritized.map((item) => item.toEntity()).toList();
    } catch (_) {
      // Keep genre page usable even when a request fails intermittently.
      return const <HomeBookEntity>[];
    }
  }

  @override
  Future<List<HomeBookEntity>> searchBooks(String query) async {
    final result = await _bookRepository.searchBooks(query: query, page: 1);
    return result.books
        .map(
          (book) => HomeBookEntity(
            id: book.id,
            title: book.title,
            coverImageUrl: book.coverImageUrl,
            authorNames: book.author,
            description: book.description,
            sourceUrl: book.sourceUrl,
          ),
        )
        .toList();
  }
}

class _ScoredHomeBookModel {
  const _ScoredHomeBookModel({
    required this.model,
    required this.score,
    required this.index,
  });

  final HomeBookModel model;
  final int score;
  final int index;
}
