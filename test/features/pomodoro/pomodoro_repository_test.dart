import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_database.dart';

void main() {
  late AppDatabase db;
  late PomodoroRepository repo;
  late int now;

  setUp(() {
    db = createTestDatabase();
    now = DateTime(2026, 10, 11, 9).millisecondsSinceEpoch;
    repo = PomodoroRepository(db, clock: () => now);
  });

  tearDown(() => db.close());

  test('进行中会话唯一，存 started_at 绝对时间戳', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);

    final active = await repo.watchActiveSession().first;

    expect(active, isNotNull);
    expect(active!.endedAt, 0);
    expect(active.startedAt, now);
    expect(active.cycleRound, 0);
    expect(
      () => repo.startSession(mode: 'flowtime', plannedMinutes: 0),
      throwsStateError,
    );
  });

  test('watchActiveSession 只读，不会在订阅时隐式 reconcile', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    now += 25 * 60 * 1000;

    final active = await repo.watchActiveSession().first;
    final logs = await db.select(db.pomodoroLogs).get();

    expect(active, isNotNull);
    expect(active!.mode, 'pomodoro');
    expect(active.endedAt, 0);
    expect(logs, hasLength(1));
  });

  test('今日专注分钟数聚合', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    final active = await repo.watchActiveSession().first;

    await repo.finishSession(active!.id, actualMinutes: 25);

    expect(await repo.todayFocusMinutes(), 25);
  });

  test('经典 focus 到期完成并自动进入短休，且累加关联待办番茄数', () async {
    await db.into(db.todos).insert(
          TodosCompanion.insert(
            id: 'todo-1',
            title: '完成任务',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await repo.startSession(
      todoId: 'todo-1',
      mode: 'pomodoro',
      plannedMinutes: 25,
    );

    now += 25 * 60 * 1000;
    final activeAfterReconcile = await repo.reconcileActiveSession();

    expect(activeAfterReconcile, isNotNull);
    expect(activeAfterReconcile!.mode, 'shortBreak');
    expect(activeAfterReconcile.durationMinutes, 5);
    expect(activeAfterReconcile.cycleRound, 1);

    final todo = await (db.select(db.todos)
          ..where((row) => row.id.equals('todo-1')))
        .getSingle();
    expect(todo.actualPomodoros, 1);

    final logs = await db.select(db.pomodoroLogs).get();
    expect(logs, hasLength(2));
    expect(logs.where((row) => row.mode == 'pomodoro').single.endedAt, now);
  });

  test('长时间离线跨过 focus 和 break deadline 时按绝对 deadline 完成并回到 idle', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    final focusStartedAt = now;
    now += (25 + 5 + 1) * 60 * 1000;

    expect(await repo.reconcileActiveSession(), isNull);

    final logs = await db.select(db.pomodoroLogs).get();
    final focus = logs.singleWhere((row) => row.mode == 'pomodoro');
    final breakSession = logs.singleWhere((row) => row.mode == 'shortBreak');
    final focusDeadline = focusStartedAt + 25 * Duration.millisecondsPerMinute;
    final breakDeadline = focusDeadline + 5 * Duration.millisecondsPerMinute;

    expect(focus.startedAt, focusStartedAt);
    expect(focus.endedAt, focusDeadline);
    expect(breakSession.startedAt, focusDeadline);
    expect(breakSession.endedAt, breakDeadline);
  });

  test('手动完成 classic focus 会累加待办并返回新 active break', () async {
    await db.into(db.todos).insert(
          TodosCompanion.insert(
            id: 'todo-manual',
            title: '手动完成',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await repo.startSession(
      todoId: 'todo-manual',
      mode: 'pomodoro',
      plannedMinutes: 25,
    );
    final focus = await repo.watchActiveSession().first;

    final breakSession = await repo.finishSession(
      focus!.id,
      actualMinutes: 25,
    );

    expect(breakSession, isNotNull);
    expect(breakSession!.mode, PomodoroRepository.shortBreakMode);
    expect(breakSession.startedAt, now);
    expect(breakSession.endedAt, 0);

    final completedFocus = await (db.select(db.pomodoroLogs)
          ..where((row) => row.id.equals(focus.id)))
        .getSingle();
    final todo = await (db.select(db.todos)
          ..where((row) => row.id.equals('todo-manual')))
        .getSingle();
    expect(completedFocus.endedAt, now);
    expect(todo.actualPomodoros, 1);
  });

  test('第四轮经典 focus 到期自动进入长休', () async {
    for (var round = 0; round < 4; round++) {
      await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
      final focus = await repo.watchActiveSession().first;
      expect(focus!.cycleRound, round);

      now += 25 * 60 * 1000;
      final breakSession = await repo.reconcileActiveSession();
      expect(breakSession, isNotNull);
      expect(
        breakSession!.mode,
        round == 3 ? 'longBreak' : 'shortBreak',
      );
      expect(breakSession.cycleRound, round + 1);

      now += breakSession.durationMinutes * 60 * 1000;
      expect(await repo.reconcileActiveSession(), isNull);
      if (round == 3) {
        expect(await repo.currentCycleRound(), 0);
      }
    }
  });

  test('break 到期后回到可开始下一轮的空闲状态', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    now += 25 * 60 * 1000;
    final breakSession = await repo.reconcileActiveSession();
    expect(breakSession!.mode, 'shortBreak');

    now += 5 * 60 * 1000;
    expect(await repo.reconcileActiveSession(), isNull);

    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    final nextFocus = await repo.watchActiveSession().first;
    expect(nextFocus!.mode, 'pomodoro');
    expect(nextFocus.cycleRound, 1);
  });

  test('重建 repository 后从持久化记录恢复当前 cycle round', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    now += 25 * 60 * 1000;
    await repo.reconcileActiveSession();
    now += 5 * 60 * 1000;
    await repo.reconcileActiveSession();

    final rebuilt = PomodoroRepository(db, clock: () => now);
    await rebuilt.startSession(mode: 'pomodoro', plannedMinutes: 25);

    final active = await rebuilt.watchActiveSession().first;
    expect(active!.cycleRound, 1);
  });

  test('Flowtime 不自动结束，Countdown 到期自动结束且不创建 break', () async {
    await repo.startSession(mode: 'flowtime', plannedMinutes: 0);
    now += 24 * 60 * 60 * 1000;
    expect((await repo.reconcileActiveSession())!.mode, 'flowtime');
    await repo.cancelSession((await repo.watchActiveSession().first)!.id);

    await repo.startSession(mode: 'countdown', plannedMinutes: 15);
    now += 15 * 60 * 1000;
    expect(await repo.reconcileActiveSession(), isNull);
    final logs = await db.select(db.pomodoroLogs).get();
    expect(logs, hasLength(2));
    expect(logs.where((row) => row.mode == 'countdown').single.endedAt, now);
  });

  test('active session partial unique index 防止第二个未结束会话', () async {
    final indexes = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'index' AND name = 'pomodoro_logs_one_active_idx'",
        )
        .get();
    expect(indexes, hasLength(1));

    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    expect(
      () => db.into(db.pomodoroLogs).insert(
            PomodoroLogsCompanion.insert(
              id: 'second-active',
              durationMinutes: 25,
              startedAt: now,
              endedAt: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('repository 是 break 规则的唯一 owner', () {
    final shortBreak = PomodoroRepository.breakForCompletedRound(1);
    final longBreak = PomodoroRepository.breakForCompletedRound(4);

    expect(shortBreak.mode, PomodoroRepository.shortBreakMode);
    expect(shortBreak.minutes, 5);
    expect(longBreak.mode, PomodoroRepository.longBreakMode);
    expect(longBreak.minutes, 15);
  });
}
