import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/book.dart';

class AiService {
  /// Caps the persisted cache so it can't grow without bound. This matters
  /// most on web, where `shared_preferences` is backed by the browser's
  /// per-origin `localStorage` (typically ~5-10 MB total, shared with the
  /// Supabase session and every other local pref) rather than a native file.
  static const _maxCacheEntries = 200;

  Future<String> summarize(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRaw = prefs.getString(AppConstants.summariesKey);
    Map<String, String> cache;
    try {
      cache =
          (cachedRaw == null
                  ? <String, dynamic>{}
                  : jsonDecode(cachedRaw) as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value.toString()));
    } on FormatException {
      // Corrupted cache entry (e.g. partially written before a quota error) —
      // drop it rather than fail every summary lookup from now on.
      cache = <String, String>{};
    }

    final existing = cache[book.id];
    if (existing != null) return existing;

    final summary = _buildLocalSummary(book);
    cache[book.id] = summary;
    while (cache.length > _maxCacheEntries) {
      cache.remove(cache.keys.first);
    }
    try {
      await prefs.setString(AppConstants.summariesKey, jsonEncode(cache));
    } catch (_) {
      // Storage quota exceeded or unavailable (private browsing, blocked
      // site data, …) — still return the summary, just don't persist it.
    }
    return summary;
  }

  String _buildLocalSummary(Book book) {
    final base = book.description.trim().isEmpty
        ? '${book.title} is a well-known work by ${book.author}.'
        : book.description.trim();
    return '$base This concise summary is generated through ai_service and cached for reuse.';
  }
}
