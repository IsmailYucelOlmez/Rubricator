/// Domain entity for a Google Books volume.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverImageUrl,
    required this.description,
    this.authorIds = const [],
    this.subjectKeys = const [],
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

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverImageUrl,
    String? description,
    List<String>? authorIds,
    List<String>? subjectKeys,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      authorIds: authorIds ?? this.authorIds,
      subjectKeys: subjectKeys ?? this.subjectKeys,
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
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown title',
      author: json['author'] as String? ?? 'Unknown author',
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
    );
  }
}
