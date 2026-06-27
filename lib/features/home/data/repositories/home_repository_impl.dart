import '../../../books/data/repositories/book_repository.dart';
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
  );

  final HomeRemoteDataSource _remoteDataSource;
  final HomeCacheDataSource _cacheDataSource;
  final BookRepository _bookRepository;

  static const int _maxBooksPerHomeSection = 10;
  static const int _maxGoogleBooksFetchSize = 40;

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
    final cachedRow = await _cacheDataSource.getGenreCache(genreKey);
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
    final row = cachedRow ?? await _cacheDataSource.getGenreCache(genreKey);
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

  @override
  Future<HomePageSnapshot> loadHomePage(List<String> genreKeys) async {
    final cacheKeys = <String>[
      HomeCacheDataSource.popularCacheKey,
      ...genreKeys,
    ];
    final cacheMap = await _cacheDataSource.getGenreCaches(cacheKeys);

    final popularBooks = _homeBooksFromModels(
      _cacheDataSource.parseCachedBooks(
        cacheMap[HomeCacheDataSource.popularCacheKey],
      ),
    );

    final genreSections = <String, HomeGenreSection>{
      for (final genreKey in genreKeys)
        genreKey: _homeSectionFromCacheRow(cacheMap[genreKey]),
    };

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
