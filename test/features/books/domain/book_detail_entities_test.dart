import 'package:bookapp/features/books/domain/entities/book_detail_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bookStoreFromUrl', () {
    test('detects D&R and kitapyurdu product pages', () {
      expect(
        bookStoreFromUrl('https://www.dr.com.tr/kitap/abc/123'),
        BookStore.dr,
      );
      expect(
        bookStoreFromUrl('https://www.kitapyurdu.com/kitap/abc/123.html'),
        BookStore.kitapyurdu,
      );
    });

    test('returns null for missing or unknown hosts', () {
      expect(bookStoreFromUrl(null), isNull);
      expect(bookStoreFromUrl('not a url'), isNull);
      expect(bookStoreFromUrl('https://example.com/book'), isNull);
    });
  });
}
