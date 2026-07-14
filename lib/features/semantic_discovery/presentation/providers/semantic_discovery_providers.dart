import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/semantic_api_datasource.dart';
import '../../data/datasources/semantic_search_log_remote_datasource.dart';
import '../../data/repositories/semantic_discovery_repository_impl.dart';
import '../../data/repositories/semantic_search_log_repository_impl.dart';
import '../../domain/entities/semantic_book_result.dart';
import '../../domain/entities/semantic_search_request.dart';
import '../../domain/repositories/semantic_discovery_repository.dart';
import '../../domain/repositories/semantic_search_log_repository.dart';
import '../../domain/usecases/log_semantic_search_usecase.dart';
import '../../domain/usecases/search_semantic_books_usecase.dart';

final semanticApiDataSourceProvider = Provider<SemanticApiDataSource>(
  (ref) => SemanticApiDataSource(),
);

final _semanticSearchLogRemoteProvider = Provider<SemanticSearchLogRemoteDataSource>(
  (ref) => SemanticSearchLogRemoteDataSource(Supabase.instance.client),
);

final semanticSearchLogRepositoryProvider = Provider<SemanticSearchLogRepository>(
  (ref) => SemanticSearchLogRepositoryImpl(
    ref.watch(_semanticSearchLogRemoteProvider),
  ),
);

final semanticDiscoveryRepositoryProvider = Provider<SemanticDiscoveryRepository>(
  (ref) => SemanticDiscoveryRepositoryImpl(
    ref.watch(semanticApiDataSourceProvider),
  ),
);

final logSemanticSearchUseCaseProvider = Provider<LogSemanticSearchUseCase>(
  (ref) => LogSemanticSearchUseCase(ref.watch(semanticSearchLogRepositoryProvider)),
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
    this.mode = SemanticSearchMode.simple,
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

final semanticSearchFiltersProvider =
    StateProvider<SemanticSearchState>((ref) => const SemanticSearchState());

final semanticSearchResultsProvider =
    FutureProvider.family<List<SemanticBookResult>, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.length < 3) return const [];

  final filters = ref.watch(semanticSearchFiltersProvider);
  return ref.read(searchSemanticBooksUseCaseProvider).call(
        SemanticSearchRequest(
          query: trimmed,
          mode: filters.mode,
          category: filters.category,
          tone: filters.tone,
        ),
      );
});
