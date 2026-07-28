import '../entities/book.dart';
import '../repositories/book_resolve_repository.dart';

class ResolveBookUseCase {
  const ResolveBookUseCase(this._repository);

  final BookResolveRepository _repository;

  Future<Book> call(Book unresolved) => _repository.resolve(unresolved);
}
