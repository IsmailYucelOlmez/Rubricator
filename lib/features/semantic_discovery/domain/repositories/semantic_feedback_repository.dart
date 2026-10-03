import '../entities/semantic_feedback.dart';

abstract class SemanticFeedbackRepository {
  Future<Map<String, SemanticFeedbackVote>> fetchMyVotes(
    SemanticFeedbackKey key,
  );

  /// [vote] null removes the user's vote.
  Future<void> submitVote({
    required SemanticFeedbackKey key,
    required String isbn13,
    required SemanticFeedbackVote? vote,
    int? resultPosition,
    double? similarity,
    String? mode,
    String? category,
    String? tone,
  });
}
