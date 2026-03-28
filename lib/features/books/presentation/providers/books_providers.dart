import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/ai_service.dart';
import '../../../../services/api_service.dart';
import '../../data/repositories/book_repository.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';

final _apiProvider = Provider<ApiService>((ref) => ApiService());

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepository(ref.watch(_apiProvider)),
);

final _aiServiceProvider = Provider<AiService>((ref) => AiService());

final trendingBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.watch(bookRepositoryProvider).trendingBooks();
});

/// Loaded work merged with list item (title, cover, authors from search when present).
final bookDetailProvider = FutureProvider.family<Book, Book>((ref, book) {
  return ref.watch(bookRepositoryProvider).getBookDetail(book);
});

final aiSummaryProvider = FutureProvider.family<String, Book>((ref, book) {
  return ref.watch(_aiServiceProvider).summarize(book);
});

final authorDetailProvider = FutureProvider.family<Author, String>((ref, authorId) {
  return ref.watch(bookRepositoryProvider).getAuthor(authorId);
});

/// Subjects come from the work payload; use the enriched [Book] from [bookDetailProvider].
final relatedBooksProvider =
    FutureProvider.family<List<Book>, ({String workId, List<String> subjects})>((
  ref,
  arg,
) async {
  if (arg.subjects.isEmpty) return <Book>[];
  final book = Book(
    id: arg.workId,
    title: '',
    author: '',
    coverId: null,
    description: '',
    subjectKeys: arg.subjects,
  );
  return ref.watch(bookRepositoryProvider).getRelatedBooks(book);
});
