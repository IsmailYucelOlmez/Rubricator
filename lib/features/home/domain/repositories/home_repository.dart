import '../entities/home_book_entity.dart';

abstract class HomeRepository {
  Future<List<HomeBookEntity>> getPopularBooks();
  Future<List<HomeBookEntity>> getBooksByGenre(String genre);

  /// Home genre rows: one Google Books `subject:` query per key (parallel).
  Future<Map<String, List<HomeBookEntity>>> getHomeGenreSectionBooks(
    List<String> genreKeys,
  );

  Future<List<HomeBookEntity>> searchBooks(String query);
}
