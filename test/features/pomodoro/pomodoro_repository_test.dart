import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PomodoroRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PomodoroRepository(db);
  });

  tearDown(() => db.close());

  test('进行中会话唯一，存 started_at 绝对时间戳', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);

    final active = await repo.watchActiveSession().first;

    expect(active, isNotNull);
    expect(active!.endedAt, 0);
    final elapsed = DateTime.now().millisecondsSinceEpoch - active.startedAt;
    expect(elapsed, greaterThanOrEqualTo(0));
    expect(
      () => repo.startSession(mode: 'flowtime', plannedMinutes: 0),
      throwsStateError,
    );
  });

  test('今日专注分钟数聚合', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    final active = await repo.watchActiveSession().first;

    await repo.finishSession(active!.id, actualMinutes: 25);

    expect(await repo.todayFocusMinutes(), 25);
  });
}
