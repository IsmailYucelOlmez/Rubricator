import '../../../../services/api_service.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../datasources/open_library_remote_datasource.dart';
import '../models/book_model.dart';

class BookRepository {
  BookRepository(ApiService api) : _ds = OpenLibraryRemoteDataSource(api);

  final OpenLibraryRemoteDataSource _ds;

  Future<List<Book>> trendingBooks() async {
    final models = await _ds.fetchTrendingWorks();
    return models.map((m) => m.toEntity()).toList();
  }

  /// Paginated search (`page` is 1-based). Empty [query] returns no results.
  Future<BookSearchPageResult> searchBooks({
    required String query,
    int page = 1,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const BookSearchPageResult(
        books: [],
        hasMore: false,
        totalFound: 0,
      );
    }
    final raw = await _ds.searchBooks(query: trimmed, page: page);
    final books = raw.docs.map((m) => m.toEntity()).toList();
    final end = raw.start + raw.docs.length;
    final hasMore = end < raw.numFound && raw.docs.isNotEmpty;
    return BookSearchPageResult(
      books: books,
      hasMore: hasMore,
      totalFound: raw.numFound,
    );
  }

  Future<Book> getBookByWorkId(String workId) async {
    var model = await _ds.fetchWork(workId.trim());
    if (model.primaryAuthorName == 'Unknown author' &&
        model.authorKeys.isNotEmpty) {
      try {
        final a = await _ds.fetchAuthor(model.authorKeys.first);
        model = model.copyWith(primaryAuthorName: a.name);
      } catch (_) {}
    }
    return model.toEntity();
  }

  Future<Book> getBookDetail(Book book) async {
    final seed = BookModel.fromEntity(book);
    final model = await _ds.fetchWorkMerged(book.id, seed);
    return model.toEntity();
  }

  Future<Author> getAuthor(String authorId) async {
    final model = await _ds.fetchAuthor(authorId);
    return model.toEntity();
  }

  Future<List<Book>> getRelatedBooks(Book book) async {
    List<BookModel> models = const <BookModel>[];
    final subject = book.subjectKeys.isNotEmpty ? book.subjectKeys.first : '';
    if (subject.isNotEmpty) {
      models = await _ds.fetchRelatedBySubject(
        subject: subject,
        excludeWorkId: book.id,
      );
    }
    if (models.isEmpty && book.author.trim().isNotEmpty) {
      models = await _ds.fetchRelatedByAuthor(
        author: book.author,
        excludeWorkId: book.id,
      );
    }
    return models.map((m) => m.toEntity()).toList();
  }
}

class BookSearchPageResult {
  const BookSearchPageResult({
    required this.books,
    required this.hasMore,
    required this.totalFound,
  });

  final List<Book> books;
  final bool hasMore;
  final int totalFound;
}
