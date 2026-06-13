import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_service.dart';
import 'reading_reminder_logic.dart';
import 'reading_reminder_prefs.dart';

class ReadingReminderScheduler {
  ReadingReminderScheduler._();

  static Future<void> ensureScheduledFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getString(kAppNotificationModeKey) != 'disabled';
    await ensureScheduled(enabled);
  }

  static Future<void> ensureScheduled(bool enabled) async {
    if (enabled) {
      await refreshSchedule();
    } else {
      await cancelReminder();
    }
  }

  static Future<void> refreshSchedule() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString(kAppNotificationModeKey) == 'disabled') {
      await cancelReminder();
      return;
    }

    final now = DateTime.now();
    final lastEntry = prefs.getString(kReadingReminderLastEntryKey);

    if (hasLoggedReadingToday(lastEntry, now)) {
      await cancelReminder();
      return;
    }

    final streak = readingReminderStreakAtRisk(
      savedStreak: prefs.getInt(kReadingReminderStreakKey) ?? 0,
      lastEntry: lastEntry,
      today: DateTime(now.year, now.month, now.day),
    );

    await NotificationService.instance.scheduleDailyReadingReminder(
      streak: streak,
    );
  }

  static Future<void> cancelReminder() async {
    await NotificationService.instance.cancelReadingReminder();
  }

  static Future<void> syncStreakAfterLog({
    required int currentStreak,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kReadingReminderStreakKey, currentStreak);
    await prefs.setString(
      kReadingReminderLastEntryKey,
      DateTime.now().toIso8601String(),
    );
    await cancelReminder();
  }
}
