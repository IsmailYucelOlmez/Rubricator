import '../../../books/domain/entities/book.dart';

abstract class BookResolveRepository {
  Future<Book> resolve(Book unresolved);
}
