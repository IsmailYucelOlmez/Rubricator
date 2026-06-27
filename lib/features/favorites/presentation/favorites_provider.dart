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

const _fetchConcurrency = 4;

Book _bookFromStoredSnapshot(UserBookEntity userBook) {
  return Book(
    id: userBook.bookId,
    title: userBook.bookTitle!,
    author: userBook.bookAuthor!,
    description: '',
    subjectKeys: userBook.bookCategories,
  );
}

Future<List<({Book book, UserBookEntity userBook})>> _hydrateEntries({
  required Ref ref,
  required Future<List<UserBookEntity>> rows,
}) async {
  final userBooks = await rows;
  if (userBooks.isEmpty) return const [];

  final bookRepo = ref.read(bookRepositoryProvider);
  final bookById = <String, Book>{};

  for (final userBook in userBooks) {
    if (userBook.hasCompletedSnapshot) {
      bookById[userBook.bookId] = _bookFromStoredSnapshot(userBook);
    }
  }

  final needFetch = userBooks.where((userBook) {
    final existing = bookById[userBook.bookId];
    if (existing == null) return true;
    final cover = existing.coverImageUrl;
    return cover == null || cover.isEmpty;
  }).toList();
  for (var i = 0; i < needFetch.length; i += _fetchConcurrency) {
    final end = (i + _fetchConcurrency > needFetch.length)
        ? needFetch.length
        : i + _fetchConcurrency;
    final chunk = needFetch.sublist(i, end);
    await Future.wait(
      chunk.map((userBook) async {
        try {
          final fetched =
              await bookRepo.getBookByWorkId(userBook.bookId);
          final existing = bookById[userBook.bookId];
          if (existing != null) {
            bookById[userBook.bookId] = existing.copyWith(
              coverImageUrl: fetched.coverImageUrl ?? existing.coverImageUrl,
              description: existing.description.isEmpty
                  ? fetched.description
                  : existing.description,
            );
          } else {
            bookById[userBook.bookId] = fetched;
          }
        } catch (_) {
          // Skip missing or network failures for a single id.
        }
      }),
    );
  }

  final entries = <({Book book, UserBookEntity userBook})>[];
  for (final userBook in userBooks) {
    final book = bookById[userBook.bookId];
    if (book != null) {
      entries.add((book: book, userBook: userBook));
    }
  }
  return entries;
}
