import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase_service.dart';
import '../../domain/entities/list_entities.dart';
import '../../domain/repositories/lists_repository.dart';

class SupabaseListsRepository implements ListsRepository {
  SupabaseClient get _client => SupabaseService.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<ListEntity>> getFeedLists() async {
    final userId = _currentUserId;
    var q = _client.from('lists').select('*');
    if (userId == null) {
      q = q.eq('is_public', true);
    } else {
      q = q.or('is_public.eq.true,user_id.eq.$userId');
    }
    final rows = await q.order('created_at', ascending: false).limit(50);
    final list = (rows as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    return Future.wait(list.map((row) => _enrichList(row, userId)));
  }

  @override
  Future<List<ListEntity>> getPopularLists() async {
    final lists = await getFeedLists();
    lists.sort((a, b) {
      final likeCmp = b.likeCount.compareTo(a.likeCount);
      if (likeCmp != 0) return likeCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return lists;
  }

  @override
  Future<List<ListEntity>> getTopListsByEngagement({int limit = 20}) async {
    final userId = _currentUserId;
    final raw = await _client.rpc(
      'list_top_by_engagement',
      params: <String, dynamic>{'p_limit': limit},
    );
    final rows = (raw as List<dynamic>?) ?? <dynamic>[];
    final ids = rows
        .whereType<Map<String, dynamic>>()
        .map((e) => e['list_id']?.toString())
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return const <ListEntity>[];

    final listRows = await _client.from('lists').select('*').inFilter('id', ids);
    final byId = <String, Map<String, dynamic>>{
      for (final row in (listRows as List<dynamic>).whereType<Map<String, dynamic>>())
        row['id'].toString(): row,
    };
    final ordered = <ListEntity>[];
    for (final id in ids) {
      final row = byId[id];
      if (row != null) {
        ordered.add(await _enrichList(row, userId));
      }
    }
    return ordered;
  }

  @override
  Future<List<ListEntity>> getFollowingLists() async {
    final userId = _currentUserId;
    if (userId == null) return getFeedLists();
    final savedRows = await _client
        .from('saved_lists')
        .select('list_id')
        .eq('user_id', userId);
    final savedListIds = (savedRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((e) => e['list_id']?.toString())
        .whereType<String>()
        .toList();
    if (savedListIds.isEmpty) return getFeedLists();

    final sourceRows = await _client.from('lists').select('user_id').inFilter('id', savedListIds);
    final creatorIds = (sourceRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((e) => e['user_id']?.toString())
        .whereType<String>()
        .where((id) => id != userId)
        .toSet()
        .toList();
    if (creatorIds.isEmpty) return getFeedLists();

    final rows = await _client
        .from('lists')
        .select('*')
        .inFilter('user_id', creatorIds)
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(50);
    final list = (rows as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    return Future.wait(list.map((row) => _enrichList(row, userId)));
  }

  @override
  Future<List<ListEntity>> getUserLists(String userId) async {
    final rows = await _client
        .from('lists')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final list = (rows as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    final currentUserId = _currentUserId;
    return Future.wait(list.map((row) => _enrichList(row, currentUserId)));
  }

  @override
  Future<List<ListEntity>> getSavedLists(String userId) async {
    final rows = await _client
        .from('saved_lists')
        .select('list_id')
        .eq('user_id', userId);
    final savedIds = (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((e) => e['list_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();
    if (savedIds.isEmpty) return const <ListEntity>[];

    final listRows = await _client.from('lists').select('*').inFilter('id', savedIds);
    final list = (listRows as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    final currentUserId = _currentUserId;
    final out = await Future.wait(list.map((row) => _enrichList(row, currentUserId)));
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  @override
  Future<ListItemEntity> addBookToList({
    required String listId,
    required String bookId,
    required String title,
    required String author,
    String? coverImageUrl,
  }) async {
    final rows = await _client
        .from('list_items')
        .select('order_index')
        .eq('list_id', listId)
        .order('order_index', ascending: false)
        .limit(1);
    final maxOrder = (rows as List<dynamic>).isEmpty
        ? -1
        : (((rows.first['order_index'] as num?)?.toInt()) ?? -1);
    final inserted = await _client
        .from('list_items')
        .insert(<String, dynamic>{
          'list_id': listId,
          'book_id': bookId,
          'book_title': title,
          'book_author': author,
          'cover_image_url': coverImageUrl,
          'order_index': maxOrder + 1,
          'note': null,
        })
        .select('*')
        .single();
    final row = inserted;
    return ListItemEntity(
      id: row['id'].toString(),
      listId: listId,
      bookId: row['book_id']?.toString() ?? bookId,
      bookTitle: (row['book_title'] as String?) ?? title,
      bookAuthor: (row['book_author'] as String?) ?? author,
      coverImageUrl: _nonEmptyUrl(row['cover_image_url'] as String?) ??
          coverImageUrl,
      orderIndex: (row['order_index'] as num?)?.toInt() ?? 0,
      note: row['note'] as String?,
    );
  }

  @override
  Future<void> reorderListItems({
    required String listId,
    required List<String> orderedItemIds,
  }) async {
    for (var i = 0; i < orderedItemIds.length; i++) {
      await _client
          .from('list_items')
          .update(<String, dynamic>{'order_index': i})
          .eq('id', orderedItemIds[i])
          .eq('list_id', listId);
    }
  }

  @override
  Future<void> removeBookFromList(String listItemId) async {
    await _client.from('list_items').delete().eq('id', listItemId);
  }

  @override
  Future<List<ListItemEntity>> getListItems(String listId) async {
    final rows = await _client
        .from('list_items')
        .select('*')
        .eq('list_id', listId)
        .order('order_index', ascending: true);
    final list = (rows as List<dynamic>).whereType<Map<String, dynamic>>();
    return list
        .map(
          (row) => ListItemEntity(
            id: row['id'].toString(),
            listId: row['list_id'].toString(),
            bookId: row['book_id']?.toString() ?? '',
            bookTitle: (row['book_title'] as String?) ?? (row['book_id']?.toString() ?? 'Unknown'),
            bookAuthor: (row['book_author'] as String?) ?? 'Unknown author',
            coverImageUrl: row['cover_image_url'] as String?,
            orderIndex: (row['order_index'] as num?)?.toInt() ?? 0,
            note: row['note'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<ListEntity> createList({
    required String userId,
    required String userName,
    required String title,
    required String description,
    required bool isPublic,
  }) async {
    final inserted = await _client
        .from('lists')
        .insert(<String, dynamic>{
          'user_id': userId,
          'title': title,
          'description': description,
          'is_public': isPublic,
        })
        .select('*')
        .single();
    return _enrichList(inserted, _currentUserId);
  }

  @override
  Future<void> updateList({
    required String listId,
    required String title,
    required String description,
    required bool isPublic,
  }) async {
    await _client
        .from('lists')
        .update(<String, dynamic>{
          'title': title,
          'description': description,
          'is_public': isPublic,
        })
        .eq('id', listId);
  }

  @override
  Future<void> deleteList(String listId) async {
    await _client.from('lists').delete().eq('id', listId);
  }

  @override
  Future<void> likeList(String userId, String listId) async {
    await _client.from('list_likes').upsert(
      <String, dynamic>{'user_id': userId, 'list_id': listId},
      onConflict: 'user_id,list_id',
    );
  }

  @override
  Future<void> unlikeList(String userId, String listId) async {
    await _client
        .from('list_likes')
        .delete()
        .eq('user_id', userId)
        .eq('list_id', listId);
  }

  @override
  Future<void> saveList(String userId, String listId) async {
    await _client.from('saved_lists').upsert(
      <String, dynamic>{'user_id': userId, 'list_id': listId},
      onConflict: 'user_id,list_id',
    );
  }

  @override
  Future<void> unsaveList(String userId, String listId) async {
    await _client
        .from('saved_lists')
        .delete()
        .eq('user_id', userId)
        .eq('list_id', listId);
  }

  @override
  Future<List<ListComment>> getComments(String listId) async {
    final rows = await _client
        .from('list_comments')
        .select('*')
        .eq('list_id', listId)
        .order('created_at', ascending: true);
    final list = (rows as List<dynamic>).whereType<Map<String, dynamic>>();
    return list
        .map(
          (row) => ListComment(
            id: row['id'].toString(),
            userId: row['user_id'].toString(),
            userName: (row['user_name'] as String?) ?? _fallbackUserName(row['user_id']?.toString()),
            listId: row['list_id'].toString(),
            content: row['content'] as String? ?? '',
            createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<void> addComment({
    required String userId,
    required String userName,
    required String listId,
    required String content,
  }) async {
    await _client.from('list_comments').insert(<String, dynamic>{
      'user_id': userId,
      'list_id': listId,
      'content': content,
    });
  }

  Future<ListEntity> _enrichList(Map<String, dynamic> row, String? viewerUserId) async {
    final listId = row['id'].toString();
    final userId = row['user_id'].toString();

    final likeCountRes = await _client
        .from('list_likes')
        .select('id')
        .eq('list_id', listId)
        .count(CountOption.exact);
    final commentCountRes = await _client
        .from('list_comments')
        .select('id')
        .eq('list_id', listId)
        .count(CountOption.exact);

    final previewRows = await _client
        .from('list_items')
        .select('*')
        .eq('list_id', listId)
        .order('order_index', ascending: true)
        .limit(4);
    final preview = (previewRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((e) => e['cover_image_url'] as String?)
        .toList();

    bool likedByMe = false;
    bool savedByMe = false;
    if (viewerUserId != null) {
      final likeRow = await _client
          .from('list_likes')
          .select('id')
          .eq('list_id', listId)
          .eq('user_id', viewerUserId)
          .maybeSingle();
      likedByMe = likeRow != null;
      final savedRow = await _client
          .from('saved_lists')
          .select('id')
          .eq('list_id', listId)
          .eq('user_id', viewerUserId)
          .maybeSingle();
      savedByMe = savedRow != null;
    }

    return ListEntity(
      id: listId,
      userId: userId,
      userName: (row['user_name'] as String?) ?? _fallbackUserName(userId),
      title: (row['title'] as String?) ?? 'Untitled list',
      description: (row['description'] as String?) ?? '',
      isPublic: (row['is_public'] as bool?) ?? true,
      likeCount: likeCountRes.count,
      commentCount: commentCountRes.count,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
      previewCoverImageUrls: preview,
      isLikedByMe: likedByMe,
      isSavedByMe: savedByMe,
    );
  }

  static String? _nonEmptyUrl(String? raw) {
    final s = raw?.trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  String _fallbackUserName(String? userId) {
    return 'user';
  }
}
