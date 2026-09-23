import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'reading_reminder_logic.dart';
import 'reading_reminder_prefs.dart';

/// Local notifications aren't supported on web (no `flutter_local_notifications`
/// web implementation), so every entry point here is a no-op there.
class ReadingReminderScheduler {
  ReadingReminderScheduler._();

  static Future<void> ensureScheduledFromPrefs() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getString(kAppNotificationModeKey) != 'disabled';
    await ensureScheduled(enabled);
  }

  static Future<void> ensureScheduled(bool enabled) async {
    if (kIsWeb) return;
    if (enabled) {
      await refreshSchedule();
    } else {
      await cancelReminder();
    }
  }

  static Future<void> refreshSchedule() async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    await NotificationService.instance.cancelReadingReminder();
  }

  static Future<void> syncStreakAfterLog({
    required int currentStreak,
  }) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kReadingReminderStreakKey, currentStreak);
    await prefs.setString(
      kReadingReminderLastEntryKey,
      DateTime.now().toIso8601String(),
    );
    await cancelReminder();
  }
}
