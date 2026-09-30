import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../data/repositories/supabase_lists_repository.dart';
import '../../domain/entities/list_entities.dart';
import '../../domain/repositories/lists_repository.dart';
import '../../domain/usecases/lists_usecases.dart';

final listsRepositoryProvider = Provider<ListsRepository>((ref) {
  ref.watch(authStateProvider);
  return SupabaseListsRepository();
});

final getFeedListsUseCaseProvider = Provider<GetFeedListsUseCase>(
  (ref) => GetFeedListsUseCase(ref.watch(listsRepositoryProvider)),
);
final getPopularListsUseCaseProvider = Provider<GetPopularListsUseCase>(
  (ref) => GetPopularListsUseCase(ref.watch(listsRepositoryProvider)),
);
final getRecommendedListsUseCaseProvider = Provider<GetRecommendedListsUseCase>(
  (ref) => GetRecommendedListsUseCase(ref.watch(listsRepositoryProvider)),
);
final getTopListsByEngagementUseCaseProvider = Provider<GetTopListsByEngagementUseCase>(
  (ref) => GetTopListsByEngagementUseCase(ref.watch(listsRepositoryProvider)),
);
final getUserListsUseCaseProvider = Provider<GetUserListsUseCase>(
  (ref) => GetUserListsUseCase(ref.watch(listsRepositoryProvider)),
);
final getSavedListsUseCaseProvider = Provider<GetSavedListsUseCase>(
  (ref) => GetSavedListsUseCase(ref.watch(listsRepositoryProvider)),
);
final searchListsUseCaseProvider = Provider<SearchListsUseCase>(
  (ref) => SearchListsUseCase(ref.watch(listsRepositoryProvider)),
);

final listsFeedProvider = FutureProvider<List<ListEntity>>((ref) {
  return ref.read(getFeedListsUseCaseProvider).call();
});

/// Precomputed list recommendations from Supabase; falls back to popular lists.
final forYouListsProvider = FutureProvider<List<ListEntity>>((ref) async {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) {
    return ref.read(getFeedListsUseCaseProvider).call();
  }

  final recommended = await ref.read(getRecommendedListsUseCaseProvider).call();
  if (recommended.isEmpty) {
    return ref.read(getPopularListsUseCaseProvider).call();
  }
  return recommended;
});

final popularListsProvider = FutureProvider<List<ListEntity>>((ref) {
  return ref.read(getPopularListsUseCaseProvider).call();
});

final topListsProvider = FutureProvider<List<ListEntity>>((ref) {
  return ref.read(getTopListsByEngagementUseCaseProvider).call(limit: 20);
});

final userListsProvider = FutureProvider<List<ListEntity>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return Future.value(const <ListEntity>[]);
  return ref.read(getUserListsUseCaseProvider).call(userId);
});

final savedListsProvider = FutureProvider<List<ListEntity>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return Future.value(const <ListEntity>[]);
  return ref.read(getSavedListsUseCaseProvider).call(userId);
});

final listItemsProvider = FutureProvider.family<List<ListItemEntity>, String>((
  ref,
  listId,
) {
  return ref.watch(listsRepositoryProvider).getListItems(listId);
});

final commentsProvider = FutureProvider.family<List<ListComment>, String>((ref, listId) {
  return ref.watch(listsRepositoryProvider).getComments(listId);
});

/// Current query typed on [ListSearchPage].
final listSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Results for [listSearchQueryProvider], searched across all public lists in the database.
final listSearchResultsProvider = FutureProvider.autoDispose<List<ListEntity>>((ref) async {
  final query = ref.watch(listSearchQueryProvider).trim();
  if (query.isEmpty) return const <ListEntity>[];
  return ref.read(searchListsUseCaseProvider).call(query);
});

/// Lists (public + the viewer's own) containing a book, for the book's
/// "lists with this book" page.
final listsContainingBookProvider = FutureProvider.autoDispose
    .family<List<ListEntity>, String>((ref, bookId) {
      ref.watch(authStateProvider);
      return ref.watch(listsRepositoryProvider).getListsContainingBook(bookId);
    });

/// Number of lists behind [listsContainingBookProvider], for the book page.
final listsContainingBookCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, bookId) {
      ref.watch(authStateProvider);
      return ref.watch(listsRepositoryProvider).countListsContainingBook(bookId);
    });

/// Book fields copied onto a list item.
typedef ListBookSnapshot = ({
  String bookId,
  String title,
  String author,
  String? coverImageUrl,
});

/// Which of the signed-in user's lists contain a book: `listId -> listItemId`.
/// A `null` item id marks an add that hasn't been confirmed by the server yet.
class BookListMembershipNotifier
    extends AutoDisposeFamilyAsyncNotifier<Map<String, String?>, String> {
  final _pending = <String>{};

  @override
  Future<Map<String, String?>> build(String bookId) async {
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    if (userId == null) return const {};
    return ref
        .watch(listsRepositoryProvider)
        .getListItemIdsForBook(userId: userId, bookId: bookId);
  }

  bool isPending(String listId) => _pending.contains(listId);

  /// Adds the book to [listId] or removes it, showing the change right away
  /// and rolling back just that list if the request fails. Taps on a list
  /// whose previous toggle is still running are ignored.
  Future<void> toggle(String listId, ListBookSnapshot book) async {
    final current = state.valueOrNull;
    if (current == null || !_pending.add(listId)) return;
    final repo = ref.read(listsRepositoryProvider);
    final wasMember = current.containsKey(listId);
    final itemId = current[listId];

    void set(String? Function(Map<String, String?> map) update) {
      final next = Map<String, String?>.of(state.valueOrNull ?? const {});
      update(next);
      state = AsyncData(next);
    }

    try {
      if (wasMember) {
        if (itemId == null) return;
        set((m) => m.remove(listId));
        await repo.removeBookFromList(itemId);
      } else {
        set((m) => m[listId] = null);
        final item = await repo.addBookToList(
          listId: listId,
          bookId: book.bookId,
          title: book.title,
          author: book.author,
          coverImageUrl: book.coverImageUrl,
        );
        set((m) => m[listId] = item.id);
      }
      _invalidateListViews(listId);
    } catch (_) {
      set((m) => wasMember ? m[listId] = itemId : m.remove(listId));
      rethrow;
    } finally {
      _pending.remove(listId);
    }
  }

  /// Covers, counts and list contents shown elsewhere changed.
  void _invalidateListViews(String listId) {
    ref.invalidate(listItemsProvider(listId));
    ref.invalidate(userListsProvider);
    ref.invalidate(listsFeedProvider);
    ref.invalidate(popularListsProvider);
    ref.invalidate(topListsProvider);
    ref.invalidate(savedListsProvider);
    ref.invalidate(listsContainingBookProvider(arg));
    ref.invalidate(listsContainingBookCountProvider(arg));
  }
}

final bookListMembershipProvider = AsyncNotifierProvider.autoDispose
    .family<BookListMembershipNotifier, Map<String, String?>, String>(
      BookListMembershipNotifier.new,
    );
