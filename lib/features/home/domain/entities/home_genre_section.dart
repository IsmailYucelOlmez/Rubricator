import 'home_book_entity.dart';

/// How a single home-screen genre rail resolved (books + UX state).
enum HomeGenreSectionLoadState {
  /// Data Source returned books or a usable cached list.
  ready,

  /// Fetches exhausted or remote returned nothing after retries ([books] empty).
  error,

  /// No cache yet and fetching is not allowed today (schedule / backoff).
  emptyUnavailable,
}

class HomeGenreSection {
  const HomeGenreSection({
    required this.books,
    required this.loadState,
  });

  final List<HomeBookEntity> books;
  final HomeGenreSectionLoadState loadState;
}
