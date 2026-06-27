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
