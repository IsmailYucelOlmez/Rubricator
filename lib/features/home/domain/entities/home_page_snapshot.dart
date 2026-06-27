import 'home_book_entity.dart';
import 'home_genre_section.dart';

/// Cached home feed: popular rail + fixed genre sections from one batch read.
class HomePageSnapshot {
  const HomePageSnapshot({
    required this.popularBooks,
    required this.genreSections,
  });

  final List<HomeBookEntity> popularBooks;
  final Map<String, HomeGenreSection> genreSections;
}
