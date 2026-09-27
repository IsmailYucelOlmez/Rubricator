import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/i18n/fallback_strings.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../books/domain/entities/book.dart';
import '../../domain/repositories/trbooks_repository.dart';
import '../../domain/usecases/trbooks_submission_exceptions.dart';

const _trbooksSelectColumns =
    'id, title, author, category, description, image_url, isbn, source_url, source';

class SupabaseTrbooksRepository implements TrbooksRepository {
  SupabaseClient get _client => SupabaseService.client;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  Future<List<Book>> searchTrbooks(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <Book>[];
    final rows = await _client.rpc(
      'search_trbooks',
      params: <String, dynamic>{
        'p_query': trimmed,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapRowToBook)
        .toList();
  }

  @override
  Future<List<Book>> popularTrbooks({int limit = 20}) async {
    final rows = await _client
        .from('trbooks')
        .select(_trbooksSelectColumns)
        .not('rating', 'is', null)
        .order('rating', ascending: false)
        .order('reviews_count', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapRowToBook)
        .toList();
  }

  @override
  Future<Book?> getById(String id) async {
    final stripped = id.startsWith('trbooks:') ? id.substring(8) : id;
    if (stripped.isEmpty) return null;
    final rows = _uuidPattern.hasMatch(stripped)
        ? await _client
              .from('trbooks')
              .select(_trbooksSelectColumns)
              .eq('id', stripped)
              .limit(1)
        : await _client
              .from('trbooks')
              .select(_trbooksSelectColumns)
              .eq('isbn', stripped)
              .limit(1);
    final list = (rows as List<dynamic>).whereType<Map<String, dynamic>>();
    return list.isEmpty ? null : mapRowToBook(list.first);
  }

  @override
  Future<List<Book>> byAuthor(String authorName, {int limit = 20}) async {
    final trimmed = authorName.trim();
    if (trimmed.isEmpty) return const <Book>[];
    // Exact match: callers pass a name decoded straight back out of our own
    // `tr:`-encoded author id, so it's guaranteed to match a stored value
    // verbatim. `eq` uses the plain btree index on `author`; a wildcard-free
    // `ilike` does not (no functional index on `lower(author)`) and was
    // timing out as a full-table scan over 167k rows.
    final rows = await _client
        .from('trbooks')
        .select(_trbooksSelectColumns)
        .eq('author', trimmed)
        .order('rating', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapRowToBook)
        .toList();
  }

  @override
  Future<List<Book>> related({
    required String excludeId,
    String? category,
    required String author,
    int limit = 10,
  }) async {
    final trimmedCategory = category?.trim();
    final trimmedAuthor = author.trim();
    if ((trimmedCategory == null || trimmedCategory.isEmpty) &&
        trimmedAuthor.isEmpty) {
      return const <Book>[];
    }
    final rows = (trimmedCategory != null && trimmedCategory.isNotEmpty)
        ? await _client
              .from('trbooks')
              .select(_trbooksSelectColumns)
              .eq('category', trimmedCategory)
              .order('rating', ascending: false)
              .limit(limit + 1)
        : await _client
              .from('trbooks')
              .select(_trbooksSelectColumns)
              .eq('author', trimmedAuthor)
              .order('rating', ascending: false)
              .limit(limit + 1);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapRowToBook)
        .where((book) => book.id != excludeId)
        .take(limit)
        .toList();
  }

  @override
  Future<List<Book>> byKeyword(String keyword, {int limit = 20}) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const <Book>[];
    final rows = await _client.rpc(
      'search_trbooks_by_keyword',
      params: <String, dynamic>{'p_keyword': trimmed, 'p_limit': limit},
    );
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapRowToBook)
        .toList();
  }

  @override
  Future<List<Book>> byGenreKey(String genreKey, {int limit = 20}) async {
    final trimmed = genreKey.trim();
    if (trimmed.isEmpty) return const <Book>[];
    final rows = await _client.rpc(
      'search_trbooks_by_genre_key',
      params: <String, dynamic>{'p_genre_key': trimmed, 'p_limit': limit},
    );
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(mapRowToBook)
        .toList();
  }

  /// Namespaced with `trbooks:` so ids never collide with Google Books volume
  /// ids elsewhere in the app (book detail lookups assume a Google volume id).
  /// `authorIds` uses a parallel `tr:`-prefixed scheme (a plain encoded name,
  /// since trbooks has no author entity) so author-page navigation can branch
  /// on it the same way book ids branch on `trbooks:`.
  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Book mapRowToBook(Map<String, dynamic> row) {
    final isbn = (row['isbn'] as String?)?.trim();
    final rowId = row['id']?.toString() ?? '';
    final category = (row['category'] as String?)?.trim();
    final author = (row['author'] as String?)?.trim();
    return Book(
      id: 'trbooks:${(isbn != null && isbn.isNotEmpty) ? isbn : rowId}',
      title: (row['title'] as String?) ?? FallbackStrings.unknownTitle,
      author: author?.isNotEmpty == true ? author! : FallbackStrings.unknownAuthor,
      coverImageUrl: row['image_url'] as String?,
      description: (row['description'] as String?) ?? '',
      authorIds: author != null && author.isNotEmpty
          ? ['tr:${Uri.encodeComponent(author)}']
          : const [],
      subjectKeys: (category != null && category.isNotEmpty) ? [category] : const [],
      sourceUrl: _nonEmpty(row['source_url'] as String?),
      isUserSubmitted: row['source'] == 'user_submitted',
    );
  }

  @override
  Future<Book> submitUserBook({
    required String title,
    required String author,
    required String isbn,
    String? description,
    String? imageUrl,
    String? publisher,
    String? category,
    int? pageCount,
    int? releasedYear,
  }) async {
    try {
      final row = await _client.rpc(
        'submit_user_trbook',
        params: <String, dynamic>{
          'p_title': title,
          'p_author': author,
          'p_isbn': isbn,
          'p_description': description,
          'p_image_url': imageUrl,
          'p_publisher': publisher,
          'p_category': category,
          'p_page_count': pageCount,
          'p_released_year': releasedYear,
        },
      );
      return mapRowToBook(row as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      final duplicateMatch = RegExp(r'DUPLICATE_ISBN:(\S+)').firstMatch(e.message);
      if (duplicateMatch != null) {
        throw TrbooksDuplicateIsbnException('trbooks:${duplicateMatch.group(1)}');
      }
      if (e.message.toLowerCase().contains('not authenticated')) {
        throw Exception('Sign in required.');
      }
      rethrow;
    }
  }
}
