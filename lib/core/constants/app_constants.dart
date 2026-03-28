class AppConstants {
  static const String openLibraryBaseUrl = 'https://openlibrary.org';
  static const String openLibraryCoverBaseUrl = 'https://covers.openlibrary.org';
  static const String summariesKey = 'cached_ai_summaries';

  /// Open Library cover by edition/work cover id. Returns null if [coverId] is null.
  static String? workCoverUrl(int? coverId, {String size = 'L'}) {
    if (coverId == null) return null;
    return '$openLibraryCoverBaseUrl/b/id/$coverId-$size.jpg';
  }

  /// Author photo from Open Library photos list.
  static String? authorPhotoUrl(int? photoId, {String size = 'M'}) {
    if (photoId == null) return null;
    return '$openLibraryCoverBaseUrl/a/id/$photoId-$size.jpg';
  }
}
