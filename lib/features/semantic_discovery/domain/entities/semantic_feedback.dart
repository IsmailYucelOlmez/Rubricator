/// A signed-in user's "is this result relevant to my query?" mark.
enum SemanticFeedbackVote {
  relevant(1),
  irrelevant(-1);

  const SemanticFeedbackVote(this.value);

  /// Value the `submit_semantic_feedback` RPC expects (0 removes the vote).
  final int value;

  static SemanticFeedbackVote? fromValue(int value) => switch (value) {
    1 => relevant,
    -1 => irrelevant,
    _ => null,
  };
}

/// Votes are stored per (query, language): both must match what the search
/// sent, otherwise the vote lands on a different query.
typedef SemanticFeedbackKey = ({String query, String? language});

/// Same pattern the API and the RPC accept; other ids can't be voted on.
final _isbnPattern = RegExp(r'^[0-9]{9,12}[0-9X]$');

bool isVotableIsbn(String isbn) =>
    _isbnPattern.hasMatch(isbn.trim().toUpperCase());

/// Thrown when the account hit the RPC's 200 votes / hour cap.
class SemanticFeedbackRateLimitException implements Exception {
  const SemanticFeedbackRateLimitException();

  @override
  String toString() => 'SemanticFeedbackRateLimitException';
}
