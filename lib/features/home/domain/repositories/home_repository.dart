import '../entities/home_book_entity.dart';
import '../entities/home_page_snapshot.dart';

abstract class HomeRepository {
  Future<HomePageSnapshot> loadHomePage(List<String> genreKeys);

  Future<List<HomeBookEntity>> getBooksByGenre(String genre);

  Future<List<HomeBookEntity>> searchBooks(String query);
}
