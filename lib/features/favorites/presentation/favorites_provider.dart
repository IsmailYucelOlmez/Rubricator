import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../books/domain/entities/book.dart';
import '../../books/presentation/providers/books_providers.dart';
import '../../user_books/domain/entities/user_book_entity.dart';
import '../../user_books/presentation/providers/user_books_provider.dart';

final favoriteEntriesProvider =
    FutureProvider<List<({Book book, UserBookEntity userBook})>>((ref) {
      ref.watch(authStateProvider);
      return _hydrateEntries(
        ref: ref,
        rows: ref.watch(favoriteUserBooksProvider.future),
      );
    });

final listEntriesByStatusProvider =
    FutureProvider.family<
      List<({Book book, UserBookEntity userBook})>,
      ReadingStatus
    >((ref, status) {
      ref.watch(authStateProvider);
      return _hydrateEntries(
        ref: ref,
        rows: ref.watch(userBooksByStatusProvider(status).future),
      );
    });

Future<List<({Book book, UserBookEntity userBook})>> _hydrateEntries({
  required Ref ref,
  required Future<List<UserBookEntity>> rows,
}) async {
  final userBooks = await rows;
  final bookRepo = ref.read(bookRepositoryProvider);
  final entries = <({Book book, UserBookEntity userBook})>[];
  for (final userBook in userBooks) {
    try {
      final book = await bookRepo.getBookByWorkId(userBook.bookId);
      entries.add((book: book, userBook: userBook));
    } catch (_) {
      // Skip missing or network failures for a single id.
    }
  }
  return entries;
}
