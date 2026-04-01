import '../../../books/domain/entities/book.dart';
import '../entities/search_log_entity.dart';
import '../repositories/search_repository.dart';

class SearchBooksUseCase {
  const SearchBooksUseCase(this._repository);
  final SearchRepository _repository;

  Future<List<Book>> call(String query) => _repository.searchBooks(query);
}

class LogSearchUseCase {
  const LogSearchUseCase(this._repository);
  final SearchRepository _repository;

  Future<void> call({required String query, String? bookId}) {
    return _repository.logSearch(query: query, bookId: bookId);
  }
}

class GetPopularSearchesUseCase {
  const GetPopularSearchesUseCase(this._repository);
  final SearchRepository _repository;

  Future<List<String>> call() => _repository.getPopularSearches();
}

class GetPopularBooksUseCase {
  const GetPopularBooksUseCase(this._repository);
  final SearchRepository _repository;

  Future<List<Book>> call() => _repository.getPopularBooks();
}

class GetSearchHistoryUseCase {
  const GetSearchHistoryUseCase(this._repository);
  final SearchRepository _repository;

  Future<List<SearchLogEntity>> call({int limit = 20}) {
    return _repository.getSearchHistory(limit: limit);
  }
}
