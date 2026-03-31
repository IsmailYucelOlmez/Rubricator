import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../domain/entities/user_book_entity.dart';

class UserBooksException implements Exception {
  UserBooksException(this.message);
  final String message;

  @override
  String toString() => message;
}

class UserBooksRepository {
  SupabaseClient get _client => SupabaseService.client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw UserBooksException('Sign in to manage your reading list.');
    }
    return userId;
  }

  Future<UserBookEntity?> getUserBook(String bookId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('user_books')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .maybeSingle();
    if (row == null) return null;
    return UserBookEntity.fromMap(row);
  }

  Future<void> upsertUserBook({
    required String bookId,
    required ReadingStatus status,
    bool? isFavorite,
    int? progress,
  }) async {
    final userId = _requireUserId();
    if (progress != null && (progress < 0 || progress > 100)) {
      throw UserBooksException('Progress must be between 0 and 100.');
    }
    if (progress != null && status != ReadingStatus.reading) {
      throw UserBooksException('Progress is only available while reading.');
    }

    await _client.from('user_books').upsert(
      <String, dynamic>{
        'user_id': userId,
        'book_id': bookId,
        'status': readingStatusToDb(status),
        ...?(isFavorite != null
            ? <String, dynamic>{'is_favorite': isFavorite}
            : null),
        'progress': status == ReadingStatus.reading ? progress : null,
      },
      onConflict: 'user_id,book_id',
    );
  }

  Future<void> toggleFavorite(String bookId) async {
    final userId = _requireUserId();
    final existing = await getUserBook(bookId);
    if (existing == null) {
      await _client.from('user_books').insert(<String, dynamic>{
        'user_id': userId,
        'book_id': bookId,
        'status': readingStatusToDb(ReadingStatus.toRead),
        'is_favorite': true,
      });
      return;
    }

    await _client
        .from('user_books')
        .update(<String, dynamic>{'is_favorite': !existing.isFavorite})
        .eq('id', existing.id);
  }

  Future<List<UserBookEntity>> getUserBooksByStatus(ReadingStatus status) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const <UserBookEntity>[];

    final rows = await _client
        .from('user_books')
        .select()
        .eq('user_id', userId)
        .eq('status', readingStatusToDb(status))
        .order('updated_at', ascending: false);
    final list = rows as List<dynamic>;
    return list
        .map((e) => UserBookEntity.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserBookEntity>> getFavoriteUserBooks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const <UserBookEntity>[];

    final rows = await _client
        .from('user_books')
        .select()
        .eq('user_id', userId)
        .eq('is_favorite', true)
        .order('updated_at', ascending: false);
    final list = rows as List<dynamic>;
    return list
        .map((e) => UserBookEntity.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
