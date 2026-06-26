import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_service.dart';
import '../domain/entities/user_book_entity.dart';
import '../domain/entities/user_book_snapshot.dart';

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
    UserBookSnapshot? snapshot,
  }) async {
    final userId = _requireUserId();
    if (progress != null && (progress < 0 || progress > 100)) {
      throw UserBooksException('Progress must be between 0 and 100.');
    }
    if (progress != null && status != ReadingStatus.reading) {
      throw UserBooksException('Progress is only available while reading.');
    }

    final payload = <String, dynamic>{
      'user_id': userId,
      'book_id': bookId,
      'status': readingStatusToDb(status),
      ...?(isFavorite != null
          ? <String, dynamic>{'is_favorite': isFavorite}
          : null),
    };

    if (status == ReadingStatus.reading) {
      if (progress != null) {
        payload['progress'] = progress;
      } else {
        final existing = await getUserBook(bookId);
        payload['progress'] = existing?.progress ?? 0;
      }
    } else {
      payload['progress'] = null;
    }

    if (snapshot != null) {
      payload['book_title'] = snapshot.title;
      payload['book_author'] = snapshot.author;
      payload['book_categories'] = snapshot.categories;
    }

    if (status == ReadingStatus.completed) {
      payload['completed_at'] = DateTime.now().toUtc().toIso8601String();
    } else {
      payload['completed_at'] = null;
    }

    await _client.from('user_books').upsert(
      payload,
      onConflict: 'user_id,book_id',
    );
  }

  Future<void> toggleFavorite(
    String bookId, {
    UserBookSnapshot? snapshot,
  }) async {
    final userId = _requireUserId();
    final existing = await getUserBook(bookId);
    if (existing == null) {
      final payload = <String, dynamic>{
        'user_id': userId,
        'book_id': bookId,
        'status': readingStatusToDb(ReadingStatus.toRead),
        'is_favorite': true,
      };
      if (snapshot != null) {
        payload['book_title'] = snapshot.title;
        payload['book_author'] = snapshot.author;
        payload['book_categories'] = snapshot.categories;
      }
      await _client.from('user_books').insert(payload);
      return;
    }

    final update = <String, dynamic>{'is_favorite': !existing.isFavorite};
    if (snapshot != null && !existing.hasCompletedSnapshot) {
      update['book_title'] = snapshot.title;
      update['book_author'] = snapshot.author;
      update['book_categories'] = snapshot.categories;
    }
    await _client
        .from('user_books')
        .update(update)
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

  Future<List<String>> getFavoriteBookIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const <String>[];

    final rows = await _client
        .from('user_books')
        .select('book_id')
        .eq('user_id', userId)
        .eq('is_favorite', true);
    final list = rows as List<dynamic>;
    return list
        .map((e) => (e as Map<String, dynamic>)['book_id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
