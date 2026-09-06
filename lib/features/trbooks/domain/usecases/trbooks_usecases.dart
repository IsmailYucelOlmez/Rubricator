import '../../../books/data/repositories/book_repository.dart';
import '../../../books/domain/entities/book.dart';
import '../repositories/trbooks_repository.dart';

class SearchTrbooksUseCase {
  const SearchTrbooksUseCase(this._repository);
  final TrbooksRepository _repository;

  Future<List<Book>> call(String query, {int limit = 20}) {
    return _repository.searchTrbooks(query, limit: limit);
  }
}

class PopularTrbooksUseCase {
  const PopularTrbooksUseCase(this._repository);
  final TrbooksRepository _repository;

  Future<List<Book>> call({int limit = 20}) {
    return _repository.popularTrbooks(limit: limit);
  }
}

class TrbooksByKeywordUseCase {
  const TrbooksByKeywordUseCase(this._repository);
  final TrbooksRepository _repository;

  Future<List<Book>> call(String keyword, {int limit = 20}) {
    return _repository.byKeyword(keyword, limit: limit);
  }
}

/// Resolves a stored book id to a [Book], regardless of which catalog it
/// came from: `trbooks:`-prefixed ids go to the local Turkish catalog,
/// everything else goes to Google Books.
class ResolveBookByIdUseCase {
  const ResolveBookByIdUseCase(this._trbooksRepository, this._bookRepository);
  final TrbooksRepository _trbooksRepository;
  final BookRepository _bookRepository;

  Future<Book> call(String id) async {
    if (id.startsWith('trbooks:')) {
      final book = await _trbooksRepository.getById(id);
      if (book == null) {
        throw StateError('trbooks entry not found for id: $id');
      }
      return book;
    }
    return _bookRepository.getBookByWorkId(id);
  }
}
