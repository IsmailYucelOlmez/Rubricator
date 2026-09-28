import 'package:bookapp/features/books/presentation/widgets/book_detail/book_detail_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ratingFromStarTap', () {
    test('left half of a star picks the half star', () {
      expect(ratingFromStarTap(index: 0, dx: 5, extent: 48), 1);
      expect(ratingFromStarTap(index: 2, dx: 23, extent: 48), 5);
    });

    test('right half (including the exact middle) picks the full star', () {
      expect(ratingFromStarTap(index: 0, dx: 24, extent: 48), 2);
      expect(ratingFromStarTap(index: 4, dx: 40, extent: 48), 10);
    });
  });

  test('starIconFor maps the 1-10 scale onto five half-able stars', () {
    final icons = [for (var i = 0; i < 5; i++) starIconFor(7, i)];
    expect(icons, [
      Icons.star,
      Icons.star,
      Icons.star,
      Icons.star_half,
      Icons.star_border,
    ]);
  });

  test('formatStarRating shows the 5-star value', () {
    expect(formatStarRating(7), '3.5');
    expect(formatStarRating(8.46), '4.2');
  });
}
