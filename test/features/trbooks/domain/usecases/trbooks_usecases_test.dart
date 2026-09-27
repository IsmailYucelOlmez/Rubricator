import 'package:bookapp/features/books/domain/entities/book.dart';
import 'package:bookapp/features/trbooks/domain/repositories/trbooks_repository.dart';
import 'package:bookapp/features/trbooks/domain/usecases/trbooks_submission_exceptions.dart';
import 'package:bookapp/features/trbooks/domain/usecases/trbooks_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTrbooksRepository implements TrbooksRepository {
  String? lastGenreKey;
  int? lastLimit;
  List<Book> genreKeyResult = const <Book>[];

  String? lastSubmittedTitle;
  String? lastSubmittedAuthor;
  String? lastSubmittedIsbn;
  Book? submitUserBookResult;
  Object? submitUserBookError;

  @override
  Future<Book> submitUserBook({
    required String title,
    required String author,
    required String isbn,
    String? description,
    String? imageUrl,
    String? publisher,
    String? category,
    int? pageCount,
    int? releasedYear,
  }) async {
    lastSubmittedTitle = title;
    lastSubmittedAuthor = author;
    lastSubmittedIsbn = isbn;
    if (submitUserBookError != null) throw submitUserBookError!;
    return submitUserBookResult!;
  }

  @override
  Future<List<Book>> byGenreKey(String genreKey, {int limit = 20}) async {
    lastGenreKey = genreKey;
    lastLimit = limit;
    return genreKeyResult;
  }

  @override
  Future<List<Book>> byKeyword(String keyword, {int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Book>> byAuthor(String authorName, {int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<Book?> getById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Book>> popularTrbooks({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Book>> related({
    required String excludeId,
    String? category,
    required String author,
    int limit = 10,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Book>> searchTrbooks(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('TrbooksByGenreKeyUseCase', () {
    test('delegates to repository.byGenreKey with the given genre and limit', () async {
      final repository = _FakeTrbooksRepository()
        ..genreKeyResult = const [
          Book(
            id: 'trbooks:9789750738609',
            title: 'Şeker Portakalı',
            author: 'Jose Mauro De Vasconcelos',
            description: '',
          ),
        ];
      final useCase = TrbooksByGenreKeyUseCase(repository);

      final result = await useCase.call('fantasy', limit: 5);

      expect(repository.lastGenreKey, 'fantasy');
      expect(repository.lastLimit, 5);
      expect(result, repository.genreKeyResult);
    });

    test('defaults to a limit of 20 when none is given', () async {
      final repository = _FakeTrbooksRepository();
      final useCase = TrbooksByGenreKeyUseCase(repository);

      await useCase.call('popular_fiction');

      expect(repository.lastLimit, 20);
    });
  });

  group('SubmitUserTrbookUseCase', () {
    test('normalizes ISBN and delegates to repository.submitUserBook', () async {
      const submitted = Book(
        id: 'trbooks:9789750738609',
        title: 'Şeker Portakalı',
        author: 'Jose Mauro De Vasconcelos',
        description: '',
      );
      final repository = _FakeTrbooksRepository()..submitUserBookResult = submitted;
      final useCase = SubmitUserTrbookUseCase(repository);

      final result = await useCase.call(
        title: '  Şeker Portakalı  ',
        author: '  Jose Mauro De Vasconcelos  ',
        isbn: '978-975-07-3860-9',
      );

      expect(repository.lastSubmittedTitle, 'Şeker Portakalı');
      expect(repository.lastSubmittedAuthor, 'Jose Mauro De Vasconcelos');
      expect(repository.lastSubmittedIsbn, '9789750738609');
      expect(result, submitted);
    });

    test('throws TrbooksValidationException for an empty title without calling the repository', () async {
      final repository = _FakeTrbooksRepository();
      final useCase = SubmitUserTrbookUseCase(repository);

      expect(
        () => useCase.call(title: '  ', author: 'Author', isbn: '9789750738609'),
        throwsA(isA<TrbooksValidationException>()),
      );
      expect(repository.lastSubmittedTitle, isNull);
    });

    test('throws TrbooksValidationException for a malformed ISBN', () async {
      final repository = _FakeTrbooksRepository();
      final useCase = SubmitUserTrbookUseCase(repository);

      expect(
        () => useCase.call(title: 'Title', author: 'Author', isbn: '123'),
        throwsA(isA<TrbooksValidationException>()),
      );
    });

    test('propagates TrbooksDuplicateIsbnException from the repository', () async {
      final repository = _FakeTrbooksRepository()
        ..submitUserBookError = TrbooksDuplicateIsbnException('trbooks:9789750738609');
      final useCase = SubmitUserTrbookUseCase(repository);

      expect(
        () => useCase.call(title: 'Title', author: 'Author', isbn: '9789750738609'),
        throwsA(isA<TrbooksDuplicateIsbnException>()),
      );
    });
  });
}
