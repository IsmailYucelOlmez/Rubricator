import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book_model.dart';

class GoogleBooksCacheDataSource {
  GoogleBooksCacheDataSource(this._client);

  final SupabaseClient _client;

  static const String _table = 'google_books_search_cache';
  static const Duration cacheTtl = Duration(hours: 24);

  Future<List<BookModel>?> getCachedBooks(String cacheKey) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('cache_key', cacheKey)
        .limit(1);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final lastFetchRaw = row['last_fetch_at'];
    if (lastFetchRaw is String) {
      final lastFetch = DateTime.tryParse(lastFetchRaw);
      if (lastFetch != null &&
          DateTime.now().difference(lastFetch.toUtc()) > cacheTtl) {
        return null;
      }
    }

    final booksJson = row['books_json'];
    if (booksJson is! List || booksJson.isEmpty) return null;

    return booksJson
        .whereType<Map<String, dynamic>>()
        .map(BookModel.fromCacheJson)
        .toList();
  }

  Future<void> saveBooks({
    required String cacheKey,
    required String cacheType,
    required List<BookModel> books,
  }) async {
    if (books.isEmpty) return;
    await _client.from(_table).upsert(<String, dynamic>{
      'cache_key': cacheKey,
      'cache_type': cacheType,
      'books_json': books.map((b) => b.toCacheJson()).toList(),
      'result_count': books.length,
      'last_fetch_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
