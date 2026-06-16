import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../core/logging/app_logger.dart';
import '../core/notification/reading_reminder_localization.dart';
import '../core/notification/reading_reminder_logic.dart';
import '../core/notification/reading_reminder_prefs.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
    AppLogger.info('notifications', 'Service initialized');
  }

  Future<void> showReadingReminder({required int streak}) async {
    await initialize();
    final copy = await loadReadingReminderCopy(streak: streak);
    await _plugin.show(
      kReadingReminderNotificationId,
      copy.title,
      copy.body,
      _notificationDetails(copy),
    );
  }

  Future<void> scheduleDailyReadingReminder({required int streak}) async {
    await initialize();
    final copy = await loadReadingReminderCopy(streak: streak);

    final now = tz.TZDateTime.now(tz.local);
    var scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      kReadingReminderHour,
      kReadingReminderMinute,
    );
    if (!scheduleDate.isAfter(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      kReadingReminderNotificationId,
      copy.title,
      copy.body,
      scheduleDate,
      _notificationDetails(copy),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReadingReminder() async {
    await _plugin.cancel(kReadingReminderNotificationId);
  }

  Future<void> cancelNotification() async {
    await _plugin.cancelAll();
  }

  NotificationDetails _notificationDetails(ReadingReminderCopy copy) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reading_reminder',
        copy.channelName,
        channelDescription: copy.channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }
}
