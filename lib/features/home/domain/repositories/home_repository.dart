import '../entities/home_book_entity.dart';
import '../entities/home_genre_section.dart';

abstract class HomeRepository {
  Stream<List<HomeBookEntity>> streamPopularBooks();
  Future<List<HomeBookEntity>> refreshPopularBooks();

  Future<List<HomeBookEntity>> getBooksByGenre(String genre);

  Stream<HomeGenreSection> streamHomeGenreSection(String genreKey);
  Future<HomeGenreSection> refreshHomeGenreSection(String genreKey);

  Future<List<HomeBookEntity>> searchBooks(String query);
}
