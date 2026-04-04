import 'package:supabase_flutter/supabase_flutter.dart';

class HabitRemoteDataSource {
  HabitRemoteDataSource(this._client);

  final SupabaseClient _client;

  String _todayLocalIsoDate() {
    final n = DateTime.now();
    final y = n.year.toString().padLeft(4, '0');
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatIsoDate(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> insertLog({
    required String userId,
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  }) async {
    await _client.from('reading_logs').insert(<String, dynamic>{
      'user_id': userId,
      'book_id': (bookId == null || bookId.trim().isEmpty) ? null : bookId.trim(),
      'date': _todayLocalIsoDate(),
      'minutes_read': minutesRead,
      'pages_read': pagesRead,
    });
  }

  Future<List<Map<String, dynamic>>> fetchLogsBetween({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _client
        .from('reading_logs')
        .select('id,user_id,book_id,date,minutes_read,pages_read,created_at')
        .eq('user_id', userId)
        .gte('date', _formatIsoDate(start))
        .lte('date', _formatIsoDate(end))
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>?> fetchUserSummary() async {
    final dynamic raw = await _client.rpc('reading_logs_user_summary');
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<bool> fetchHasLogOnDate({
    required String userId,
    required String isoDate,
  }) async {
    final rows = await _client
        .from('reading_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('date', isoDate)
        .limit(1);
    final list = rows as List<dynamic>? ?? <dynamic>[];
    return list.isNotEmpty;
  }

  Future<bool> fetchHasReadToday({required String userId}) {
    return fetchHasLogOnDate(userId: userId, isoDate: _todayLocalIsoDate());
  }
}
