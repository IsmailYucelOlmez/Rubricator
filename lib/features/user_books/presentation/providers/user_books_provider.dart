import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../data/user_books_repository.dart';
import '../../domain/entities/user_book_entity.dart';

final userBooksRepositoryProvider = Provider<UserBooksRepository>(
  (ref) => UserBooksRepository(),
);

final userBookProvider =
    AsyncNotifierProviderFamily<UserBookNotifier, UserBookEntity?, String>(
      UserBookNotifier.new,
    );

final userBooksByStatusProvider =
    FutureProvider.family<List<UserBookEntity>, ReadingStatus>((ref, status) {
      ref.watch(authStateProvider);
      return ref.read(userBooksRepositoryProvider).getUserBooksByStatus(status);
    });

final favoriteUserBooksProvider = FutureProvider<List<UserBookEntity>>((ref) {
  ref.watch(authStateProvider);
  return ref.read(userBooksRepositoryProvider).getFavoriteUserBooks();
});

class UserBookNotifier extends FamilyAsyncNotifier<UserBookEntity?, String> {
  late final String _bookId;

  @override
  Future<UserBookEntity?> build(String arg) {
    _bookId = arg;
    ref.watch(authStateProvider);
    return ref.read(userBooksRepositoryProvider).getUserBook(arg);
  }

  Future<void> upsert({
    required ReadingStatus status,
    bool? isFavorite,
    int? progress,
  }) async {
    final previous = state.valueOrNull;
    final previousStatus = previous?.status;
    final now = DateTime.now();
    final userId = ref.read(authStateProvider).valueOrNull?.id ?? '';
    final optimistic = (previous ??
            UserBookEntity(
              id: '',
              userId: userId,
              bookId: _bookId,
              status: ReadingStatus.toRead,
              isFavorite: false,
              progress: null,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
          status: status,
          isFavorite: isFavorite ?? previous?.isFavorite ?? false,
          progress: status == ReadingStatus.reading ? progress : null,
          updatedAt: now,
        );
    state = AsyncData(optimistic);

    state = await AsyncValue.guard(() async {
      await ref
          .read(userBooksRepositoryProvider)
          .upsertUserBook(
            bookId: _bookId,
            status: status,
            isFavorite: isFavorite,
            progress: progress,
          );
      if (previousStatus != null && previousStatus != status) {
        ref.invalidate(userBooksByStatusProvider(previousStatus));
      }
      ref.invalidate(userBooksByStatusProvider(status));
      ref.invalidate(favoriteUserBooksProvider);
      return ref.read(userBooksRepositoryProvider).getUserBook(_bookId);
    });
  }

  Future<void> toggleFavorite() async {
    final previous = state.valueOrNull;
    final now = DateTime.now();
    final userId = ref.read(authStateProvider).valueOrNull?.id ?? '';
    final optimistic = (previous ??
            UserBookEntity(
              id: '',
              userId: userId,
              bookId: _bookId,
              status: ReadingStatus.toRead,
              isFavorite: false,
              progress: null,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(isFavorite: !(previous?.isFavorite ?? false), updatedAt: now);
    state = AsyncData(optimistic);

    state = await AsyncValue.guard(() async {
      await ref.read(userBooksRepositoryProvider).toggleFavorite(_bookId);
      if (previous != null) {
        ref.invalidate(userBooksByStatusProvider(previous.status));
      } else {
        ref.invalidate(userBooksByStatusProvider(ReadingStatus.toRead));
      }
      ref.invalidate(favoriteUserBooksProvider);
      return ref.read(userBooksRepositoryProvider).getUserBook(_bookId);
    });
  }
}
