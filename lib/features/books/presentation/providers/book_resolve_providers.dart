import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/book_identity_cache_datasource.dart';
import '../../data/repositories/book_resolve_repository_impl.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../../domain/repositories/book_resolve_repository.dart';
import '../../domain/usecases/resolve_book_usecase.dart';
import 'books_providers.dart';

final _bookIdentityCacheProvider = Provider<BookIdentityCacheDataSource>(
  (ref) => BookIdentityCacheDataSource(Supabase.instance.client),
);

final bookResolveRepositoryProvider = Provider<BookResolveRepository>((ref) {
  return BookResolveRepositoryImpl(
    bookRepository: ref.watch(bookRepositoryProvider),
    identityCache: ref.watch(_bookIdentityCacheProvider),
  );
});

final resolveBookUseCaseProvider = Provider<ResolveBookUseCase>(
  (ref) => ResolveBookUseCase(ref.watch(bookResolveRepositoryProvider)),
);

final resolveBookProvider = FutureProvider.family<Book, Book>((ref, book) {
  return ref.watch(resolveBookUseCaseProvider).call(book);
});

bool isPendingBookId(String id) => id.trim().startsWith('pending:');

BookEntity bookEntityFromBook(Book book) => BookEntity(
      id: book.id,
      title: book.title,
      author: book.author,
      coverImageUrl: book.coverImageUrl,
      description: book.description,
      authorIds: book.authorIds,
      subjectKeys: book.subjectKeys,
    );

/// Resolves `pending:` books and maps the Google-hydrated result to [BookEntity]
/// without a second `/volumes/{id}` fetch.
final resolvedBookDetailProvider =
    FutureProvider.family<BookEntity, Book>((ref, book) async {
  final resolved = await ref.watch(resolveBookProvider(book).future);
  return bookEntityFromBook(resolved);
});
