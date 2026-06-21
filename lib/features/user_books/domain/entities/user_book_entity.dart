enum ReadingStatus { toRead, reading, completed, dropped, reReading }

ReadingStatus readingStatusFromDb(String value) {
  switch (value) {
    case 'to_read':
      return ReadingStatus.toRead;
    case 'reading':
      return ReadingStatus.reading;
    case 'completed':
      return ReadingStatus.completed;
    case 'dropped':
      return ReadingStatus.dropped;
    case 're_reading':
      return ReadingStatus.reReading;
    default:
      return ReadingStatus.toRead;
  }
}

String readingStatusToDb(ReadingStatus status) {
  switch (status) {
    case ReadingStatus.toRead:
      return 'to_read';
    case ReadingStatus.reading:
      return 'reading';
    case ReadingStatus.completed:
      return 'completed';
    case ReadingStatus.dropped:
      return 'dropped';
    case ReadingStatus.reReading:
      return 're_reading';
  }
}

List<String> _categoriesFromMap(Map<String, dynamic> map) {
  final raw = map['book_categories'];
  if (raw is List<dynamic>) {
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  return const [];
}

class UserBookEntity {
  const UserBookEntity({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    required this.isFavorite,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.bookTitle,
    this.bookAuthor,
    this.bookCategories = const [],
    this.completedAt,
  });

  final String id;
  final String userId;
  final String bookId;
  final ReadingStatus status;
  final bool isFavorite;
  final int? progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bookTitle;
  final String? bookAuthor;
  final List<String> bookCategories;
  final DateTime? completedAt;

  /// Stored title/author on `user_books` — avoids Google Books fetch in lists.
  bool get hasCompletedSnapshot =>
      bookTitle != null &&
      bookTitle!.isNotEmpty &&
      bookAuthor != null &&
      bookAuthor!.isNotEmpty;

  UserBookEntity copyWith({
    String? id,
    String? userId,
    String? bookId,
    ReadingStatus? status,
    bool? isFavorite,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bookTitle,
    String? bookAuthor,
    List<String>? bookCategories,
    DateTime? completedAt,
  }) {
    return UserBookEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      bookCategories: bookCategories ?? this.bookCategories,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory UserBookEntity.fromMap(Map<String, dynamic> map) {
    return UserBookEntity(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      bookId: map['book_id'] as String? ?? '',
      status: readingStatusFromDb((map['status'] as String?) ?? 'to_read'),
      isFavorite: map['is_favorite'] as bool? ?? false,
      progress: map['progress'] as int?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
      bookTitle: map['book_title'] as String?,
      bookAuthor: map['book_author'] as String?,
      bookCategories: _categoriesFromMap(map),
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? ''),
    );
  }
}
