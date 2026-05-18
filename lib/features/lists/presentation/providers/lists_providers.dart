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

Map<String, int> _buildAuthorWeights(List<AuthorStat> stats) {
  final weights = <String, int>{};
  for (final stat in stats) {
    final key = _normalizeAuthorKey(stat.author);
    if (key.isEmpty) continue;
    weights[key] = (weights[key] ?? 0) + stat.count;
  }
  return weights;
}

String _normalizeAuthorKey(String author) {
  return author.trim().toLowerCase();
}

bool _authorKeysMatch(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  if (a.contains(b) || b.contains(a)) return true;
  final aLast = a.split(RegExp(r'\s+')).lastOrNull ?? '';
  final bLast = b.split(RegExp(r'\s+')).lastOrNull ?? '';
  return aLast.length > 2 && aLast == bLast;
}

int _authorMatchInHaystack(String haystack, Map<String, int> weights) {
  var score = 0;
  for (final entry in weights.entries) {
    if (_authorKeysMatch(haystack, entry.key)) {
      score += entry.value;
    }
  }
  return score;
}

int _listItemsAuthorScore(
  List<ListItemEntity> items,
  Map<String, int> weights,
) {
  var score = 0;
  for (final item in items) {
    final author = _normalizeAuthorKey(item.bookAuthor);
    if (author.isEmpty || author == 'unknown author') continue;
    for (final entry in weights.entries) {
      if (_authorKeysMatch(author, entry.key)) {
        score += entry.value;
        break;
      }
    }
  }
  return score;
}

int _popularityBoost(ListEntity list) {
  return (list.likeCount ~/ 5) + (list.commentCount ~/ 3);
}

int _combinedListScore({
  required ListEntity list,
  required Map<String, int> genreWeights,
  required Map<String, int> authorWeights,
  required List<ListItemEntity> items,
}) {
  final genreScore = _listGenreMatchScore(list, genreWeights);
  final metaHaystack =
      '${list.title} ${list.description}'.toLowerCase();
  final authorMetaScore = _authorMatchInHaystack(metaHaystack, authorWeights);
  final authorItemScore = _listItemsAuthorScore(items, authorWeights);
  final authorScore = authorMetaScore + (authorItemScore * 2);
  final tasteScore = ((genreScore * 6) + (authorScore * 4)) ~/ 10;
  return tasteScore + _popularityBoost(list);
}

List<ListEntity> _sortListsByScore(
  List<({ListEntity list, int score})> scored,
) {
  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byLikes = b.list.likeCount.compareTo(a.list.likeCount);
    if (byLikes != 0) return byLikes;
    return b.list.createdAt.compareTo(a.list.createdAt);
  });
  return <ListEntity>[for (final entry in scored) entry.list];
}

final forYouListsProvider = FutureProvider<List<ListEntity>>((ref) async {
  final repo = ref.watch(listsRepositoryProvider);
  final baseLists = await ref.read(getFeedListsUseCaseProvider).call();
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return baseLists;

  final genreStats = ref.watch(genreStatsProvider).valueOrNull ?? const <GenreStat>[];
  final authorStats =
      ref.watch(authorStatsProvider).valueOrNull ?? const <AuthorStat>[];
  if (genreStats.isEmpty && authorStats.isEmpty) {
    return ref.read(getPopularListsUseCaseProvider).call();
  }

  final genreWeights = _buildGenreWeights(genreStats);
  final authorWeights = _buildAuthorWeights(authorStats);
  final itemsByListId = await repo.getListItemsByListIds(
    baseLists.map((l) => l.id).toList(),
  );

  final scored = <({ListEntity list, int score})>[
    for (final list in baseLists)
      (
        list: list,
        score: _combinedListScore(
          list: list,
          genreWeights: genreWeights,
          authorWeights: authorWeights,
          items: itemsByListId[list.id] ?? const <ListItemEntity>[],
        ),
      ),
  ];
  if (!scored.any((entry) => entry.score > 0)) {
    return ref.read(getPopularListsUseCaseProvider).call();
  }
  return _sortListsByScore(scored);
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
