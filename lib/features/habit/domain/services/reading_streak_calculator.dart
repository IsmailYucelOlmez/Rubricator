import '../entities/reading_stats_entity.dart';

/// Pure streak math from distinct calendar days that had at least one log.
class ReadingStreakCalculator {
  const ReadingStreakCalculator._();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static ReadingStatsEntity fromSummary({
    required int totalMinutes,
    required int totalPages,
    required List<DateTime> activeDates,
    required DateTime today,
  }) {
    final unique = <DateTime>{};
    for (final d in activeDates) {
      unique.add(dateOnly(d));
    }
    final sorted = unique.toList()..sort();
    return ReadingStatsEntity(
      totalMinutes: totalMinutes,
      totalPages: totalPages,
      currentStreak: _currentStreak(unique, dateOnly(today)),
      longestStreak: _longestStreak(sorted),
    );
  }

  static int _currentStreak(Set<DateTime> active, DateTime today) {
    var d = today;
    var n = 0;
    while (active.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  static int _longestStreak(List<DateTime> sortedAsc) {
    if (sortedAsc.isEmpty) return 0;
    var best = 1;
    var run = 1;
    for (var i = 1; i < sortedAsc.length; i++) {
      final prev = sortedAsc[i - 1];
      final cur = sortedAsc[i];
      if (cur.difference(prev).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else if (cur != prev) {
        run = 1;
      }
    }
    return best;
  }
}
