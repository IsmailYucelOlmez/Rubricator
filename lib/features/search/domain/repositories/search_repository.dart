import '../../../books/domain/entities/book.dart';
import '../entities/search_log_entity.dart';

abstract class SearchRepository {
  Future<List<Book>> searchBooks(String query);

  Future<void> logSearch({required String query, String? bookId});

  Future<List<String>> getPopularSearches();

  Future<List<Book>> getPopularBooks();

  Future<List<SearchLogEntity>> getSearchHistory({int limit = 20});
}
