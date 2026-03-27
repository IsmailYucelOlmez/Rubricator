import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../books/domain/book.dart';
import '../../books/presentation/books_controller.dart';
import '../data/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(),
);

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Book>>(FavoritesNotifier.new);

class FavoritesNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading || auth.hasError) return const <Book>[];
    final user = auth.valueOrNull;
    if (user == null) return const <Book>[];

    final ids = await ref.read(favoritesRepositoryProvider).listFavoriteBookIds();
    final bookRepo = ref.read(bookRepositoryProvider);
    final books = <Book>[];
    for (final id in ids) {
      try {
        books.add(await bookRepo.getBookByWorkId(id));
      } catch (_) {
        // Skip missing or network failures for a single id.
      }
    }
    return books;
  }

  bool isFavorite(String bookId) {
    return state.maybeWhen(
      data: (books) => books.any((b) => b.id == bookId),
      orElse: () => false,
    );
  }

  Future<void> toggle(Book book) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      throw StateError('Sign in to manage favorites.');
    }
    final repo = ref.read(favoritesRepositoryProvider);
    final ids = await repo.listFavoriteBookIds();
    final exists = ids.contains(book.id);
    if (exists) {
      await repo.removeFavorite(book.id);
    } else {
      await repo.addFavorite(book.id);
    }
    ref.invalidateSelf();
  }
}
