import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../lists/presentation/providers/lists_providers.dart';
import '../../../profile_stats/presentation/providers/profile_stats_providers.dart';
import '../../data/user_books_repository.dart';
import '../../domain/entities/user_book_entity.dart';
import '../../domain/entities/user_book_snapshot.dart';

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

/// One query for all favorite book ids (home page cards).
final favoriteBookIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authStateProvider);
  final ids = await ref.read(userBooksRepositoryProvider).getFavoriteBookIds();
  return ids.toSet();
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
    UserBookSnapshot? snapshot,
  }) async {
    final userId = ref.read(authStateProvider).valueOrNull?.id;
    if (userId == null || userId.isEmpty) {
      throw UserBooksException('Sign in to manage your reading list.');
    }

    final previous = state.valueOrNull;
    final previousStatus = previous?.status;
    final now = DateTime.now();
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
          completedAt: status == ReadingStatus.completed ? now : null,
          bookTitle: snapshot?.title ?? previous?.bookTitle,
          bookAuthor: snapshot?.author ?? previous?.bookAuthor,
          bookCategories: snapshot?.categories ?? previous?.bookCategories ?? const [],
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
            snapshot: snapshot,
          );
      if (previousStatus != null && previousStatus != status) {
        ref.invalidate(userBooksByStatusProvider(previousStatus));
      }
      ref.invalidate(userBooksByStatusProvider(status));
      ref.invalidate(favoriteUserBooksProvider);
      _invalidateProfileStatsIfNeeded(previousStatus, status);
      _invalidateForYouListsIfNeeded(previousStatus, status, isFavorite);
      return ref.read(userBooksRepositoryProvider).getUserBook(_bookId);
    });
  }

  void _invalidateProfileStatsIfNeeded(
    ReadingStatus? previous,
    ReadingStatus next,
  ) {
    if (previous == ReadingStatus.completed || next == ReadingStatus.completed) {
      ref.read(profileStatsGenerationProvider.notifier).state++;
      ref.invalidate(profileStatsSummaryProvider);
      ref.invalidate(genreStatsProvider);
      ref.invalidate(authorStatsProvider);
      ref.invalidate(libraryStatsProvider);
    }
  }

  void _invalidateForYouListsIfNeeded(
    ReadingStatus? previous,
    ReadingStatus next,
    bool? isFavorite,
  ) {
    if (previous == ReadingStatus.completed ||
        next == ReadingStatus.completed ||
        isFavorite != null) {
      ref.invalidate(forYouListsProvider);
    }
  }

  Future<void> toggleFavorite({UserBookSnapshot? snapshot}) async {
    final previous = state.valueOrNull;
    final now = DateTime.now();
    final userId = ref.read(authStateProvider).valueOrNull?.id ?? '';
    final toggledFavorite = !(previous?.isFavorite ?? false);
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
          isFavorite: toggledFavorite,
          updatedAt: now,
          bookTitle: snapshot?.title ?? previous?.bookTitle,
          bookAuthor: snapshot?.author ?? previous?.bookAuthor,
          bookCategories: snapshot?.categories ?? previous?.bookCategories ?? const [],
        );
    state = AsyncData(optimistic);

    state = await AsyncValue.guard(() async {
      await ref
          .read(userBooksRepositoryProvider)
          .toggleFavorite(_bookId, snapshot: snapshot);
      if (previous != null) {
        ref.invalidate(userBooksByStatusProvider(previous.status));
      } else {
        ref.invalidate(userBooksByStatusProvider(ReadingStatus.toRead));
      }
      ref.invalidate(favoriteUserBooksProvider);
      ref.invalidate(favoriteBookIdsProvider);
      ref.invalidate(forYouListsProvider);
      return ref.read(userBooksRepositoryProvider).getUserBook(_bookId);
    });
  }
}
