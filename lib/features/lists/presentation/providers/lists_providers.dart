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
final getFollowingListsUseCaseProvider = Provider<GetFollowingListsUseCase>(
  (ref) => GetFollowingListsUseCase(ref.watch(listsRepositoryProvider)),
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

final popularListsProvider = FutureProvider<List<ListEntity>>((ref) {
  return ref.read(getPopularListsUseCaseProvider).call();
});

final followingListsProvider = FutureProvider<List<ListEntity>>((ref) {
  return ref.read(getFollowingListsUseCaseProvider).call();
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
