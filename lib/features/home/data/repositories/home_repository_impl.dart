import '../../domain/entities/home_book_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/home_book_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  static final RegExp _latinRegex = RegExp(
    r'^[a-zA-Z0-9\s\-\.,:;\x27\x22!?()]+$',
  );

  int _getLanguageScore(HomeBookModel book) {
    final langs = book.languages;
    if (langs != null && (langs.contains('eng') || langs.contains('tur'))) {
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

  @override
  Future<List<HomeBookEntity>> getPopularBooks() async {
    final models = await _remoteDataSource.fetchPopularBooks();
    final prioritized = _prioritizeModels(models);
    return prioritized.map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<HomeBookEntity>> getBooksByGenre(String genre) async {
    final models = await _remoteDataSource.fetchBooksByGenre(genre);
    final prioritized = _prioritizeModels(models);
    return prioritized.map((item) => item.toEntity()).toList();
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
