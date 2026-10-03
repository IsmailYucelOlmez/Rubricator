import 'package:bookapp/features/habit/data/datasources/habit_pending_logs_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('removeForUser drops only that user\'s queued logs', () async {
    final ds = HabitPendingLogsLocalDataSource();
    await ds.enqueue(userId: 'a', minutesRead: 10, pagesRead: 5);
    await ds.enqueue(userId: 'b', minutesRead: 20, pagesRead: 8);
    await ds.enqueue(userId: 'a', minutesRead: 5, pagesRead: 2);

    await ds.removeForUser('a');

    expect(await ds.getForUser('a'), isEmpty);
    final remaining = await ds.getAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.userId, 'b');
  });
}
