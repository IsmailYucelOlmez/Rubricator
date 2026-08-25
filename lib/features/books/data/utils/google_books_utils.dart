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
  ///
  /// [restrictLanguage] can be set to `false` to drop `langRestrict` — used as
  /// a fallback when a language-restricted search returns too few results.
  static Map<String, dynamic> baseListParams({
    required String lang,
    int maxResults = defaultMaxResults,
    String? orderBy,
    int? startIndex,
    bool restrictLanguage = true,
  }) {
    final params = <String, dynamic>{
      'printType': 'books',
      'maxResults': maxResults,
    };
    if (restrictLanguage) {
      params['langRestrict'] = lang;
    }
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

  /// Field-unrestricted fallback query for combined title+author input (e.g.
  /// `"suç ve ceza dostoyevski"`) that `intitle:`/`inauthor:` alone can miss.
  static String buildPlainSearchQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.contains(' ') ? '"$trimmed"' : trimmed;
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
          '${normalizeSearchText(book.title)}|'
              '${book.authorKeys.isNotEmpty ? normalizeSearchText(Uri.decodeComponent(book.authorKeys.first.substring(2))) : normalizeSearchText(book.primaryAuthorName)}';
      return seen.add(key);
    }).toList();
  }

  /// Folds Turkish letters to their ASCII equivalents so diacritic and
  /// non-diacritic spellings (`"sokağın"` vs `"sokagin"`) compare equal.
  /// Only used for client-side comparison/dedup — never sent as `q=`.
  static String _foldTurkish(String input) {
    const from = 'İIıŞşĞğÇçÖöÜü';
    const to = 'iiissggccoouu';
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      final idx = from.indexOf(ch);
      buffer.write(idx >= 0 ? to[idx] : ch);
    }
    return buffer.toString();
  }

  static String normalizeSearchText(String input) {
    return _foldTurkish(input)
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

  /// Minimum [relevanceScore] a result must reach to survive [query]
  /// filtering. Below this, a book shares no meaningful title/author overlap
  /// with the query and is likely a popularity-ranked false positive.
  static const double minRelevanceScore = 1.5;

  /// Drops results with no meaningful relevance to [query]. If every result
  /// would be dropped, returns [books] unchanged rather than emptying it —
  /// a few weak matches are better than none.
  static List<BookModel> filterByMinRelevance(
    List<BookModel> books,
    String query, {
    double minScore = minRelevanceScore,
  }) {
    if (query.trim().isEmpty) return books;
    final filtered = books
        .where((b) => relevanceScore(b, query) >= minScore)
        .toList();
    return filtered.isEmpty ? books : filtered;
  }

  /// Deduplicate, filter out irrelevant noise (when [query] given), then rank
  /// by relevance and quality.
  static List<BookModel> postProcess(List<BookModel> books, {String? query}) {
    final deduped = deduplicate(books);
    final relevant = query != null && query.trim().isNotEmpty
        ? filterByMinRelevance(deduped, query)
        : deduped;
    return sortByRelevanceThenQuality(relevant, query: query);
  }

  static String searchCacheKey({
    required String query,
    required String lang,
    required int page,
    required int limit,
  }) {
    return 'search|v4|${query.toLowerCase().trim()}|$lang|$page|$limit';
  }

  static String authorCacheKey({
    required String authorName,
    required String lang,
    required int limit,
  }) {
    return 'author|v3|${authorName.toLowerCase().trim()}|$lang|$limit';
  }
}
