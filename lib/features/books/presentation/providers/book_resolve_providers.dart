import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/book_identity_cache_datasource.dart';
import '../../data/repositories/book_resolve_repository_impl.dart';
import '../../domain/entities/book.dart';
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
