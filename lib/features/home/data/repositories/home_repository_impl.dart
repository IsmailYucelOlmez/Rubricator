import '../../domain/entities/home_book_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<List<HomeBookEntity>> getPopularBooks() async {
    final models = await _remoteDataSource.fetchPopularBooks();
    return models.map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<HomeBookEntity>> getBooksByGenre(String genre) async {
    final models = await _remoteDataSource.fetchBooksByGenre(genre);
    return models.map((item) => item.toEntity()).toList();
  }

  @override
  Future<List<HomeBookEntity>> searchBooks(String query) async {
    final models = await _remoteDataSource.searchBooks(query);
    return models.map((item) => item.toEntity()).toList();
  }
}
