class AppConstants {
  static const String summariesKey = 'cached_ai_summaries';

  /// Cover thumbnail URL (forced to https), or null for placeholder.
  static String? bookThumbnailUrl(String? coverImageUrl) {
    if (coverImageUrl == null || coverImageUrl.isEmpty) return null;
    return secureCoverUrl(coverImageUrl);
  }

  /// Detail cover: bumps Google Books zoom when present.
  static String? bookDetailCoverUrl(String? coverImageUrl) {
    if (coverImageUrl == null || coverImageUrl.isEmpty) return null;
    return secureCoverUrl(coverImageUrl).replaceAll('zoom=1', 'zoom=3');
  }

  /// Upgrades `http:` cover URLs to `https:`. Some sources (Supabase rows,
  /// trbooks, list previews) aren't normalized at parse time, and an `http`
  /// image on the https-served web build is mixed content the browser may
  /// block (and Android blocks cleartext by default).
  static String secureCoverUrl(String url) =>
      url.replaceFirst(RegExp(r'^http:', caseSensitive: false), 'https:');
}
