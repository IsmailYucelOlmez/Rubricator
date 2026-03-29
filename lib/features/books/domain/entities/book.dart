/// Domain entity for a work (Open Library "work" id without `/works/` prefix).
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverId,
    required this.description,
    this.authorIds = const [],
    this.subjectKeys = const [],
  });

  final String id;
  final String title;
  final String author;
  final int? coverId;
  final String description;

  /// Open Library author keys without `/authors/` prefix (when known).
  final List<String> authorIds;

  /// Subject strings from the work (used for related-book search).
  final List<String> subjectKeys;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? coverId,
    String? description,
    List<String>? authorIds,
    List<String>? subjectKeys,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverId: coverId ?? this.coverId,
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
      'coverId': coverId,
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
      coverId: json['coverId'] as int?,
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
