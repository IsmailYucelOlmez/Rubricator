import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_book_model.dart';

class HomeCacheDataSource {
  HomeCacheDataSource(this._client);

  final SupabaseClient _client;

  static const String _table = 'genre_books_cache';
  static const List<int> _defaultAllowedWeekdays = <int>[1, 3, 5];
  static const int _maxRetryAttempts = 5;

  Future<GenreCacheSnapshot?> getGenreCache(String genreKey) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('genre_key', genreKey)
        .limit(1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return GenreCacheSnapshot.fromJson(row);
  }

  bool canAttemptFetchToday(GenreCacheSnapshot? row, {DateTime? now}) {
    if (row == null) return true;
    if (row.fetchCompleted) return false;
    if (!row.isActive) return false;
    final weekday = (now ?? DateTime.now()).weekday;
    final allowed = row.allowedWeekdays.isEmpty
        ? _defaultAllowedWeekdays
        : row.allowedWeekdays;
    return allowed.contains(weekday);
  }

  int get maxRetryAttempts => _maxRetryAttempts;

  Future<void> saveFetchSuccess({
    required String genreKey,
    required List<HomeBookModel> books,
  }) async {
    final payload = books.map((b) => _bookJson(b)).toList();
    await _client.from(_table).upsert(<String, dynamic>{
      'genre_key': genreKey,
      'books_json': payload,
      'total_count': books.length,
      'last_fetch_at': DateTime.now().toUtc().toIso8601String(),
      'last_fetch_status': 'success',
      'last_fetch_error': null,
      'fetch_completed': true,
      'is_active': true,
    });
  }

  Future<void> saveFetchFailure({
    required String genreKey,
    required Object error,
  }) async {
    await _client.from(_table).upsert(<String, dynamic>{
      'genre_key': genreKey,
      'last_fetch_at': DateTime.now().toUtc().toIso8601String(),
      'last_fetch_status': 'error',
      'last_fetch_error': error.toString(),
      'fetch_completed': false,
      'is_active': true,
    });
  }

  List<HomeBookModel> parseCachedBooks(GenreCacheSnapshot? row) {
    if (row == null || row.booksJson.isEmpty) return const <HomeBookModel>[];
    return row.booksJson
        .whereType<Map<String, dynamic>>()
        .map(_bookFromJson)
        .toList();
  }

  Map<String, dynamic> _bookJson(HomeBookModel book) {
    return <String, dynamic>{
      'id': book.id,
      'title': book.title,
      'cover_image_url': book.coverImageUrl,
      'author_names': book.authorNames,
      'languages': book.languages ?? const <String>[],
      'categories': book.categories ?? const <String>[],
    };
  }

  HomeBookModel _bookFromJson(Map<String, dynamic> json) {
    final languagesRaw = json['languages'];
    final categoriesRaw = json['categories'];
    return HomeBookModel(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : 'unknown',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Unknown title',
      coverImageUrl: (json['cover_image_url'] as String?)?.trim(),
      authorNames: (json['author_names'] as String?)?.trim().isNotEmpty == true
          ? (json['author_names'] as String).trim()
          : 'Unknown author',
      languages: languagesRaw is List
          ? languagesRaw.whereType<String>().toList()
          : null,
      categories: categoriesRaw is List
          ? categoriesRaw.whereType<String>().toList()
          : null,
    );
  }
}

class GenreCacheSnapshot {
  const GenreCacheSnapshot({
    required this.booksJson,
    required this.allowedWeekdays,
    required this.fetchCompleted,
    required this.isActive,
  });

  final List<dynamic> booksJson;
  final List<int> allowedWeekdays;
  final bool fetchCompleted;
  final bool isActive;

  factory GenreCacheSnapshot.fromJson(Map<String, dynamic> json) {
    final allowedRaw = json['allowed_weekdays'];
    return GenreCacheSnapshot(
      booksJson: (json['books_json'] as List<dynamic>?) ?? const <dynamic>[],
      allowedWeekdays: allowedRaw is List
          ? allowedRaw
                .map((e) => e is int ? e : int.tryParse(e.toString()))
                .whereType<int>()
                .toList()
          : const <int>[],
      fetchCompleted: json['fetch_completed'] == true,
      isActive: json['is_active'] != false,
    );
  }
}
