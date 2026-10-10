import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';

class PomodoroRepository {
  PomodoroRepository(this._db);

  final AppDatabase _db;

  Future<void> startSession({
    String? todoId,
    String mode = 'pomodoro',
    int plannedMinutes = 25,
  }) async {
    final active = await watchActiveSession().first;
    if (active != null) {
      throw StateError('已有进行中的专注会话 ${active.id}');
    }

    await _db.into(_db.pomodoroLogs).insert(
          PomodoroLogsCompanion.insert(
            id: newUlid(),
            todoId: Value(todoId),
            durationMinutes: plannedMinutes,
            mode: Value(mode),
            startedAt: nowMs(),
            endedAt: 0,
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Stream<PomodoroLog?> watchActiveSession() => (_db.select(_db.pomodoroLogs)
        ..where((p) => p.deletedAt.isNull() & p.endedAt.equals(0))
        ..limit(1))
      .watch()
      .map((rows) => rows.isEmpty ? null : rows.single);

  Future<void> finishSession(String id, {int? actualMinutes}) async {
    final row = await (_db.select(_db.pomodoroLogs)
          ..where((p) => p.id.equals(id)))
        .getSingle();

    await (_db.update(_db.pomodoroLogs)..where((p) => p.id.equals(id))).write(
      PomodoroLogsCompanion(
        endedAt: Value(nowMs()),
        durationMinutes: Value(actualMinutes ?? row.durationMinutes),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> cancelSession(String id) =>
      (_db.update(_db.pomodoroLogs)..where((p) => p.id.equals(id))).write(
        PomodoroLogsCompanion(
          deletedAt: Value(nowMs()),
          updatedAt: Value(nowMs()),
        ),
      );

  Future<int> todayFocusMinutes() async {
    final dayStart = DateTime.now().copyWith(
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

    return rows.fold<int>(0, (sum, row) => sum + row.durationMinutes);
  }
}
