import 'package:bookapp/features/trbooks/data/repositories/supabase_trbooks_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseTrbooksRepository.mapRowToBook', () {
    test('prefers isbn for the namespaced id when present', () {
      final book = SupabaseTrbooksRepository.mapRowToBook(<String, dynamic>{
        'id': 'row-uuid',
        'title': 'Simyacı',
        'author': 'Paulo Coelho',
        'category': 'literature',
        'description': 'Bir çobanın hazine arayışı.',
        'image_url': 'https://example.com/cover.jpg',
        'isbn': '9789750738623',
      });

      expect(book.id, 'trbooks:9789750738623');
      expect(book.title, 'Simyacı');
      expect(book.author, 'Paulo Coelho');
      expect(book.coverImageUrl, 'https://example.com/cover.jpg');
      expect(book.description, 'Bir çobanın hazine arayışı.');
      expect(book.subjectKeys, ['literature']);
      expect(book.authorIds, ['tr:Paulo%20Coelho']);
    });

    test('falls back to row id when isbn is missing or blank', () {
      final book = SupabaseTrbooksRepository.mapRowToBook(<String, dynamic>{
        'id': 'row-uuid',
        'title': 'Bilinmeyen',
        'author': 'Bilinmeyen Yazar',
        'category': null,
        'description': null,
        'image_url': null,
        'isbn': '',
      });

      expect(book.id, 'trbooks:row-uuid');
      expect(book.description, '');
      expect(book.subjectKeys, isEmpty);
    });
  });
}
