import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileStatsRemoteDataSource {
  ProfileStatsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<int> countUserBooks({
    required String userId,
    String? status,
    bool? isFavorite,
    List<String>? statusIn,
  }) async {
    var q = _client.from('user_books').select('id').eq('user_id', userId);
    if (statusIn != null && statusIn.isNotEmpty) {
      q = q.inFilter('status', statusIn);
    } else if (status != null) {
      q = q.eq('status', status);
    }
    if (isFavorite != null) {
      q = q.eq('is_favorite', isFavorite);
    }
    final res = await q.count(CountOption.exact);
    return res.count;
  }

  Future<List<String>> fetchCompletedBookIds(String userId) async {
    final rows = await _client
        .from('user_books')
        .select('book_id')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .order('updated_at', ascending: false);
    final list = rows as List<dynamic>;
    final seen = <String>{};
    final out = <String>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['book_id'] as String?;
      if (id == null || id.isEmpty) continue;
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  Future<List<int>> fetchUserRatings(String userId) async {
    final rows = await _client
        .from('ratings')
        .select('rating')
        .eq('user_id', userId);
    final list = rows as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => (e['rating'] as num?)?.toInt())
        .whereType<int>()
        .where((r) => r >= 1 && r <= 5)
        .toList();
  }

  Future<int> countReviews(String userId) async {
    final res = await _client
        .from('reviews')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
    return res.count;
  }

  Future<int> countQuotes(String userId) async {
    final res = await _client
        .from('quotes')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
    return res.count;
  }
}
