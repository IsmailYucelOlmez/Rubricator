import 'package:supabase_flutter/supabase_flutter.dart';

class BookIdentityCacheEntry {
  const BookIdentityCacheEntry({
    required this.isbn13,
    required this.googleVolumeId,
    this.resolvedTitle,
    this.resolveMethod = 'isbn',
  });

  final String isbn13;
  final String googleVolumeId;
  final String? resolvedTitle;
  final String resolveMethod;
}

class BookIdentityCacheDataSource {
  BookIdentityCacheDataSource(this._client);

  final SupabaseClient _client;

  Future<BookIdentityCacheEntry?> lookup(String isbn13) async {
    final normalized = isbn13.trim();
    if (normalized.isEmpty) return null;

    final row = await _client
        .from('book_identity_cache')
        .select('isbn13, google_volume_id, resolved_title, resolve_method')
        .eq('isbn13', normalized)
        .maybeSingle();

    if (row == null) return null;
    final volumeId = row['google_volume_id'] as String? ?? '';
    if (volumeId.isEmpty) return null;

    return BookIdentityCacheEntry(
      isbn13: normalized,
      googleVolumeId: volumeId,
      resolvedTitle: row['resolved_title'] as String?,
      resolveMethod: row['resolve_method'] as String? ?? 'isbn',
    );
  }

  Future<void> upsert({
    required String isbn13,
    required String googleVolumeId,
    String? resolvedTitle,
    String resolveMethod = 'isbn',
  }) async {
    await _client.rpc(
      'upsert_book_identity_cache',
      params: {
        'p_isbn13': isbn13,
        'p_google_volume_id': googleVolumeId,
        'p_resolved_title': resolvedTitle,
        'p_resolve_method': resolveMethod,
      },
    );
  }
}
