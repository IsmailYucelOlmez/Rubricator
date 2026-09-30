import 'home_book_entity.dart';
import 'home_genre_section.dart';

/// Home feed: popular rail + fixed genre sections.
///
/// May be partial while sections stream in: a null [popularBooks] or a genre
/// key missing from [genreSections] means that rail is still loading.
class HomePageSnapshot {
  const HomePageSnapshot({
    required this.popularBooks,
    required this.genreSections,
  });

  static const HomePageSnapshot empty = HomePageSnapshot(
    popularBooks: null,
    genreSections: <String, HomeGenreSection>{},
  );

  final List<HomeBookEntity>? popularBooks;
  final Map<String, HomeGenreSection> genreSections;

  bool isCompleteFor(List<String> genreKeys) =>
      popularBooks != null && genreKeys.every(genreSections.containsKey);

  bool get hasAnyBooks =>
      (popularBooks?.isNotEmpty ?? false) ||
      genreSections.values.any((s) => s.books.isNotEmpty);

  /// Rails loaded in [this] replace those in [base]; rails still loading
  /// here keep showing [base]'s (e.g. the on-disk copy) until they arrive.
  HomePageSnapshot overlaying(HomePageSnapshot base) {
    return HomePageSnapshot(
      popularBooks: popularBooks ?? base.popularBooks,
      genreSections: <String, HomeGenreSection>{
        ...base.genreSections,
        ...genreSections,
      },
    );
  }
}
