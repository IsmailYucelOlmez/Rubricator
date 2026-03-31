import '../entities/home_book_entity.dart';

abstract class HomeRepository {
  Future<List<HomeBookEntity>> getPopularBooks();
  Future<List<HomeBookEntity>> getBooksByGenre(String genre);
  Future<List<HomeBookEntity>> searchBooks(String query);
}
