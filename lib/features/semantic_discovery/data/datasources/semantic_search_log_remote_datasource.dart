import 'package:supabase_flutter/supabase_flutter.dart';

class SemanticSearchLogRemoteDataSource {
  SemanticSearchLogRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<void> logSearch({
    required String query,
    required String mode,
    String? category,
    String? tone,
    required int resultCount,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    await _client.from('semantic_search_logs').insert({
      'user_id': _client.auth.currentUser?.id,
      'query': trimmed,
      'mode': mode,
      'category': category == 'All' ? null : category,
      'tone': tone == 'All' ? null : tone,
      'result_count': resultCount,
    });
  }
}
