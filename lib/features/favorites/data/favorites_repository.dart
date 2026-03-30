import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

class FavoritesException implements Exception {
  FavoritesException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Favorites table access — always scoped by authenticated user (RLS on server).
class FavoritesRepository {
  FavoritesRepository();

  SupabaseClient get _client => SupabaseService.client;

  Future<void> addFavorite(String bookId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw FavoritesException('Sign in to add favorites.');
    }
    await _client.from('user_books').upsert(
      <String, dynamic>{
        'user_id': userId,
        'book_id': bookId,
        'status': 'to_read',
        'is_favorite': true,
      },
      onConflict: 'user_id,book_id',
    );
  }

  Future<void> removeFavorite(String bookId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw FavoritesException('Sign in to manage favorites.');
    }
    await _client
        .from('user_books')
        .update(<String, dynamic>{'is_favorite': false})
        .eq('user_id', userId)
        .eq('book_id', bookId);
  }

  Future<List<String>> listFavoriteBookIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return <String>[];
    final rows = await _client
        .from('user_books')
        .select('book_id')
        .eq('user_id', userId)
        .eq('is_favorite', true)
        .order('updated_at', ascending: false);
    final list = rows as List<dynamic>;
    return list
        .map((e) => (e as Map<String, dynamic>)['book_id'] as String)
        .toList();
  }
}
