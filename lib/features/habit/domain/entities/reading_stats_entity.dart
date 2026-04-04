class ReadingStatsEntity {
  const ReadingStatsEntity({
    required this.totalMinutes,
    required this.totalPages,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int totalMinutes;
  final int totalPages;
  final int currentStreak;
  final int longestStreak;
}
