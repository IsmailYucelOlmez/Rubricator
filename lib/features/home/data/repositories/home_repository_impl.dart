import '../../domain/entities/home_book_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_cache_datasource.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/home_book_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource, this._cacheDataSource);

  final HomeRemoteDataSource _remoteDataSource;
  final HomeCacheDataSource _cacheDataSource;

  static const int _maxBooksPerHomeSection = 10;
  static const int _maxGoogleBooksFetchSize = 40;
  static const String _popularGenreCacheKey = 'popular_fiction';

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

  Future<List<HomeBookModel>> _getOrRefreshGenreBooks(String genreKey) async {
    final cachedRow = await _cacheDataSource.getGenreCache(genreKey);
    final cachedBooks = _prioritizeModels(
      _cacheDataSource.parseCachedBooks(cachedRow),
    );
    if (cachedBooks.isNotEmpty) return cachedBooks;

    if (!_cacheDataSource.canAttemptFetchToday(cachedRow)) {
      return cachedBooks;
    }

    Object? lastError;
    for (var i = 0; i < _cacheDataSource.maxRetryAttempts; i++) {
      try {
        final remote = await _remoteDataSource.fetchBooksByGenre(
          genreKey,
          maxResults: _maxGoogleBooksFetchSize,
        );
        final prioritized = _prioritizeModels(remote);
        if (prioritized.isEmpty) {
          throw StateError('No books returned for genre: $genreKey');
        }
        await _cacheDataSource.saveFetchSuccess(
          genreKey: genreKey,
          books: prioritized,
        );
        return prioritized;
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
    return cachedBooks;
  }

  Future<List<HomeBookModel>> _getOrRefreshPopularBooks() async {
    final cachedRow = await _cacheDataSource.getGenreCache(
      _popularGenreCacheKey,
    );
    final cachedBooks = _prioritizeModels(
      _cacheDataSource.parseCachedBooks(cachedRow),
    );
    if (cachedBooks.isNotEmpty) return cachedBooks;

    if (!_cacheDataSource.canAttemptFetchToday(cachedRow)) {
      return cachedBooks;
    }

    Object? lastError;
    for (var i = 0; i < _cacheDataSource.maxRetryAttempts; i++) {
      try {
        final remote = await _remoteDataSource.fetchPopularBooks(
          maxResults: _maxGoogleBooksFetchSize,
        );
        final prioritized = _prioritizeModels(remote);
        if (prioritized.isEmpty) {
          throw StateError('No popular books returned');
        }
        await _cacheDataSource.saveFetchSuccess(
          genreKey: _popularGenreCacheKey,
          books: prioritized,
        );
        return prioritized;
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      await _cacheDataSource.saveFetchFailure(
        genreKey: _popularGenreCacheKey,
        error: lastError,
      );
    }
    return cachedBooks;
  }

  @override
  Future<List<HomeBookEntity>> getPopularBooks() async {
    final models = await _getOrRefreshPopularBooks();
    final prioritized = _prioritizeModels(models);
    return prioritized
        .take(_maxBooksPerHomeSection)
        .map((item) => item.toEntity())
        .toList();
  }

  @override
  Future<List<HomeBookEntity>> getBooksByGenre(String genre) async {
    try {
      final models = await _getOrRefreshGenreBooks(genre);
      final prioritized = _prioritizeModels(models);
      return prioritized.map((item) => item.toEntity()).toList();
    } catch (_) {
      // Keep genre page usable even when a request fails intermittently.
      return const <HomeBookEntity>[];
    }
  }

  @override
  Future<Map<String, List<HomeBookEntity>>> getHomeGenreSectionBooks(
    List<String> genreKeys,
  ) async {
    if (genreKeys.isEmpty) return <String, List<HomeBookEntity>>{};

    // One `subject:` query per row — Google often omits `volumeInfo.categories`,
    // so splitting a single combined result by category leaves rows empty.
    final entries = await Future.wait(
      genreKeys.map((g) async {
        try {
          final models = await _getOrRefreshGenreBooks(g);
          final prioritized = _prioritizeModels(models);
          return MapEntry(
            g,
            prioritized
                .take(_maxBooksPerHomeSection)
                .map((m) => m.toEntity())
                .toList(),
          );
        } catch (_) {
          // Isolate partial API failures so one genre does not break all rows.
          return MapEntry(g, const <HomeBookEntity>[]);
        }
      }),
    );

    return Map<String, List<HomeBookEntity>>.fromEntries(entries);
  }

  @override
  Future<List<HomeBookEntity>> searchBooks(String query) async {
    final models = await _remoteDataSource.searchBooks(query);
    final prioritized = _prioritizeModels(models);
    return prioritized.map((item) => item.toEntity()).toList();
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
