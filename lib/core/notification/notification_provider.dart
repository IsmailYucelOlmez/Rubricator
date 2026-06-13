import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_reminder_prefs.dart';
import 'reading_reminder_scheduler.dart';

enum NotificationMode { enabled, disabled }

final notificationModeProvider = StateNotifierProvider<NotificationModeNotifier, NotificationMode>(
  (ref) => NotificationModeNotifier(),
);

class NotificationModeNotifier extends StateNotifier<NotificationMode> {
  NotificationModeNotifier() : super(NotificationMode.enabled) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kAppNotificationModeKey);
    state = raw == 'disabled' ? NotificationMode.disabled : NotificationMode.enabled;
    await ReadingReminderScheduler.ensureScheduled(
      state == NotificationMode.enabled,
    );
  }

  Future<void> setNotificationMode(NotificationMode mode) async {
    final resolved = mode == NotificationMode.enabled ? NotificationMode.enabled : NotificationMode.disabled;
    state = resolved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kAppNotificationModeKey,
      resolved == NotificationMode.enabled ? 'enabled' : 'disabled',
    );
    await ReadingReminderScheduler.ensureScheduled(
      resolved == NotificationMode.enabled,
    );
  }
}
