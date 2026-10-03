import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/semantic_feedback.dart';

/// Relevance votes go straight to Supabase RPCs; identity is `auth.uid()`.
class SemanticFeedbackRemoteDataSource {
  SemanticFeedbackRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// The signed-in user's votes for [query], keyed by ISBN.
  Future<Map<String, SemanticFeedbackVote>> fetchMine({
    required String query,
    String? language,
  }) async {
    if (_client.auth.currentUser == null) return const {};
    final raw = await _client.rpc(
      'get_my_semantic_feedback',
      params: {'p_query': query, 'p_language': language},
    );
    final votes = <String, SemanticFeedbackVote>{};
    if (raw is List) {
      for (final row in raw.whereType<Map>()) {
        final isbn = row['isbn13'] as String?;
        final vote = SemanticFeedbackVote.fromValue(
          (row['vote'] as num?)?.toInt() ?? 0,
        );
        if (isbn != null && vote != null) votes[isbn] = vote;
      }
    }
    return votes;
  }

  /// Sets ([vote] non-null) or removes ([vote] null) the user's vote.
  Future<void> submit({
    required String query,
    required String isbn13,
    required SemanticFeedbackVote? vote,
    String? language,
    int? resultPosition,
    double? similarity,
    String? mode,
    String? category,
    String? tone,
  }) async {
    try {
      await _client.rpc(
        'submit_semantic_feedback',
        params: {
          'p_query': query,
          'p_isbn13': isbn13,
          'p_vote': vote?.value ?? 0,
          'p_language': language,
          'p_result_position': resultPosition,
          'p_similarity': similarity,
          'p_mode': mode,
          'p_category': category == 'All' ? null : category,
          'p_tone': tone == 'All' ? null : tone,
        },
      );
    } on PostgrestException catch (error) {
      if (error.code == 'PT429') {
        throw const SemanticFeedbackRateLimitException();
      }
      rethrow;
    }
  }
}
