import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_log_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_usecases.dart';

final _searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>(
  (ref) => SearchRemoteDataSource(Supabase.instance.client),
);

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(
    ref.watch(bookRepositoryProvider),
    ref.watch(_searchRemoteDataSourceProvider),
  );
});

final _searchBooksUseCaseProvider = Provider<SearchBooksUseCase>(
  (ref) => SearchBooksUseCase(ref.watch(searchRepositoryProvider)),
);
final _logSearchUseCaseProvider = Provider<LogSearchUseCase>(
  (ref) => LogSearchUseCase(ref.watch(searchRepositoryProvider)),
);
final _getPopularSearchesUseCaseProvider = Provider<GetPopularSearchesUseCase>(
  (ref) => GetPopularSearchesUseCase(ref.watch(searchRepositoryProvider)),
);
final _getPopularBooksUseCaseProvider = Provider<GetPopularBooksUseCase>(
  (ref) => GetPopularBooksUseCase(ref.watch(searchRepositoryProvider)),
);
final _getSearchHistoryUseCaseProvider = Provider<GetSearchHistoryUseCase>(
  (ref) => GetSearchHistoryUseCase(ref.watch(searchRepositoryProvider)),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchProvider = FutureProvider.autoDispose<List<Book>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.length < 2) return const <Book>[];
  return ref.watch(_searchBooksUseCaseProvider).call(query);
});

final popularSearchProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(_getPopularSearchesUseCaseProvider).call();
});

final popularBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.watch(_getPopularBooksUseCaseProvider).call();
});

final searchHistoryProvider = FutureProvider<List<SearchLogEntity>>((ref) {
  return ref.watch(_getSearchHistoryUseCaseProvider).call(limit: 20);
});

final searchInteractionProvider = Provider<SearchInteractionController>(
  (ref) => SearchInteractionController(ref),
);

class SearchInteractionController {
  const SearchInteractionController(this._ref);

  final Ref _ref;
  static String _lastLoggedKey = '';

  Future<void> logSubmit(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    final dedupeKey = '$q|';
    if (_lastLoggedKey == dedupeKey) return;
    await _ref.read(_logSearchUseCaseProvider).call(query: q);
    _lastLoggedKey = dedupeKey;
    _ref.invalidate(popularSearchProvider);
  }

  Future<void> logBookClick({
    required String query,
    required String bookId,
  }) async {
    final q = query.trim();
    final b = bookId.trim();
    if (q.length < 2 || b.isEmpty) return;
    final dedupeKey = '$q|$b';
    if (_lastLoggedKey == dedupeKey) return;
    await _ref.read(_logSearchUseCaseProvider).call(query: q, bookId: b);
    _lastLoggedKey = dedupeKey;
    _ref.invalidate(popularBooksProvider);
    _ref.invalidate(popularSearchProvider);
  }
}
