import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/logging/app_logger.dart';
import '../../../books/data/repositories/book_repository.dart';
import '../../../books/domain/entities/book.dart';
import '../../../trbooks/data/repositories/supabase_trbooks_repository.dart';
import '../../../trbooks/domain/repositories/trbooks_repository.dart';
import '../../domain/entities/home_book_entity.dart';
import '../../domain/entities/home_genre_section.dart';
import '../../domain/entities/home_page_snapshot.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_cache_datasource.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/home_book_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(
    this._remoteDataSource,
    this._cacheDataSource,
    this._localDataSource,
    this._bookRepository,
    this._trbooksRepository, {
    required this.lang,
  });

  final HomeRemoteDataSource _remoteDataSource;
  final HomeCacheDataSource _cacheDataSource;
  final HomeLocalDataSource _localDataSource;
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
        await _bestEffortCacheWrite(
          () => _cacheDataSource.saveFetchSuccess(
            genreKey: genreKey,
            lang: lang,
            books: prioritized,
          ),
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
      await _bestEffortCacheWrite(
        () => _cacheDataSource.saveFetchFailure(
          genreKey: genreKey,
          lang: lang,
          error: lastError!,
        ),
      );
    }
    return (
      models: const <HomeBookModel>[],
      sectionState: HomeGenreSectionLoadState.error,
    );
  }

  List<HomeBookEntity> _homeBooksFromModels(List<HomeBookModel> models) {
    return _prioritizeModels(
      models,
    ).take(_maxBooksPerHomeSection).map((item) => item.toEntity()).toList();
  }

  HomeGenreSection _homeSectionFromCacheRow(GenreCacheSnapshot? row) {
    final books = _homeBooksFromModels(_cacheDataSource.parseCachedBooks(row));
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
        .where(
          (key) => _cacheDataSource.parseCachedBooks(cacheMap[key]).isEmpty,
        )
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
      return books
          .take(_maxBooksPerHomeSection)
          .map(_homeBookFromBook)
          .toList();
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
  Future<HomePageSnapshot?> readSavedHomePage() => _localDataSource.read();

  @override
  Future<void> saveHomePage(HomePageSnapshot snapshot) =>
      _localDataSource.write(snapshot);

  @override
  Stream<HomePageSnapshot> watchHomePage(List<String> genreKeys) async* {
    final cacheKeys = <String>[
      HomeCacheDataSource.popularCacheKey,
      ...genreKeys,
    ];

    final Map<String, HomePageBundleEntry> bundle;
    try {
      bundle = await _timed(
        'get_home_page rpc',
        _cacheDataSource.getHomePageBundle(
          cacheKeys,
          lang: lang,
          limit: _maxBooksPerHomeSection,
        ),
      );
    } on PostgrestException catch (error) {
      // PGRST202: function not deployed yet — keep the page working through
      // the per-section requests until the migration is applied.
      if (error.code != 'PGRST202') rethrow;
      AppLogger.warning(
        'home',
        'get_home_page RPC missing, falling back to per-section requests',
      );
      yield* _watchHomePageLegacy(genreKeys);
      return;
    }
    yield _snapshotFromBundle(bundle, genreKeys);
  }

  HomePageSnapshot _snapshotFromBundle(
    Map<String, HomePageBundleEntry> bundle,
    List<String> genreKeys,
  ) {
    List<HomeBookEntity> trbooksOf(String key) =>
        (bundle[key]?.trbooksRows ?? const <Map<String, dynamic>>[])
            .map(SupabaseTrbooksRepository.mapRowToBook)
            .take(_maxBooksPerHomeSection)
            .map(_homeBookFromBook)
            .toList();

    const popularKey = HomeCacheDataSource.popularCacheKey;
    var popularBooks = trbooksOf(popularKey);
    if (popularBooks.isEmpty) {
      popularBooks = _homeBooksFromModels(
        _cacheDataSource.parseCachedBooks(bundle[popularKey]?.cacheRow),
      );
    }

    final genreSections = <String, HomeGenreSection>{};
    for (final genreKey in genreKeys) {
      final trbooksBooks = trbooksOf(genreKey);
      genreSections[genreKey] = trbooksBooks.isNotEmpty
          ? HomeGenreSection(
              books: trbooksBooks,
              loadState: HomeGenreSectionLoadState.ready,
            )
          : _homeSectionFromCacheRow(bundle[genreKey]?.cacheRow);
    }

    return HomePageSnapshot(
      popularBooks: popularBooks,
      genreSections: genreSections,
    );
  }

  /// Pre-`get_home_page` path: one cache read plus one trbooks RPC per rail,
  /// all started together. Emits after every rail that resolves so a slow
  /// request only holds back its own rail instead of the whole page.
  Stream<HomePageSnapshot> _watchHomePageLegacy(List<String> genreKeys) async* {
    final cacheKeys = <String>[
      HomeCacheDataSource.popularCacheKey,
      ...genreKeys,
    ];

    final cacheMapFuture = _timed(
      'genre_books_cache read',
      _loadHomeCacheWithFallback(cacheKeys),
    );
    // Rails whose trbooks list is non-empty never await the cache read; keep
    // its failure from surfacing as an unhandled async error.
    unawaited(cacheMapFuture.then((_) {}, onError: (Object _) {}));

    Future<_HomeRail> popularRail() async {
      const key = HomeCacheDataSource.popularCacheKey;
      final trbooks = await _timed('trbooks $key', _trbooksHomeBooks(key));
      if (trbooks.isNotEmpty) return _HomeRail.popular(trbooks);
      final cacheMap = await cacheMapFuture;
      return _HomeRail.popular(
        _homeBooksFromModels(_cacheDataSource.parseCachedBooks(cacheMap[key])),
      );
    }

    Future<_HomeRail> genreRail(String genreKey) async {
      final trbooks = await _timed(
        'trbooks $genreKey',
        _trbooksHomeBooks(genreKey),
      );
      if (trbooks.isNotEmpty) {
        return _HomeRail.genre(
          genreKey,
          HomeGenreSection(
            books: trbooks,
            loadState: HomeGenreSectionLoadState.ready,
          ),
        );
      }
      final cacheMap = await cacheMapFuture;
      return _HomeRail.genre(
        genreKey,
        _homeSectionFromCacheRow(cacheMap[genreKey]),
      );
    }

    var current = HomePageSnapshot.empty;
    await for (final rail in Stream<_HomeRail>.fromFutures(<Future<_HomeRail>>[
      popularRail(),
      for (final genreKey in genreKeys) genreRail(genreKey),
    ])) {
      current = HomePageSnapshot(
        popularBooks: rail.popularBooks ?? current.popularBooks,
        genreSections: <String, HomeGenreSection>{
          ...current.genreSections,
          if (rail.genreKey != null) rail.genreKey!: rail.section!,
        },
      );
      yield current;
    }
  }

  Future<T> _timed<T>(String label, Future<T> future) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await future;
    } finally {
      AppLogger.info(
        'home.timing',
        '$label: ${stopwatch.elapsedMilliseconds}ms',
      );
    }
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

  /// The genre cache is an optimisation: a rejected or failed write (RLS on the
  /// cache table, offline, ...) must not turn a successful fetch into a failed
  /// section, nor trigger the retry loop. Server-side, writes to this table are
  /// being moved to the service role (supabase/deferred/cache_write_lockdown.sql).
  Future<void> _bestEffortCacheWrite(Future<void> Function() write) async {
    try {
      await write();
    } catch (error) {
      AppLogger.warning(
        'home',
        'Genre cache write skipped',
        data: {'error': error.toString()},
      );
    }
  }
}

class _HomeRail {
  const _HomeRail.popular(List<HomeBookEntity> books)
    : popularBooks = books,
      genreKey = null,
      section = null;

  const _HomeRail.genre(String this.genreKey, HomeGenreSection this.section)
    : popularBooks = null;

  final List<HomeBookEntity>? popularBooks;
  final String? genreKey;
  final HomeGenreSection? section;
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
