class AppConstants {
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
