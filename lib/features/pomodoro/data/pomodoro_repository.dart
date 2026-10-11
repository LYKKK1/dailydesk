import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

class PomodoroRepository {
  PomodoroRepository(
    this._db, {
    int Function()? clock,
  }) : _clock = clock ?? nowMs;

  static const classicMode = 'pomodoro';
  static const flowtimeMode = 'flowtime';
  static const countdownMode = 'countdown';
  static const shortBreakMode = 'shortBreak';
  static const longBreakMode = 'longBreak';

  final AppDatabase _db;
  final int Function() _clock;

  int get _now => _clock();

  static ({String mode, int minutes}) breakForCompletedRound(
    int completedRound,
  ) {
    if (completedRound >= 4) {
      return (mode: longBreakMode, minutes: 15);
    }
    return (mode: shortBreakMode, minutes: 5);
  }

  Future<void> startSession({
    String? todoId,
    String mode = classicMode,
    int plannedMinutes = 25,
  }) async {
    await reconcileActiveSession();
    try {
      await _db.transaction(() async {
        final active = await _readActiveSession();
        if (active != null) {
          throw StateError('已有进行中的专注会话 ${active.id}');
        }

        final cycleRound = mode == classicMode ? await _nextClassicRound() : 0;
        final timestamp = _now;
        await _db.into(_db.pomodoroLogs).insert(
              PomodoroLogsCompanion.insert(
                id: newUlid(),
                todoId: Value(todoId),
                durationMinutes: plannedMinutes,
                mode: Value(mode),
                cycleRound: Value(cycleRound),
                startedAt: timestamp,
                endedAt: 0,
                createdAt: timestamp,
                updatedAt: timestamp,
              ),
            );
      });
    } on SqliteException catch (error) {
      if (error.extendedResultCode == 2067) {
        throw StateError('已有进行中的专注会话');
      }
      rethrow;
    }
  }

  /// Watches the persisted active row without reconciling or writing.
  Stream<PomodoroLog?> watchActiveSession() => (_db.select(_db.pomodoroLogs)
        ..where((p) => p.deletedAt.isNull() & p.endedAt.equals(0))
        ..limit(1))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.single);

  /// Finishes an expired active session and creates the next classic break.
  ///
  /// Returns the new active break when a classic focus transitions, the
  /// unchanged session for Flowtime, or null when the session becomes idle.
  Future<PomodoroLog?> reconcileActiveSession() async {
    final active = await _readActiveSession();
    if (active == null) {
      return null;
    }
    return transitionExpiredSession(active.id);
  }

  /// Applies the persisted state-machine transition for one active session.
  Future<PomodoroLog?> transitionExpiredSession(String id) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.pomodoroLogs)
            ..where(
              (p) => p.id.equals(id) & p.deletedAt.isNull(),
            ))
          .getSingleOrNull();
      if (row == null || row.endedAt != 0) {
        return _readActiveSession();
      }
      final timestamp = _now;
      if (!_isExpired(row, timestamp) || row.mode == flowtimeMode) {
        return row;
      }

      if (row.mode == classicMode) {
        final completedRound = (row.cycleRound + 1).clamp(1, 4);
        final focusDeadline = _deadline(row);
        await _finishRow(
          row,
          endedAt: focusDeadline,
          cycleRound: completedRound,
        );
        await _incrementTodoPomodoros(row.todoId, focusDeadline);

        final breakSession = await _createBreak(
          row,
          completedRound: completedRound,
          startedAt: focusDeadline,
        );
        final breakDeadline = _deadline(breakSession);
        if (timestamp >= breakDeadline) {
          await _finishRow(
            breakSession,
            endedAt: breakDeadline,
          );
          return null;
        }
        return breakSession;
      }

      await _finishRow(row, endedAt: _deadline(row));
      if (_countsAsPomodoro(row.mode)) {
        await _incrementTodoPomodoros(row.todoId, _deadline(row));
      }
      return null;
    });
  }

  Future<PomodoroLog?> finishSession(String id, {int? actualMinutes}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.pomodoroLogs)
            ..where((p) => p.id.equals(id)))
          .getSingle();
      if (row.endedAt != 0) {
        return _readActiveSession();
      }

      final timestamp = _now;
      if (row.mode == classicMode) {
        final completedRound = (row.cycleRound + 1).clamp(1, 4);
        await _finishRow(
          row,
          endedAt: timestamp,
          actualMinutes: actualMinutes,
          cycleRound: completedRound,
        );
        await _incrementTodoPomodoros(row.todoId, timestamp);
        return _createBreak(
          row,
          completedRound: completedRound,
          startedAt: timestamp,
        );
      }

      await _finishRow(
        row,
        endedAt: timestamp,
        actualMinutes: actualMinutes,
      );
      if (_countsAsPomodoro(row.mode)) {
        await _incrementTodoPomodoros(row.todoId, timestamp);
      }
      return null;
    });
  }

  Future<void> cancelSession(String id) =>
      (_db.update(_db.pomodoroLogs)..where((p) => p.id.equals(id))).write(
        PomodoroLogsCompanion(
          deletedAt: Value(_now),
          updatedAt: Value(_now),
        ),
      );

  /// Returns the current persisted classic round, not a widget-local counter.
  Future<int> currentCycleRound() async {
    final active = await _readActiveSession();
    if (active != null &&
        (active.mode == classicMode || _isBreak(active.mode))) {
      return active.cycleRound;
    }
    final latest = await _latestClassicLog();
    final round = latest?.cycleRound ?? 0;
    return round >= 4 ? 0 : round;
  }

  Future<int> todayFocusMinutes() async {
    final dayStart = DateTime.fromMillisecondsSinceEpoch(_now).copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final rows = await (_db.select(_db.pomodoroLogs)
          ..where(
            (p) =>
                p.deletedAt.isNull() &
                p.startedAt.isBiggerOrEqualValue(
                  dayStart.millisecondsSinceEpoch,
                ),
          ))
        .get();

    return rows
        .where((row) => !_isBreak(row.mode))
        .fold<int>(0, (sum, row) => sum + row.durationMinutes);
  }

  Future<int> todayFocusSessionCount() async {
    final dayStart = DateTime.fromMillisecondsSinceEpoch(_now).copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final rows = await (_db.select(_db.pomodoroLogs)
          ..where(
            (p) =>
                p.deletedAt.isNull() &
                p.endedAt.isBiggerThanValue(0) &
                p.startedAt.isBiggerOrEqualValue(
                  dayStart.millisecondsSinceEpoch,
                ),
          ))
        .get();

    return rows.where((row) => _countsAsPomodoro(row.mode)).length;
  }

  Future<PomodoroLog?> _readActiveSession() => (_db.select(_db.pomodoroLogs)
        ..where((p) => p.deletedAt.isNull() & p.endedAt.equals(0))
        ..limit(1))
      .getSingleOrNull();

  Future<PomodoroLog?> _latestClassicLog() => (_db.select(_db.pomodoroLogs)
        ..where((p) => p.deletedAt.isNull() & p.mode.equals(classicMode))
        ..orderBy([
          (p) => OrderingTerm(
                expression: p.startedAt,
                mode: OrderingMode.desc,
              ),
        ])
        ..limit(1))
      .getSingleOrNull();

  Future<int> _nextClassicRound() async {
    final latest = await _latestClassicLog();
    final round = latest?.cycleRound ?? 0;
    return round >= 4 ? 0 : round.clamp(0, 3);
  }

  bool _isExpired(PomodoroLog row, int timestamp) =>
      row.durationMinutes > 0 && timestamp >= _deadline(row);

  bool _isBreak(String mode) => mode == shortBreakMode || mode == longBreakMode;

  bool _countsAsPomodoro(String mode) =>
      mode == classicMode || mode == flowtimeMode || mode == countdownMode;

  int _deadline(PomodoroLog row) =>
      row.startedAt + row.durationMinutes * Duration.millisecondsPerMinute;

  Future<PomodoroLog> _createBreak(
    PomodoroLog focus, {
    required int completedRound,
    required int startedAt,
  }) async {
    final breakSpec = breakForCompletedRound(completedRound);
    final breakId = newUlid();
    await _db.into(_db.pomodoroLogs).insert(
          PomodoroLogsCompanion.insert(
            id: breakId,
            todoId: Value(focus.todoId),
            durationMinutes: breakSpec.minutes,
            mode: Value(breakSpec.mode),
            cycleRound: Value(completedRound),
            startedAt: startedAt,
            endedAt: 0,
            createdAt: startedAt,
            updatedAt: startedAt,
          ),
        );
    return (_db.select(_db.pomodoroLogs)..where((p) => p.id.equals(breakId)))
        .getSingle();
  }

  Future<void> _finishRow(
    PomodoroLog row, {
    required int endedAt,
    int? actualMinutes,
    int? cycleRound,
  }) =>
      (_db.update(_db.pomodoroLogs)..where((p) => p.id.equals(row.id))).write(
        PomodoroLogsCompanion(
          endedAt: Value(endedAt),
          durationMinutes: actualMinutes == null
              ? const Value.absent()
              : Value(actualMinutes),
          cycleRound:
              cycleRound == null ? const Value.absent() : Value(cycleRound),
          updatedAt: Value(endedAt),
        ),
      );

  Future<void> _incrementTodoPomodoros(String? todoId, int timestamp) async {
    if (todoId == null) {
      return;
    }
    final todo = await (_db.select(_db.todos)
          ..where((row) => row.id.equals(todoId)))
        .getSingleOrNull();
    if (todo == null) {
      return;
    }
    await (_db.update(_db.todos)..where((row) => row.id.equals(todoId))).write(
      TodosCompanion(
        actualPomodoros: Value(todo.actualPomodoros + 1),
        updatedAt: Value(timestamp),
      ),
    );
  }
}
