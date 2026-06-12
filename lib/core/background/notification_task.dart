import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../services/notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (task, inputData) async {
      final prefs =
          await SharedPreferences.getInstance();

      final streak =
          prefs.getInt('current_streak') ?? 0;

      final lastEntry =
          prefs.getString('last_entry_date');

      if (lastEntry == null) {
        return Future.value(true);
      }

      final entryDate =
          DateTime.parse(lastEntry);

      final now = DateTime.now();

      final readToday =
          entryDate.year == now.year &&
          entryDate.month == now.month &&
          entryDate.day == now.day;

      if (!readToday) {
        await NotificationService.instance
            .initialize();

        await NotificationService.instance
            .showStreakReminder(streak);
      }

      return Future.value(true);
    },
  );
}