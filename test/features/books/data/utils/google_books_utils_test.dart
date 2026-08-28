import 'package:bookapp/features/books/data/models/book_model.dart';
import 'package:bookapp/features/books/data/utils/google_books_utils.dart';
import 'package:flutter_test/flutter_test.dart';

BookModel _book({
  required String workId,
  required String title,
  String author = 'Unknown',
  String? isbn13,
  double? averageRating,
  int? ratingsCount,
  String? coverImageUrl,
  String description = '',
}) {
  return BookModel(
    workId: workId,
    title: title,
    primaryAuthorName: author,
    authorKeys: <String>['g:${Uri.encodeComponent(author)}'],
    description: description,
    subjects: const <String>[],
    isbn13: isbn13,
    averageRating: averageRating,
    ratingsCount: ratingsCount,
    coverImageUrl: coverImageUrl,
  );
}

void main() {
  group('normalizeSearchText / textSimilarity — Turkish fold', () {
    test('diacritic and non-diacritic spellings compare equal', () {
      expect(
        GoogleBooksUtils.normalizeSearchText('Sokağın Ortasında'),
        GoogleBooksUtils.normalizeSearchText('sokagin ortasinda'),
      );
    });

    test('İstanbul vs istanbul is an exact match', () {
      expect(
        GoogleBooksUtils.textSimilarity('İstanbul', 'istanbul'),
        1.0,
      );
    });

    test('dotless ı folds the same as dotted İ/I', () {
      expect(
        GoogleBooksUtils.normalizeSearchText('Kırık Kalpler'),
        GoogleBooksUtils.normalizeSearchText('kirik kalpler'),
      );
    });
  });

  group('filterByMinRelevance', () {
    test('drops a popular but textually unrelated result', () {
      final relevant = _book(
        workId: '1',
        title: 'Suç ve Ceza',
        author: 'Dostoyevski',
      );
      final popularNoise = _book(
        workId: '2',
        title: 'Completely Unrelated Bestseller',
        author: 'Someone Else',
        isbn13: '9780000000002',
        coverImageUrl: 'https://example.com/cover.jpg',
        description: 'A very popular book',
        averageRating: 4.9,
        ratingsCount: 100000,
      );

      final filtered = GoogleBooksUtils.filterByMinRelevance(
        <BookModel>[relevant, popularNoise],
        'suç ve ceza',
      );

      expect(filtered.map((b) => b.workId), <String>['1']);
    });

    test('falls back to the original list when everything is filtered out', () {
      final books = <BookModel>[
        _book(workId: '1', title: 'Alpha'),
        _book(workId: '2', title: 'Beta'),
      ];

      final filtered = GoogleBooksUtils.filterByMinRelevance(books, 'zzz not matching anything');

      expect(filtered, books);
    });

    test('empty query returns the list unchanged', () {
      final books = <BookModel>[_book(workId: '1', title: 'Alpha')];
      expect(GoogleBooksUtils.filterByMinRelevance(books, '   '), books);
    });
  });

  group('deduplicate', () {
    test('merges Turkish casing variants of the same title/author', () {
      final books = <BookModel>[
        _book(workId: '1', title: 'Sokağın Ortasında', author: 'Yazar Adı'),
        _book(workId: '2', title: 'sokagin ortasinda', author: 'yazar adi'),
      ];

      final deduped = GoogleBooksUtils.deduplicate(books);

      expect(deduped, hasLength(1));
      expect(deduped.first.workId, '1');
    });

    test('keeps distinct ISBN-13 editions apart', () {
      final books = <BookModel>[
        _book(workId: '1', title: 'A', isbn13: '9780000000001'),
        _book(workId: '2', title: 'A', isbn13: '9780000000002'),
      ];

      expect(GoogleBooksUtils.deduplicate(books), hasLength(2));
    });
  });

  group('buildUnifiedSearchQueries / buildPlainSearchQuery', () {
    test('ISBN-13 digit input becomes a single isbn: query', () {
      expect(
        GoogleBooksUtils.buildUnifiedSearchQueries('9789750718533'),
        <String>['isbn:9789750718533'],
      );
    });

    test('ISBN-10 digit input with dashes becomes a single isbn: query', () {
      expect(
        GoogleBooksUtils.buildUnifiedSearchQueries('975-071-853-3'),
        <String>['isbn:9750718533'],
      );
    });

    test('single-word input is unquoted in both field queries', () {
      expect(
        GoogleBooksUtils.buildUnifiedSearchQueries('Dune'),
        <String>['intitle:Dune', 'inauthor:Dune'],
      );
    });

    test('multi-word input is quoted in both field queries', () {
      expect(
        GoogleBooksUtils.buildUnifiedSearchQueries('yüzüklerin efendisi'),
        <String>[
          'intitle:"yüzüklerin efendisi"',
          'inauthor:"yüzüklerin efendisi"',
        ],
      );
    });

    test('combined title+author input builds a quoted plain fallback query', () {
      expect(
        GoogleBooksUtils.buildPlainSearchQuery('suç ve ceza dostoyevski'),
        '"suç ve ceza dostoyevski"',
      );
    });

    test('single-word plain fallback query is unquoted', () {
      expect(GoogleBooksUtils.buildPlainSearchQuery('Dune'), 'Dune');
    });

    test('empty input yields no queries', () {
      expect(GoogleBooksUtils.buildUnifiedSearchQueries('   '), isEmpty);
      expect(GoogleBooksUtils.buildPlainSearchQuery('   '), '');
    });
  });

  group('cache key versioning', () {
    test('searchCacheKey uses the current version prefix', () {
      expect(
        GoogleBooksUtils.searchCacheKey(
          query: 'Dune',
          lang: 'tr',
          page: 1,
          limit: 20,
        ),
        'search|v4|dune|tr|1|20',
      );
    });

    test('authorCacheKey uses the current version prefix', () {
      expect(
        GoogleBooksUtils.authorCacheKey(
          authorName: 'Frank Herbert',
          lang: 'en',
          limit: 20,
        ),
        'author|v3|frank herbert|en|20',
      );
    });
  });
}
