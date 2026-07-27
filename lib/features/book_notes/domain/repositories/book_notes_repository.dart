import '../entities/book_note_entity.dart';

abstract class BookNotesRepository {
  Future<List<BookNoteEntity>> getPublicNotesByBook(
    String bookId, {
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  });

  Future<List<BookNoteEntity>> getMyNotes({
    String? searchQuery,
    List<String>? tagFilter,
    int limit = 20,
    int offset = 0,
  });

  Future<List<String>> getMyTags();

  Future<BookNoteEntity> addNote(BookNoteEntity note);

  Future<BookNoteEntity> updateNote(BookNoteEntity note);

  Future<void> deleteNote(String noteId);
}
