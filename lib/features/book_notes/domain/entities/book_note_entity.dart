class BookNoteEntity {
  const BookNoteEntity({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.pageNumber,
    required this.chapterTitle,
    required this.noteTitle,
    required this.noteContent,
    required this.tags,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String bookId;
  final int? pageNumber;
  final String? chapterTitle;
  final String noteTitle;
  final String noteContent;
  final List<String> tags;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookNoteEntity copyWith({
    String? id,
    String? userId,
    String? bookId,
    int? pageNumber,
    bool clearPageNumber = false,
    String? chapterTitle,
    bool clearChapterTitle = false,
    String? noteTitle,
    String? noteContent,
    List<String>? tags,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookNoteEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      pageNumber: clearPageNumber ? null : (pageNumber ?? this.pageNumber),
      chapterTitle:
          clearChapterTitle ? null : (chapterTitle ?? this.chapterTitle),
      noteTitle: noteTitle ?? this.noteTitle,
      noteContent: noteContent ?? this.noteContent,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
