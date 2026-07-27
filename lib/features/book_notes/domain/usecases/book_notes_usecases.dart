import '../entities/book_note_entity.dart';
import '../repositories/book_notes_repository.dart';

class BookNoteValidationException implements Exception {
  BookNoteValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

List<String> normalizeBookNoteTags(List<String> raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final tag in raw) {
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty) continue;
    if (normalized.length > 40) {
      throw BookNoteValidationException('Each tag must be at most 40 characters.');
    }
    if (seen.add(normalized)) out.add(normalized);
    if (out.length > 10) {
      throw BookNoteValidationException('At most 10 tags are allowed.');
    }
  }
  return out;
}

void _validateNoteFields({
  required String noteTitle,
  required String noteContent,
  int? pageNumber,
  String? chapterTitle,
  required List<String> tags,
}) {
  final title = noteTitle.trim();
  if (title.isEmpty || title.length > 200) {
    throw BookNoteValidationException('Title must be 1–200 characters.');
  }
  final content = noteContent.trim();
  if (content.isEmpty || content.length > 10000) {
    throw BookNoteValidationException('Content must be 1–10,000 characters.');
  }
  if (pageNumber != null && pageNumber <= 0) {
    throw BookNoteValidationException('Page number must be a positive integer.');
  }
  final chapter = chapterTitle?.trim();
  if (chapter != null && chapter.isNotEmpty && chapter.length > 100) {
    throw BookNoteValidationException('Chapter title must be at most 100 characters.');
  }
  normalizeBookNoteTags(tags);
}

class GetPublicNotesByBookUseCase {
  const GetPublicNotesByBookUseCase(this._repository);
  final BookNotesRepository _repository;

  Future<List<BookNoteEntity>> call(
    String bookId, {
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) {
    return _repository.getPublicNotesByBook(
      bookId,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }
}

class GetMyNotesUseCase {
  const GetMyNotesUseCase(this._repository);
  final BookNotesRepository _repository;

  Future<List<BookNoteEntity>> call({
    String? searchQuery,
    List<String>? tagFilter,
    int limit = 20,
    int offset = 0,
  }) {
    return _repository.getMyNotes(
      searchQuery: searchQuery,
      tagFilter: tagFilter,
      limit: limit,
      offset: offset,
    );
  }
}

class GetMyNoteTagsUseCase {
  const GetMyNoteTagsUseCase(this._repository);
  final BookNotesRepository _repository;

  Future<List<String>> call() => _repository.getMyTags();
}

class AddBookNoteUseCase {
  const AddBookNoteUseCase(this._repository);
  final BookNotesRepository _repository;

  Future<BookNoteEntity> call(BookNoteEntity note) {
    _validateNoteFields(
      noteTitle: note.noteTitle,
      noteContent: note.noteContent,
      pageNumber: note.pageNumber,
      chapterTitle: note.chapterTitle,
      tags: note.tags,
    );
    final normalizedTags = normalizeBookNoteTags(note.tags);
    return _repository.addNote(
      note.copyWith(
        noteTitle: note.noteTitle.trim(),
        noteContent: note.noteContent.trim(),
        chapterTitle: note.chapterTitle?.trim().isEmpty ?? true
            ? null
            : note.chapterTitle!.trim(),
        tags: normalizedTags,
      ),
    );
  }
}

class UpdateBookNoteUseCase {
  const UpdateBookNoteUseCase(this._repository);
  final BookNotesRepository _repository;

  Future<BookNoteEntity> call(BookNoteEntity note) {
    _validateNoteFields(
      noteTitle: note.noteTitle,
      noteContent: note.noteContent,
      pageNumber: note.pageNumber,
      chapterTitle: note.chapterTitle,
      tags: note.tags,
    );
    final normalizedTags = normalizeBookNoteTags(note.tags);
    return _repository.updateNote(
      note.copyWith(
        noteTitle: note.noteTitle.trim(),
        noteContent: note.noteContent.trim(),
        chapterTitle: note.chapterTitle?.trim().isEmpty ?? true
            ? null
            : note.chapterTitle!.trim(),
        tags: normalizedTags,
      ),
    );
  }
}

class DeleteBookNoteUseCase {
  const DeleteBookNoteUseCase(this._repository);
  final BookNotesRepository _repository;

  Future<void> call(String noteId) => _repository.deleteNote(noteId);
}
