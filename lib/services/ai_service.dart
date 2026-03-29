import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../features/books/domain/entities/book.dart';

class AiService {
  Future<String> summarize(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRaw = prefs.getString(AppConstants.summariesKey);
    final cache =
        (cachedRaw == null
                ? <String, dynamic>{}
                : jsonDecode(cachedRaw) as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value.toString()));

    final existing = cache[book.id];
    if (existing != null) return existing;

    final summary = _buildLocalSummary(book);
    cache[book.id] = summary;
    await prefs.setString(AppConstants.summariesKey, jsonEncode(cache));
    return summary;
  }

  String _buildLocalSummary(Book book) {
    final base = book.description.trim().isEmpty
        ? '${book.title} is a well-known work by ${book.author}.'
        : book.description.trim();
    return '$base This concise summary is generated through ai_service and cached for reuse.';
  }
}
