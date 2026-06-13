import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone() as String;
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const settings = InitializationSettings(
      android: android,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showStreakReminder(
    int streak,
  ) async {
    await _plugin.show(
      1001,
      'Okuma Hatırlatması',
      'Bugün kayıt eklemedin. '
      '$streak günlük serin bozulacak.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminder',
          'Reading Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleNotification({int id=1001, required String title, required String body, required int hour, required int minute}) async {

    final now = tz.TZDateTime.now(tz.local);

    var scheduleDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduleDate,    
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminder',
          'Reading Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time
    );

  }

  Future<void> cancelNotification() async {
    await _plugin.cancelAll();
  }
}

