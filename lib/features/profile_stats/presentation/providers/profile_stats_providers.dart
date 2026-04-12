import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../data/datasources/profile_stats_remote_datasource.dart';
import '../../data/repositories/profile_stats_repository_impl.dart';
import '../../domain/entities/profile_stats_entities.dart';
import '../../domain/repositories/profile_stats_repository.dart';
import '../../domain/usecases/profile_stats_usecases.dart';

final profileStatsRemoteProvider = Provider<ProfileStatsRemoteDataSource>(
  (ref) => ProfileStatsRemoteDataSource(Supabase.instance.client),
);

/// Bump to drop in-memory aggregation cache in [ProfileStatsRepositoryImpl] (e.g. pull-to-refresh).
final profileStatsGenerationProvider = StateProvider<int>((ref) => 0);

final profileStatsRepositoryProvider = Provider<ProfileStatsRepository>((ref) {
  ref.watch(profileStatsGenerationProvider);
  ref.watch(authStateProvider.select((a) => a.valueOrNull?.id));
  return ProfileStatsRepositoryImpl(
    ref.watch(profileStatsRemoteProvider),
    ref.watch(bookRepositoryProvider),
    () => ref.watch(authStateProvider).valueOrNull?.id,
  );
});

final getProfileStatsSummaryUseCaseProvider =
    Provider<GetProfileStatsSummaryUseCase>(
  (ref) => GetProfileStatsSummaryUseCase(ref.watch(profileStatsRepositoryProvider)),
);

final getGenreStatsUseCaseProvider = Provider<GetGenreStatsUseCase>(
  (ref) => GetGenreStatsUseCase(ref.watch(profileStatsRepositoryProvider)),
);

final getAuthorStatsUseCaseProvider = Provider<GetAuthorStatsUseCase>(
  (ref) => GetAuthorStatsUseCase(ref.watch(profileStatsRepositoryProvider)),
);

final getRatingStatsUseCaseProvider = Provider<GetRatingStatsUseCase>(
  (ref) => GetRatingStatsUseCase(ref.watch(profileStatsRepositoryProvider)),
);

final getLibraryStatsUseCaseProvider = Provider<GetLibraryStatsUseCase>(
  (ref) => GetLibraryStatsUseCase(ref.watch(profileStatsRepositoryProvider)),
);

final getContentStatsUseCaseProvider = Provider<GetContentStatsUseCase>(
  (ref) => GetContentStatsUseCase(ref.watch(profileStatsRepositoryProvider)),
);

/// Profile strip only: Supabase counts + Google Books metadata for top genre.
final profileStatsSummaryProvider =
    FutureProvider<ProfileStatsSummary>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) {
    return const ProfileStatsSummary(
      completedBooks: 0,
      averageRating: 0,
      topGenre: '—',
    );
  }
  return ref.read(getProfileStatsSummaryUseCaseProvider).call();
});

/// Full stats page: shares completed-book metadata with [authorStatsProvider].
final genreStatsProvider = FutureProvider<List<GenreStat>>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return const <GenreStat>[];
  return ref.read(getGenreStatsUseCaseProvider).call();
});

final authorStatsProvider = FutureProvider<List<AuthorStat>>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return const <AuthorStat>[];
  return ref.read(getAuthorStatsUseCaseProvider).call();
});

final ratingStatsProvider = FutureProvider<RatingStat>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) {
    return const RatingStat(averageRating: 0, distribution: <int, int>{});
  }
  return ref.read(getRatingStatsUseCaseProvider).call();
});

final libraryStatsProvider = FutureProvider<LibraryStat>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) {
    return const LibraryStat(
      toRead: 0,
      reading: 0,
      completed: 0,
      dropped: 0,
      favorites: 0,
    );
  }
  return ref.read(getLibraryStatsUseCaseProvider).call();
});

final contentStatsProvider = FutureProvider<ContentStat>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) {
    return const ContentStat(reviewCount: 0, quoteCount: 0);
  }
  return ref.read(getContentStatsUseCaseProvider).call();
});
