import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book_note_model.dart';

class BookNotesRemoteDataSource {
  BookNotesRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _selectColumns =
      'id,user_id,book_id,page_number,chapter_title,note_title,note_content,tags,is_public,created_at,updated_at';

  Future<List<BookNoteModel>> fetchPublicNotesByBook(
    String bookId, {
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from('book_notes')
        .select(_selectColumns)
        .eq('book_id', bookId.trim())
        .eq('is_public', true);

    query = _applySearchFilter(query, searchQuery);

    final rows = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return _parseRows(rows);
  }

  Future<List<BookNoteModel>> fetchMyNotes({
    required String userId,
    String? searchQuery,
    List<String>? tagFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from('book_notes')
        .select(_selectColumns)
        .eq('user_id', userId);

    query = _applySearchFilter(query, searchQuery);

    if (tagFilter != null && tagFilter.isNotEmpty) {
      query = query.contains('tags', tagFilter);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return _parseRows(rows);
  }

  Future<List<String>> fetchMyTags({required String userId}) async {
    final rows = await _client
        .from('book_notes')
        .select('tags')
        .eq('user_id', userId);

    final tags = <String>{};
    for (final row in _parseRows(rows)) {
      tags.addAll(row.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  Future<BookNoteModel> insertNote(BookNoteModel model) async {
    final row = await _client
        .from('book_notes')
        .insert(model.toInsertMap())
        .select(_selectColumns)
        .single();
    return BookNoteModel.fromRow(row);
  }

  Future<BookNoteModel> updateNote(BookNoteModel model) async {
    final row = await _client
        .from('book_notes')
        .update(model.toUpdateMap())
        .eq('id', model.id)
        .select(_selectColumns)
        .single();
    return BookNoteModel.fromRow(row);
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('book_notes').delete().eq('id', noteId);
  }

  PostgrestFilterBuilder<PostgrestList> _applySearchFilter(
    PostgrestFilterBuilder<PostgrestList> query,
    String? searchQuery,
  ) {
    final q = searchQuery?.trim();
    if (q == null || q.isEmpty) return query;

    final escaped = q.replaceAll('\\', '\\\\').replaceAll(',', '\\,');
    final pattern = '%$escaped%';
    final tagQuery = q.toLowerCase();
    return query.or(
      'note_title.ilike.$pattern,note_content.ilike.$pattern,chapter_title.ilike.$pattern,tags.cs.{$tagQuery}',
    );
  }

  List<BookNoteModel> _parseRows(dynamic rows) {
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(BookNoteModel.fromRow)
        .toList();
  }
}
