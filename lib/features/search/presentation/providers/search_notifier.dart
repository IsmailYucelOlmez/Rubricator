import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/data/repositories/book_repository.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/providers/books_providers.dart';

class SearchState {
  const SearchState({
    this.items = const [],
    this.loadingFirstPage = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.activeQuery = '',
  });

  final List<Book> items;
  final bool loadingFirstPage;
  final bool loadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String activeQuery;

  SearchState copyWith({
    List<Book>? items,
    bool? loadingFirstPage,
    bool? loadingMore,
    bool? hasMore,
    String? errorMessage,
    String? activeQuery,
    bool clearError = false,
  }) {
    return SearchState(
      items: items ?? this.items,
      loadingFirstPage: loadingFirstPage ?? this.loadingFirstPage,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeQuery: activeQuery ?? this.activeQuery,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._repository) : super(const SearchState());

  final BookRepository _repository;
  int _page = 1;

  void clear() {
    _page = 1;
    state = const SearchState();
  }

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      clear();
      return;
    }
    _page = 1;
    state = state.copyWith(
      loadingFirstPage: true,
      clearError: true,
      activeQuery: q,
      items: const [],
      hasMore: false,
    );
    try {
      final result = await _repository.searchBooks(query: q, page: 1);
      state = state.copyWith(
        items: result.books,
        hasMore: result.hasMore,
        loadingFirstPage: false,
      );
    } catch (e) {
      state = state.copyWith(
        loadingFirstPage: false,
        errorMessage: _friendlyMessage(e),
        items: const [],
        hasMore: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.loadingFirstPage || !state.hasMore) return;
    final q = state.activeQuery;
    if (q.length < 2) return;

    state = state.copyWith(loadingMore: true, clearError: true);
    final nextPage = _page + 1;
    try {
      final result = await _repository.searchBooks(query: q, page: nextPage);
      _page = nextPage;
      state = state.copyWith(
        items: [...state.items, ...result.books],
        hasMore: result.hasMore,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        loadingMore: false,
        errorMessage: _friendlyMessage(e),
      );
    }
  }

  static String _friendlyMessage(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    return 'Something went wrong. Check your connection and try again.';
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref.watch(bookRepositoryProvider)),
);
