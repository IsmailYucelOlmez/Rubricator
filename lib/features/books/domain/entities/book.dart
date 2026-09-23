import '../../../../core/i18n/fallback_strings.dart';

/// Domain entity for a Google Books volume.
///
/// [id] is the stable key; equality uses [id] so Riverpod `family` providers
/// treat the same volume as one cache entry even when lists carry richer metadata.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverImageUrl,
    required this.description,
    this.authorIds = const [],
    this.subjectKeys = const [],
    this.sourceUrl,
    this.isUserSubmitted = false,
  });

  final String id;
  final String title;
  final String author;

  /// HTTPS thumbnail from Google Books `imageLinks`.
  final String? coverImageUrl;

  final String description;

  /// Author identifiers: `g:` + URI-encoded display name.
  final List<String> authorIds;

  /// Categories / subjects for related-book search.
  final List<String> subjectKeys;

  /// Retailer product page this book was scraped from (trbooks only, e.g.
  /// D&R/Kitapyurdu); `null` for Google Books-origin books.
  final String? sourceUrl;

  /// True for trbooks rows with `source = 'user_submitted'` — surfaced as a
  /// "user contribution" badge to distinguish from scraped/verified data.
  final bool isUserSubmitted;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverImageUrl,
    String? description,
    List<String>? authorIds,
    List<String>? subjectKeys,
    String? sourceUrl,
    bool? isUserSubmitted,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      authorIds: authorIds ?? this.authorIds,
      subjectKeys: subjectKeys ?? this.subjectKeys,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isUserSubmitted: isUserSubmitted ?? this.isUserSubmitted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverImageUrl': coverImageUrl,
      'description': description,
      'authorIds': authorIds,
      'subjectKeys': subjectKeys,
      'sourceUrl': sourceUrl,
      'isUserSubmitted': isUserSubmitted,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? FallbackStrings.unknownTitle,
      author: json['author'] as String? ?? FallbackStrings.unknownAuthor,
      coverImageUrl: json['coverImageUrl'] as String?,
      description: json['description'] as String? ?? '',
      authorIds:
          (json['authorIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      subjectKeys:
          (json['subjectKeys'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sourceUrl: json['sourceUrl'] as String?,
      isUserSubmitted: json['isUserSubmitted'] as bool? ?? false,
    );
  }
}
