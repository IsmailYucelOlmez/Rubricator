import '../models/book_model.dart';

/// Shared Google Books API helpers ([xdocs/google_books_api.mdc]).
abstract final class GoogleBooksUtils {
  static const int defaultMaxResults = 40;

  static final RegExp _isbnDigits = RegExp(r'^\d{10}$|^\d{13}$');

  /// Base query params required on every `/volumes` list request.
  static Map<String, dynamic> baseListParams({
    required String lang,
    int maxResults = defaultMaxResults,
    String? orderBy,
    int? startIndex,
  }) {
    final params = <String, dynamic>{
      'printType': 'books',
      'langRestrict': lang,
      'maxResults': maxResults,
    };
    if (orderBy != null && orderBy.isNotEmpty) {
      params['orderBy'] = orderBy;
    }
    if (startIndex != null) {
      params['startIndex'] = startIndex;
    }
    return params;
  }

  /// Builds field-prefixed `q` values for a unified search box (title + author).
  /// ISBN-only input returns a single query; otherwise title and author run in parallel.
  static List<String> buildUnifiedSearchQueries(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const <String>[];

    final digits = trimmed.replaceAll(RegExp(r'[-\s]'), '');
    if (_isbnDigits.hasMatch(digits)) {
      return <String>['isbn:$digits'];
    }

    final term = trimmed.contains(' ') ? '"$trimmed"' : trimmed;
    return <String>['intitle:$term', 'inauthor:$term'];
  }

  /// Builds a field-prefixed `q` value — never bare free text.
  static String buildTitleSearchQuery(String raw) {
    final queries = buildUnifiedSearchQueries(raw);
    if (queries.isEmpty) return '';
    return queries.first;
  }

  static String buildAuthorSearchQuery(String authorName) {
    final name = authorName.trim().replaceAll('"', ' ');
    if (name.isEmpty) return '';
    return 'inauthor:"$name"';
  }

  static String buildSubjectSearchQuery(String subject) {
    final s = subject.trim().replaceAll('"', ' ');
    if (s.isEmpty) return '';
    return s.contains(' ') ? 'subject:"$s"' : 'subject:$s';
  }

  /// Removes duplicate editions (ISBN-13 preferred, else title + first author).
  static List<BookModel> deduplicate(List<BookModel> books) {
    final seen = <String>{};
    return books.where((book) {
      final key =
          book.isbn13 ??
          '${book.title.toLowerCase()}|'
              '${book.authorKeys.isNotEmpty ? Uri.decodeComponent(book.authorKeys.first.substring(2)).toLowerCase() : book.primaryAuthorName.toLowerCase()}';
      return seen.add(key);
    }).toList();
  }

  static int qualityScore(BookModel book) {
    var score = 0;
    if (book.isbn13 != null) score += 3;
    if (book.coverImageUrl != null) score += 2;
    if (book.pageCount != null) score += 1;
    if (book.averageRating != null) score += 1;
    if (book.publishedYear != null) score += 1;
    return score;
  }

  static List<BookModel> sortByQuality(List<BookModel> books) {
    final copy = List<BookModel>.from(books);
    copy.sort((a, b) => qualityScore(b).compareTo(qualityScore(a)));
    return copy;
  }

  static List<BookModel> postProcess(List<BookModel> books) {
    return sortByQuality(deduplicate(books));
  }

  static String searchCacheKey({
    required String query,
    required String lang,
    required int page,
    required int limit,
  }) {
    return 'search|v2|${query.toLowerCase().trim()}|$lang|$page|$limit';
  }

  static String authorCacheKey({
    required String authorName,
    required String lang,
    required int limit,
  }) {
    return 'author|${authorName.toLowerCase().trim()}|$lang|$limit';
  }
}
