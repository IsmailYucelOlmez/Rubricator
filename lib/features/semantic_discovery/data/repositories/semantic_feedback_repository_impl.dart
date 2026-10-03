import '../../domain/entities/semantic_feedback.dart';
import '../../domain/repositories/semantic_feedback_repository.dart';
import '../datasources/semantic_feedback_remote_datasource.dart';

class SemanticFeedbackRepositoryImpl implements SemanticFeedbackRepository {
  const SemanticFeedbackRepositoryImpl(this._remote);

  final SemanticFeedbackRemoteDataSource _remote;

  @override
  Future<Map<String, SemanticFeedbackVote>> fetchMyVotes(
    SemanticFeedbackKey key,
  ) {
    return _remote.fetchMine(query: key.query, language: key.language);
  }

  @override
  Future<void> submitVote({
    required SemanticFeedbackKey key,
    required String isbn13,
    required SemanticFeedbackVote? vote,
    int? resultPosition,
    double? similarity,
    String? mode,
    String? category,
    String? tone,
  }) {
    return _remote.submit(
      query: key.query,
      language: key.language,
      isbn13: isbn13,
      vote: vote,
      resultPosition: resultPosition,
      similarity: similarity,
      mode: mode,
      category: category,
      tone: tone,
    );
  }
}
