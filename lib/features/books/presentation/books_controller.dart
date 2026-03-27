import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ai_service.dart';
import '../../../services/api_service.dart';
import '../data/book_repository.dart';
import '../domain/book.dart';

final _apiProvider = Provider<ApiService>((ref) => ApiService());

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepository(ref.watch(_apiProvider)),
);
final _aiServiceProvider = Provider<AiService>((ref) => AiService());

final trendingBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.watch(bookRepositoryProvider).trendingBooks();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchedBooksProvider = FutureProvider<List<Book>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(bookRepositoryProvider).searchBooks(query);
});

final bookDetailProvider = FutureProvider.family<Book, Book>((ref, book) {
  return ref.watch(bookRepositoryProvider).getBookDetail(book);
});

final aiSummaryProvider = FutureProvider.family<String, Book>((ref, book) {
  return ref.watch(_aiServiceProvider).summarize(book);
});
