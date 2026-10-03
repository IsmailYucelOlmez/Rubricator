import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../data/datasources/semantic_api_datasource.dart';
import '../../data/datasources/semantic_feedback_remote_datasource.dart';
import '../../data/datasources/semantic_search_log_remote_datasource.dart';
import '../../data/repositories/semantic_discovery_repository_impl.dart';
import '../../data/repositories/semantic_feedback_repository_impl.dart';
import '../../data/repositories/semantic_search_log_repository_impl.dart';
import '../../domain/entities/semantic_book_result.dart';
import '../../domain/entities/semantic_feedback.dart';
import '../../domain/entities/semantic_search_request.dart';
import '../../domain/repositories/semantic_discovery_repository.dart';
import '../../domain/repositories/semantic_feedback_repository.dart';
import '../../domain/repositories/semantic_search_log_repository.dart';
import '../../domain/usecases/log_semantic_search_usecase.dart';
import '../../domain/usecases/search_semantic_books_usecase.dart';

final semanticApiDataSourceProvider = Provider<SemanticApiDataSource>(
  (ref) => SemanticApiDataSource(),
);

final _semanticSearchLogRemoteProvider =
    Provider<SemanticSearchLogRemoteDataSource>(
      (ref) => SemanticSearchLogRemoteDataSource(Supabase.instance.client),
    );

final semanticSearchLogRepositoryProvider =
    Provider<SemanticSearchLogRepository>(
      (ref) => SemanticSearchLogRepositoryImpl(
        ref.watch(_semanticSearchLogRemoteProvider),
      ),
    );

final semanticDiscoveryRepositoryProvider =
    Provider<SemanticDiscoveryRepository>(
      (ref) => SemanticDiscoveryRepositoryImpl(
        ref.watch(semanticApiDataSourceProvider),
      ),
    );

final logSemanticSearchUseCaseProvider = Provider<LogSemanticSearchUseCase>(
  (ref) =>
      LogSemanticSearchUseCase(ref.watch(semanticSearchLogRepositoryProvider)),
);

final searchSemanticBooksUseCaseProvider = Provider<SearchSemanticBooksUseCase>(
  (ref) => SearchSemanticBooksUseCase(
    ref.watch(semanticDiscoveryRepositoryProvider),
    ref.watch(semanticSearchLogRepositoryProvider),
  ),
);

class SemanticSearchState {
  const SemanticSearchState({
    this.query = '',
    this.category = 'All',
    this.tone = 'All',
    this.mode = SemanticSearchMode.advanced,
  });

  final String query;
  final String category;
  final String tone;
  final SemanticSearchMode mode;

  SemanticSearchState copyWith({
    String? query,
    String? category,
    String? tone,
    SemanticSearchMode? mode,
  }) {
    return SemanticSearchState(
      query: query ?? this.query,
      category: category ?? this.category,
      tone: tone ?? this.tone,
      mode: mode ?? this.mode,
    );
  }
}

final semanticSearchFiltersProvider = StateProvider<SemanticSearchState>(
  (ref) => const SemanticSearchState(),
);

/// Relevant / irrelevant marks applied to a search, keyed by the query.
class SemanticSearchRefinement {
  const SemanticSearchRefinement({
    this.relevant = const [],
    this.irrelevant = const [],
  });

  /// Uses the most recent marks (map order) up to the API's per-side cap.
  factory SemanticSearchRefinement.fromVotes(
    Map<String, SemanticFeedbackVote> votes,
  ) {
    List<String> latest(SemanticFeedbackVote vote) {
      final isbns = [
        for (final entry in votes.entries)
          if (entry.value == vote) entry.key,
      ];
      const cap = SemanticSearchRequest.maxRefinementIsbns;
      return isbns.length <= cap ? isbns : isbns.sublist(isbns.length - cap);
    }

    return SemanticSearchRefinement(
      relevant: latest(SemanticFeedbackVote.relevant),
      irrelevant: latest(SemanticFeedbackVote.irrelevant),
    );
  }

  final List<String> relevant;
  final List<String> irrelevant;

  bool get isEmpty => relevant.isEmpty && irrelevant.isEmpty;

  bool sameAs(SemanticSearchRefinement? other) =>
      other != null &&
      _sameSet(relevant, other.relevant) &&
      _sameSet(irrelevant, other.irrelevant);

  static bool _sameSet(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);
}

/// Null = plain search. Setting it re-runs [semanticSearchResultsProvider].
final semanticSearchRefinementProvider =
    StateProvider.family<SemanticSearchRefinement?, String>(
      (ref, query) => null,
    );

final semanticSearchResultsProvider =
    FutureProvider.family<List<SemanticBookResult>, String>((ref, query) async {
      final trimmed = query.trim();
      if (trimmed.length < 3) return const [];

      final filters = ref.watch(semanticSearchFiltersProvider);
      final languageCode = ref.watch(localeProvider).languageCode;
      final refinement = ref.watch(semanticSearchRefinementProvider(trimmed));
      return ref
          .read(searchSemanticBooksUseCaseProvider)
          .call(
            SemanticSearchRequest(
              query: trimmed,
              mode: filters.mode,
              category: filters.category,
              tone: filters.tone,
              language: languageCode,
              relevantIsbns: refinement?.relevant ?? const [],
              irrelevantIsbns: refinement?.irrelevant ?? const [],
            ),
          );
    });

final semanticFeedbackRepositoryProvider = Provider<SemanticFeedbackRepository>(
  (ref) => SemanticFeedbackRepositoryImpl(
    SemanticFeedbackRemoteDataSource(Supabase.instance.client),
  ),
);

/// The signed-in user's relevance votes for one (query, language), keyed by
/// ISBN in the order they were cast (most recent last). Loading fails open.
class SemanticFeedbackVotesNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<
          Map<String, SemanticFeedbackVote>,
          SemanticFeedbackKey
        > {
  final _pending = <String>{};

  @override
  Future<Map<String, SemanticFeedbackVote>> build(
    SemanticFeedbackKey key,
  ) async {
    if (ref.watch(currentUserIdProvider) == null) return const {};
    try {
      return await ref
          .watch(semanticFeedbackRepositoryProvider)
          .fetchMyVotes(key);
    } catch (error) {
      AppLogger.warning('semantic', 'Loading feedback votes failed: $error');
      return const {};
    }
  }

  /// Casts [vote] for [isbn13], or removes it when it is already the user's
  /// vote. Optimistic; reverted and rethrown when the RPC fails.
  Future<void> toggle(
    String isbn13,
    SemanticFeedbackVote vote, {
    int? resultPosition,
    double? similarity,
    String? mode,
    String? category,
    String? tone,
  }) async {
    if (_pending.contains(isbn13)) return;
    final previous = state.valueOrNull?[isbn13];
    final next = previous == vote ? null : vote;
    _set(isbn13, next);
    _pending.add(isbn13);
    try {
      await ref
          .read(semanticFeedbackRepositoryProvider)
          .submitVote(
            key: arg,
            isbn13: isbn13,
            vote: next,
            resultPosition: resultPosition,
            similarity: similarity,
            mode: mode,
            category: category,
            tone: tone,
          );
    } catch (_) {
      _set(isbn13, previous);
      rethrow;
    } finally {
      _pending.remove(isbn13);
    }
  }

  void _set(String isbn13, SemanticFeedbackVote? vote) {
    final votes = Map.of(
      state.valueOrNull ?? const <String, SemanticFeedbackVote>{},
    )..remove(isbn13);
    if (vote != null) votes[isbn13] = vote;
    state = AsyncData(votes);
  }
}

final semanticFeedbackVotesProvider = AsyncNotifierProvider.autoDispose
    .family<
      SemanticFeedbackVotesNotifier,
      Map<String, SemanticFeedbackVote>,
      SemanticFeedbackKey
    >(SemanticFeedbackVotesNotifier.new);
