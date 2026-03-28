import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/book_repository.dart';
import '../../domain/entities/book.dart';
import 'books_providers.dart';

class BookSearchState {
  const BookSearchState({
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

  /// Last query that was sent to the API (trimmed, min length enforced by notifier).
  final String activeQuery;

  BookSearchState copyWith({
    List<Book>? items,
    bool? loadingFirstPage,
    bool? loadingMore,
    bool? hasMore,
    String? errorMessage,
    String? activeQuery,
    bool clearError = false,
  }) {
    return BookSearchState(
      items: items ?? this.items,
      loadingFirstPage: loadingFirstPage ?? this.loadingFirstPage,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeQuery: activeQuery ?? this.activeQuery,
    );
  }
}

class BookSearchNotifier extends StateNotifier<BookSearchState> {
  BookSearchNotifier(this._repository) : super(const BookSearchState());

  final BookRepository _repository;
  int _page = 1;

  /// Clears results (trending shows when query is short).
  void clear() {
    _page = 1;
    state = const BookSearchState();
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

final bookSearchNotifierProvider =
    StateNotifierProvider<BookSearchNotifier, BookSearchState>((ref) {
  return BookSearchNotifier(ref.watch(bookRepositoryProvider));
});
