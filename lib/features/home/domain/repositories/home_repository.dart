import '../entities/home_book_entity.dart';
import '../entities/home_page_snapshot.dart';

abstract class HomeRepository {
  /// Emits progressively more complete snapshots as rails load; the last
  /// event is complete for [genreKeys].
  Stream<HomePageSnapshot> watchHomePage(List<String> genreKeys);

  /// Last complete home page saved on this device, if any.
  Future<HomePageSnapshot?> readSavedHomePage();

  Future<void> saveHomePage(HomePageSnapshot snapshot);

  Future<List<HomeBookEntity>> getBooksByGenre(String genre);

  Future<List<HomeBookEntity>> searchBooks(String query);
}
