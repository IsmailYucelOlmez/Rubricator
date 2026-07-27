import '../../domain/entities/book_note_entity.dart';
import '../../domain/repositories/book_notes_repository.dart';
import '../datasources/book_notes_remote_datasource.dart';
import '../models/book_note_model.dart';

class BookNotesRepositoryImpl implements BookNotesRepository {
  BookNotesRepositoryImpl(this._remote, this._currentUserId);

  final BookNotesRemoteDataSource _remote;
  final String? Function() _currentUserId;

  @override
  Future<List<BookNoteEntity>> getPublicNotesByBook(
    String bookId, {
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    final list = await _remote.fetchPublicNotesByBook(
      bookId,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<BookNoteEntity>> getMyNotes({
    String? searchQuery,
    List<String>? tagFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    final userId = _requireUserId();
    final list = await _remote.fetchMyNotes(
      userId: userId,
      searchQuery: searchQuery,
      tagFilter: tagFilter,
      limit: limit,
      offset: offset,
    );
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<String>> getMyTags() async {
    final userId = _requireUserId();
    return _remote.fetchMyTags(userId: userId);
  }

  @override
  Future<BookNoteEntity> addNote(BookNoteEntity note) async {
    final userId = _requireUserId();
    final model = BookNoteModel.fromRow(<String, dynamic>{
      'id': note.id,
      'user_id': userId,
      'book_id': note.bookId,
      'page_number': note.pageNumber,
      'chapter_title': note.chapterTitle,
      'note_title': note.noteTitle,
      'note_content': note.noteContent,
      'tags': note.tags,
      'is_public': note.isPublic,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
    });
    final saved = await _remote.insertNote(model);
    return saved.toEntity();
  }

  @override
  Future<BookNoteEntity> updateNote(BookNoteEntity note) async {
    _requireUserId();
    final model = BookNoteModel.fromRow(<String, dynamic>{
      'id': note.id,
      'user_id': note.userId,
      'book_id': note.bookId,
      'page_number': note.pageNumber,
      'chapter_title': note.chapterTitle,
      'note_title': note.noteTitle,
      'note_content': note.noteContent,
      'tags': note.tags,
      'is_public': note.isPublic,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.updatedAt.toIso8601String(),
    });
    final saved = await _remote.updateNote(model);
    return saved.toEntity();
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _requireUserId();
    await _remote.deleteNote(noteId);
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Sign in required.');
    }
    return userId;
  }
}
