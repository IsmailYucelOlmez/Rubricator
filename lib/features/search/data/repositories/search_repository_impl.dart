import '../../../books/data/repositories/book_repository.dart';
import '../../../books/domain/entities/book.dart';
import '../../domain/entities/search_log_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._bookRepository, this._remote);

  final BookRepository _bookRepository;
  final SearchRemoteDataSource _remote;

  @override
  Future<List<Book>> searchBooks(String query) async {
    final result = await _bookRepository.searchBooks(query: query, page: 1);
    return result.books;
  }

  @override
  Future<void> logSearch({required String query, String? bookId}) {
    return _remote.logSearch(query: query, bookId: bookId);
  }

  @override
  Future<List<String>> getPopularSearches() async {
    return _remote.fetchPopularQueries(limit: 10);
  }

  @override
  Future<List<Book>> getPopularBooks() async {
    final topIds = await _remote.fetchPopularBookIds(limit: 10);
    if (topIds.isEmpty) return <Book>[];
    final books = await Future.wait(
      topIds.map(_bookRepository.getBookByWorkId),
      eagerError: false,
    );
    return books;
  }

  @override
  Future<List<SearchLogEntity>> getSearchHistory({int limit = 20}) async {
    final rows = await _remote.fetchSearchHistoryForUser(limit: limit);
    return rows.map((row) {
      return SearchLogEntity(
        id: (row['id'] as String?) ?? '',
        userId: row['user_id'] as String?,
        query: (row['query'] as String?) ?? '',
        bookId: row['book_id'] as String?,
        createdAt:
            DateTime.tryParse((row['created_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }
}
