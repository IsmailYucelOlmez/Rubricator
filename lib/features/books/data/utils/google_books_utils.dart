import 'dart:math' as math;

import '../models/book_model.dart';

/// Shared Google Books API helpers ([xdocs/google_books_api.mdc]).
abstract final class GoogleBooksUtils {
  static const int defaultMaxResults = 40;

  static final RegExp _isbnDigits = RegExp(r'^\d{10}$|^\d{13}$');
  static final RegExp _nonAlnum = RegExp(r'[^\p{L}\p{N}\s]+', unicode: true);
  static final RegExp _multiSpace = RegExp(r'\s+');
  /// Legacy Open Library work (`…W`) / edition (`…M`) ids, e.g. `OL1064277W`.
  static final RegExp _openLibraryId = RegExp(
    r'^OL\d+[A-Za-z]$',
    caseSensitive: false,
  );

  /// Whether [raw] is safe to pass to Google Books `/volumes/{id}`.
  ///
  /// Rejects empty, `pending:` (ISBN resolve), and legacy Open Library ids that
  /// otherwise produce upstream 503 `backendFailed` noise.
  static bool isFetchableVolumeId(String raw) {
    final id = raw.trim();
    if (id.isEmpty) return false;
    if (id.startsWith('pending:')) return false;
    if (_openLibraryId.hasMatch(id)) return false;
    return true;
  }

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

  static String normalizeSearchText(String input) {
    return input
        .toLowerCase()
        .replaceAll(_nonAlnum, ' ')
        .replaceAll(_multiSpace, ' ')
        .trim();
  }

  /// Token Jaccard similarity in `[0, 1]`, with a contains boost.
  static double textSimilarity(String a, String b) {
    final left = normalizeSearchText(a);
    final right = normalizeSearchText(b);
    if (left.isEmpty || right.isEmpty) return 0;
    if (left == right) return 1;

    if (left.contains(right) || right.contains(left)) {
      final shorter = math.min(left.length, right.length);
      final longer = math.max(left.length, right.length);
      return 0.7 + 0.3 * (shorter / longer);
    }

    final leftTokens = left.split(' ').where((t) => t.isNotEmpty).toSet();
    final rightTokens = right.split(' ').where((t) => t.isNotEmpty).toSet();
    if (leftTokens.isEmpty || rightTokens.isEmpty) return 0;

    final intersection = leftTokens.intersection(rightTokens).length;
    final union = leftTokens.union(rightTokens).length;
    if (union == 0) return 0;
    return intersection / union;
  }

  /// Query match score: title/author exact + similarity.
  static double relevanceScore(BookModel book, String query) {
    final q = normalizeSearchText(query);
    if (q.isEmpty) return 0;

    final title = normalizeSearchText(book.title);
    final author = normalizeSearchText(book.primaryAuthorName);

    var score = 0.0;
    if (title == q) {
      score += 20;
    } else {
      score += 12 * textSimilarity(title, q);
    }

    if (author == q) {
      score += 15;
    } else {
      score += 8 * textSimilarity(author, q);
    }

    return score;
  }

  /// Metadata richness score. Rating contribution is `averageRating * ln(ratingsCount)`.
  static double qualityScore(BookModel book) {
    var score = 0.0;
    if (book.isbn13 != null) score += 3;
    if (book.coverImageUrl != null) score += 2;
    if (book.description.trim().isNotEmpty) score += 1;
    if (book.pageCount != null) score += 1;
    if (book.publishedYear != null) score += 1;

    final rating = book.averageRating;
    final count = book.ratingsCount;
    if (rating != null && count != null && count > 0) {
      score += rating * math.log(count);
    }
    return score;
  }

  static int compareByRelevanceThenQuality(
    BookModel a,
    BookModel b, {
    String? query,
  }) {
    if (query != null && query.trim().isNotEmpty) {
      final byRelevance = relevanceScore(
        b,
        query,
      ).compareTo(relevanceScore(a, query));
      if (byRelevance != 0) return byRelevance;
    }
    return qualityScore(b).compareTo(qualityScore(a));
  }

  static List<BookModel> sortByRelevanceThenQuality(
    List<BookModel> books, {
    String? query,
  }) {
    final copy = List<BookModel>.from(books);
    copy.sort((a, b) => compareByRelevanceThenQuality(a, b, query: query));
    return copy;
  }

  /// Deduplicate, then rank by relevance (when [query] given) and quality.
  static List<BookModel> postProcess(List<BookModel> books, {String? query}) {
    return sortByRelevanceThenQuality(deduplicate(books), query: query);
  }

  static String searchCacheKey({
    required String query,
    required String lang,
    required int page,
    required int limit,
  }) {
    return 'search|v3|${query.toLowerCase().trim()}|$lang|$page|$limit';
  }

  static String authorCacheKey({
    required String authorName,
    required String lang,
    required int limit,
  }) {
    return 'author|v2|${authorName.toLowerCase().trim()}|$lang|$limit';
  }
}
