import 'package:supabase_flutter/supabase_flutter.dart';

class SearchRemoteDataSource {
  SearchRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<void> logSearch({required String query, String? bookId}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    await _client.from('search_logs').insert({
      'user_id': _client.auth.currentUser?.id,
      'query': trimmed,
      'book_id': bookId?.trim().isEmpty == true ? null : bookId?.trim(),
    });
  }

  Future<List<String>> fetchPopularQueries({int limit = 10}) async {
    final rows = await _client.rpc(
      'search_logs_popular_queries',
      params: <String, dynamic>{'p_limit': limit},
    );
    final list = rows as List<dynamic>? ?? <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map((row) => (row['query'] as String?)?.trim() ?? '')
        .where((q) => q.isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchPopularBookIds({int limit = 10}) async {
    final rows = await _client.rpc(
      'search_logs_popular_book_ids',
      params: <String, dynamic>{'p_limit': limit},
    );
    final list = rows as List<dynamic>? ?? <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map((row) => (row['book_id'] as String?)?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchSearchHistoryForUser({
    int limit = 20,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return <Map<String, dynamic>>[];
    final rows = await _client
        .from('search_logs')
        .select('id,user_id,query,book_id,created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().toList();
  }
}
