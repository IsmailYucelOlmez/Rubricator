import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../profile_stats/domain/entities/profile_stats_entities.dart';
import '../../../profile_stats/presentation/providers/profile_stats_providers.dart';
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

Map<String, int> _buildGenreWeights(List<GenreStat> stats) {
  final weights = <String, int>{
    'fantasy': 0,
    'science_fiction': 0,
    'romance': 0,
    'mystery': 0,
    'thriller': 0,
    'horror': 0,
  };
  for (final stat in stats) {
    final value = stat.genre.trim().toLowerCase().replaceAll('_', ' ');
    String? key;
    if (value.contains('science fiction') ||
        value.contains('sci fi') ||
        value.contains('sci-fi')) {
      key = 'science_fiction';
    } else if (value.contains('fantasy')) {
      key = 'fantasy';
    } else if (value.contains('romance') || value.contains('love')) {
      key = 'romance';
    } else if (value.contains('mystery') ||
        value.contains('detective') ||
        value.contains('crime')) {
      key = 'mystery';
    } else if (value.contains('thriller') ||
        value.contains('suspense') ||
        value.contains('action')) {
      key = 'thriller';
    } else if (value.contains('horror') || value.contains('ghost')) {
      key = 'horror';
    }
    if (key != null) {
      weights[key] = (weights[key] ?? 0) + stat.count;
    }
  }
  return weights;
}

int _listGenreMatchScore(ListEntity list, Map<String, int> weights) {
  final haystack = '${list.title} ${list.description}'.toLowerCase();
  var score = 0;
  if (haystack.contains('fantasy') || haystack.contains('magic')) {
    score += weights['fantasy'] ?? 0;
  }
  if (haystack.contains('science fiction') ||
      haystack.contains('sci-fi') ||
      haystack.contains('space')) {
    score += weights['science_fiction'] ?? 0;
  }
  if (haystack.contains('romance') || haystack.contains('love')) {
    score += weights['romance'] ?? 0;
  }
  if (haystack.contains('mystery') ||
      haystack.contains('detective') ||
      haystack.contains('crime')) {
    score += weights['mystery'] ?? 0;
  }
  if (haystack.contains('thriller') ||
      haystack.contains('suspense') ||
      haystack.contains('action')) {
    score += weights['thriller'] ?? 0;
  }
  if (haystack.contains('horror') || haystack.contains('ghost')) {
    score += weights['horror'] ?? 0;
  }
  return score;
}

final forYouListsProvider = FutureProvider<List<ListEntity>>((ref) async {
  final baseLists = await ref.read(getFeedListsUseCaseProvider).call();
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return baseLists;

  final statsAsync = ref.watch(genreStatsProvider);
  final stats = statsAsync.valueOrNull;
  if (stats == null || stats.isEmpty) return baseLists;

  final weights = _buildGenreWeights(stats);
  final scored = <({ListEntity list, int score})>[
    for (final list in baseLists)
      (list: list, score: _listGenreMatchScore(list, weights)),
  ];
  final hasAnyScore = scored.any((entry) => entry.score > 0);
  if (!hasAnyScore) return baseLists;

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return b.list.createdAt.compareTo(a.list.createdAt);
  });
  return <ListEntity>[for (final entry in scored) entry.list];
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
