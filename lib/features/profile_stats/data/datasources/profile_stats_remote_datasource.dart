import 'package:supabase_flutter/supabase_flutter.dart';

class CompletedUserBookRecord {
  const CompletedUserBookRecord({
    required this.bookId,
    this.bookTitle,
    this.bookAuthor,
    this.bookCategories = const [],
  });

  final String bookId;
  final String? bookTitle;
  final String? bookAuthor;
  final List<String> bookCategories;

  bool get hasSnapshot =>
      bookTitle != null &&
      bookTitle!.isNotEmpty &&
      bookAuthor != null &&
      bookAuthor!.isNotEmpty;
}

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

  Future<List<CompletedUserBookRecord>> fetchCompletedBooks(String userId) async {
    final rows = await _client
        .from('user_books')
        .select('book_id, book_title, book_author, book_categories')
        .eq('user_id', userId)
        .eq('status', 'completed')
        .order('completed_at', ascending: false)
        .order('updated_at', ascending: false);
    final list = rows as List<dynamic>;
    final seen = <String>{};
    final out = <CompletedUserBookRecord>[];
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['book_id'] as String?;
      if (id == null || id.isEmpty) continue;
      if (!seen.add(id)) continue;
      final categoriesRaw = e['book_categories'];
      final categories = categoriesRaw is List<dynamic>
          ? categoriesRaw.map((c) => c.toString()).where((s) => s.isNotEmpty).toList()
          : const <String>[];
      out.add(
        CompletedUserBookRecord(
          bookId: id,
          bookTitle: e['book_title'] as String?,
          bookAuthor: e['book_author'] as String?,
          bookCategories: categories,
        ),
      );
    }
    return out;
  }

  Future<List<String>> fetchCompletedBookIds(String userId) async {
    final rows = await fetchCompletedBooks(userId);
    return rows.map((e) => e.bookId).toList();
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
        .where((r) => r >= 1 && r <= 10)
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
