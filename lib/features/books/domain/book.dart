class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverId,
    required this.description,
  });

  final String id;
  final String title;
  final String author;
  final int? coverId;
  final String description;

  factory Book.fromSearchJson(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    final authors = json['author_name'] as List<dynamic>?;
    return Book(
      id: key.replaceFirst('/works/', ''),
      title: json['title'] as String? ?? 'Unknown title',
      author: (authors?.isNotEmpty ?? false)
          ? authors!.first.toString()
          : 'Unknown author',
      coverId: json['cover_i'] as int?,
      description: '',
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? coverId,
    String? description,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverId: coverId ?? this.coverId,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverId': coverId,
      'description': description,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown title',
      author: json['author'] as String? ?? 'Unknown author',
      coverId: json['coverId'] as int?,
      description: json['description'] as String? ?? '',
    );
  }
}
