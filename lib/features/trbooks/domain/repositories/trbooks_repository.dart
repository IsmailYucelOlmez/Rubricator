import '../../../books/domain/entities/book.dart';

abstract class TrbooksRepository {
  Future<List<Book>> searchTrbooks(String query, {int limit = 20});

  /// Highest rated/most-reviewed catalog entries, for use as a Turkish
  /// "popular books" substitute where Google Books trending is normally shown.
  Future<List<Book>> popularTrbooks({int limit = 20});

  /// Looks up a single row by a `trbooks:`-prefixed [id] (or the bare
  /// isbn/row-uuid). Returns `null` when nothing matches.
  Future<Book?> getById(String id);

  /// Books by an exact (case-insensitive) author name match.
  Future<List<Book>> byAuthor(String authorName, {int limit = 20});

  /// Same-category (or same-author, when no category) books, excluding
  /// [excludeId], for use as a Google-Books "related books" substitute.
  Future<List<Book>> related({
    required String excludeId,
    String? category,
    required String author,
    int limit = 10,
  });

  /// Broad title/description keyword match (e.g. a genre word like "korku"),
  /// ranked by rating/reviews_count rather than text similarity, for use as
  /// a Google-Books genre-browse substitute.
  Future<List<Book>> byKeyword(String keyword, {int limit = 20});
}
