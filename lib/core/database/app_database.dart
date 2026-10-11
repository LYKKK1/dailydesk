import 'package:dailydesk/core/database/tables.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Todos,
    Subtasks,
    Schedules,
    Memos,
    PomodoroLogs,
    Habits,
    HabitRecords,
    SyncDevices,
    WidgetLayouts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(pomodoroLogs, pomodoroLogs.cycleRound);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS '
            'pomodoro_logs_one_active_idx '
            'ON pomodoro_logs (ended_at) '
            'WHERE deleted_at IS NULL AND ended_at = 0',
          );
        },
      );
}
