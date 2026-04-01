class SearchLogEntity {
  const SearchLogEntity({
    required this.id,
    required this.userId,
    required this.query,
    required this.bookId,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String query;
  final String? bookId;
  final DateTime createdAt;
}
