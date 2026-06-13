bool hasLoggedReadingToday(String? lastEntry, DateTime now) {
  if (lastEntry == null) return false;
  final entryDate = DateTime.parse(lastEntry);
  return entryDate.year == now.year &&
      entryDate.month == now.month &&
      entryDate.day == now.day;
}

int readingReminderStreakAtRisk({
  required int savedStreak,
  required String? lastEntry,
  required DateTime today,
}) {
  if (lastEntry == null || savedStreak <= 0) {
    return 0;
  }

  final entryDay = DateTime.parse(lastEntry);
  final entryDate = DateTime(entryDay.year, entryDay.month, entryDay.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (entryDate == yesterday) {
    return savedStreak;
  }

  return 0;
}

const kReadingReminderNotificationId = 1001;
