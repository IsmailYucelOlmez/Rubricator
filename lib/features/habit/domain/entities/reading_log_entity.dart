class ReadingLogEntity {
  const ReadingLogEntity({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.minutesRead,
    required this.pagesRead,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? bookId;
  final int minutesRead;
  final int pagesRead;
  final DateTime date;
  final DateTime createdAt;
}
