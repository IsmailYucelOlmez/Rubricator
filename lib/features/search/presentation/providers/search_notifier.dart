import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../../trbooks/presentation/providers/trbooks_providers.dart';
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
    ref.watch(resolveBookByIdUseCaseProvider),
  );
});

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

List<Book> _deduplicateBooks(List<Book> books) {
  final seen = <String>{};
  return books.where((book) {
    final key = '${book.title.toLowerCase()}|${book.author.toLowerCase()}';
    return seen.add(key);
  }).toList();
}

class SearchPaginationState {
  const SearchPaginationState({
    required this.books,
    required this.hasMore,
    required this.isLoadingMore,
    required this.query,
  });

  final List<Book> books;
  final bool hasMore;
  final bool isLoadingMore;
  final String query;
}

final searchProvider =
    AsyncNotifierProvider.autoDispose<SearchPaginationNotifier, SearchPaginationState>(
      SearchPaginationNotifier.new,
    );

class SearchPaginationNotifier extends AutoDisposeAsyncNotifier<SearchPaginationState> {
  static const _trPageSize = 20;

  int _page = 1;
  // Which source the current query's pages come from; fixed per query.
  bool _useTrbooks = false;
  // Raw rows consumed from trbooks (pre-dedup), used as the RPC offset.
  int _trOffset = 0;

  @override
  Future<SearchPaginationState> build() async {
    _page = 1;
    _useTrbooks = false;
    _trOffset = 0;
    final query = ref.watch(searchQueryProvider).trim();
    if (query.length < 2) {
      return const SearchPaginationState(
        books: <Book>[],
        hasMore: false,
        isLoadingMore: false,
        query: '',
      );
    }
    final isTurkish = ref.watch(localeProvider).languageCode == 'tr';
    // Turkish locale: trbooks only; Google Books is queried solely as a
    // fallback when trbooks has no match (or fails).
    if (isTurkish) {
      final trbooks = await _searchTrbooks(query, offset: 0);
      if (trbooks.isNotEmpty) {
        _useTrbooks = true;
        _trOffset = trbooks.length > _trPageSize ? _trPageSize : trbooks.length;
        return SearchPaginationState(
          books: _deduplicateBooks(trbooks.take(_trPageSize).toList()),
          hasMore: trbooks.length > _trPageSize,
          isLoadingMore: false,
          query: query,
        );
      }
    }
    final result = await ref
        .read(bookRepositoryProvider)
        .searchBooks(query: query, page: 1);
    return SearchPaginationState(
      books: _deduplicateBooks(result.books),
      hasMore: result.hasMore,
      isLoadingMore: false,
      query: query,
    );
  }

  /// Fetches one extra row beyond [_trPageSize] so callers can tell whether
  /// another page exists without a separate count query.
  Future<List<Book>> _searchTrbooks(String query, {required int offset}) async {
    try {
      return await ref
          .read(searchTrbooksUseCaseProvider)
          .call(query, limit: _trPageSize + 1, offset: offset);
    } catch (_) {
      // Local Turkish catalog is a supplemental source; Google Books results
      // alone are still a valid search outcome if this fails.
      return const <Book>[];
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        current.isLoadingMore ||
        !current.hasMore ||
        current.query.length < 2) {
      return;
    }

    final nextPage = _page + 1;
    state = AsyncData(
      SearchPaginationState(
        books: current.books,
        hasMore: current.hasMore,
        isLoadingMore: true,
        query: current.query,
      ),
    );

    if (_useTrbooks) {
      try {
        final rows = await ref
            .read(searchTrbooksUseCaseProvider)
            .call(current.query, limit: _trPageSize + 1, offset: _trOffset);
        final pageRows = rows.take(_trPageSize).toList();
        _trOffset += pageRows.length;
        state = AsyncData(
          SearchPaginationState(
            books: _deduplicateBooks(<Book>[...current.books, ...pageRows]),
            hasMore: rows.length > _trPageSize,
            isLoadingMore: false,
            query: current.query,
          ),
        );
      } catch (e, stackTrace) {
        state = AsyncError(e, stackTrace);
      }
      return;
    }

    try {
      final result = await ref
          .read(bookRepositoryProvider)
          .searchBooks(query: current.query, page: nextPage);
      _page = nextPage;
      final merged = _deduplicateBooks(<Book>[...current.books, ...result.books]);
      state = AsyncData(
        SearchPaginationState(
          books: merged,
          hasMore: result.hasMore,
          isLoadingMore: false,
          query: current.query,
        ),
      );
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}

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
    _ref.invalidate(searchHistoryProvider);
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
    _ref.invalidate(searchHistoryProvider);
  }
}
