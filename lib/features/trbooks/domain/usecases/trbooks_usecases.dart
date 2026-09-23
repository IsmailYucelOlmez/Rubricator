import '../../../books/data/repositories/book_repository.dart';
import '../../../books/domain/entities/book.dart';
import '../repositories/trbook_description_repository.dart';
import '../repositories/trbooks_repository.dart';
import 'trbooks_submission_exceptions.dart';

/// Strips everything but digits/`X` (mirrors the server-side
/// `trbooks_normalize_isbn` SQL function) so client-side validation matches
/// what the RPC will accept.
String? normalizeIsbn(String raw) {
  final normalized = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
  return normalized.isEmpty ? null : normalized;
}

void _validateSubmission({
  required String title,
  required String author,
  required String isbn,
}) {
  if (title.trim().isEmpty) {
    throw TrbooksValidationException('Title is required.');
  }
  if (author.trim().isEmpty) {
    throw TrbooksValidationException('Author is required.');
  }
  final normalizedIsbn = normalizeIsbn(isbn);
  if (normalizedIsbn == null || (normalizedIsbn.length != 10 && normalizedIsbn.length != 13)) {
    throw TrbooksValidationException('ISBN must be 10 or 13 digits.');
  }
}

class SearchTrbooksUseCase {
  const SearchTrbooksUseCase(this._repository);
  final TrbooksRepository _repository;

  Future<List<Book>> call(String query, {int limit = 20, int offset = 0}) {
    return _repository.searchTrbooks(query, limit: limit, offset: offset);
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

class TrbooksByGenreKeyUseCase {
  const TrbooksByGenreKeyUseCase(this._repository);
  final TrbooksRepository _repository;

  Future<List<Book>> call(String genreKey, {int limit = 20}) {
    return _repository.byGenreKey(genreKey, limit: limit);
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

class SubmitUserTrbookUseCase {
  const SubmitUserTrbookUseCase(this._repository);
  final TrbooksRepository _repository;

  Future<Book> call({
    required String title,
    required String author,
    required String isbn,
    String? description,
    String? imageUrl,
    String? publisher,
    String? category,
    int? pageCount,
    int? releasedYear,
  }) {
    _validateSubmission(title: title, author: author, isbn: isbn);
    return _repository.submitUserBook(
      title: title.trim(),
      author: author.trim(),
      isbn: normalizeIsbn(isbn)!,
      description: description?.trim().isEmpty ?? true ? null : description!.trim(),
      imageUrl: imageUrl?.trim().isEmpty ?? true ? null : imageUrl!.trim(),
      publisher: publisher?.trim().isEmpty ?? true ? null : publisher!.trim(),
      category: category?.trim().isEmpty ?? true ? null : category!.trim(),
      pageCount: pageCount,
      releasedYear: releasedYear,
    );
  }
}

/// Only meaningful once title/author/ISBN are all filled in — the "generate
/// description" button in the add-book form stays disabled until then.
class GenerateTrbookDescriptionUseCase {
  const GenerateTrbookDescriptionUseCase(this._repository);
  final TrbookDescriptionRepository _repository;

  Future<String> call({
    required String title,
    required String author,
    required String isbn,
  }) {
    _validateSubmission(title: title, author: author, isbn: isbn);
    return _repository.generateDescription(
      title: title.trim(),
      author: author.trim(),
      isbn: normalizeIsbn(isbn)!,
    );
  }
}
