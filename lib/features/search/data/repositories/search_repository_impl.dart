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
    final rows = await _remote.fetchSearchHistoryForUser(limit: 50);
    final seen = <String>{};
    final queries = <String>[];
    for (final row in rows) {
      final q = ((row['query'] as String?) ?? '').trim();
      if (q.isEmpty) continue;
      if (!seen.add(q.toLowerCase())) continue;
      queries.add(q);
      if (queries.length >= 6) break;
    }
    return queries;
  }

  @override
  Future<List<Book>> getPopularBooks() async {
    final topIds = await _remote.fetchPopularBookIds(limit: 6);
    if (topIds.isEmpty) return <Book>[];
    final books = await Future.wait<Book?>(
      topIds.map((id) async {
        try {
          return await _bookRepository.getBookByWorkId(id);
        } catch (_) {
          // Some ids intermittently fail on upstream API (e.g. 503).
          // Skip failing ids so other popular books can still be shown.
          return null;
        }
      }),
      eagerError: true,
    );
    return books.whereType<Book>().toList();
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
