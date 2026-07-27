import '../../domain/entities/book_note_entity.dart';

class BookNoteModel {
  BookNoteModel({
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
    this.userName,
  });

  factory BookNoteModel.fromRow(Map<String, dynamic> row) {
    return BookNoteModel(
      id: (row['id'] as String?) ?? '',
      userId: (row['user_id'] as String?) ?? '',
      bookId: (row['book_id'] as String?) ?? '',
      pageNumber: (row['page_number'] as num?)?.toInt(),
      chapterTitle: row['chapter_title'] as String?,
      noteTitle: (row['note_title'] as String?) ?? '',
      noteContent: (row['note_content'] as String?) ?? '',
      tags: _parseTags(row['tags']),
      isPublic: row['is_public'] as bool? ?? false,
      createdAt:
          _parseDateTime(row['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDateTime(row['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      userName: (row['user_name'] as String?)?.trim(),
    );
  }

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
  final String? userName;

  BookNoteEntity toEntity() {
    return BookNoteEntity(
      id: id,
      userId: userId,
      bookId: bookId,
      pageNumber: pageNumber,
      chapterTitle: chapterTitle,
      noteTitle: noteTitle,
      noteContent: noteContent,
      tags: tags,
      isPublic: isPublic,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userName: userName,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return <String, dynamic>{
      'user_id': userId,
      'book_id': bookId,
      'page_number': pageNumber,
      'chapter_title': chapterTitle,
      'note_title': noteTitle,
      'note_content': noteContent,
      'tags': tags,
      'is_public': isPublic,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'page_number': pageNumber,
      'chapter_title': chapterTitle,
      'note_title': noteTitle,
      'note_content': noteContent,
      'tags': tags,
      'is_public': isPublic,
    };
  }

  static List<String> _parseTags(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
