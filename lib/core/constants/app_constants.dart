import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String googleBooksBaseUrl =
      'https://www.googleapis.com/books/v1';

  /// `GOOGLE_BOOKS_API_KEY` from [assets/.env] (loaded in [SupabaseService.initialize]),
  /// or `--dart-define=GOOGLE_BOOKS_API_KEY=...` when the file value is empty.
  static String get googleBooksApiKey {
    final fromFile = dotenv.env['GOOGLE_BOOKS_API_KEY']?.trim() ?? '';
    if (fromFile.isNotEmpty) return fromFile;
    return const String.fromEnvironment(
      'GOOGLE_BOOKS_API_KEY',
      defaultValue: '',
    ).trim();
  }

  static const String summariesKey = 'cached_ai_summaries';

  /// Google Books thumbnail URL, or null for placeholder.
  static String? bookThumbnailUrl(String? coverImageUrl) {
    if (coverImageUrl == null || coverImageUrl.isEmpty) return null;
    return coverImageUrl;
  }

  /// Detail cover: bumps Google Books zoom when present.
  static String? bookDetailCoverUrl(String? coverImageUrl) {
    if (coverImageUrl == null || coverImageUrl.isEmpty) return null;
    return coverImageUrl.replaceAll('zoom=1', 'zoom=3');
  }
}
