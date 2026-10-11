import 'dart:io';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() => db.close());

  test('all nine tables are created', () async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    for (final table in [
      'todos',
      'subtasks',
      'schedules',
      'memos',
      'pomodoro_logs',
      'habits',
      'habit_records',
      'sync_devices',
      'widget_layouts',
    ]) {
      expect(names, contains(table), reason: 'missing table $table');
    }
  });

  test('file databases use WAL mode', () async {
    await db.close();
    final dir = await Directory.systemTemp.createTemp('dd_db');
    addTearDown(() => dir.delete(recursive: true));
    final fileDb = AppDatabase(NativeDatabase(File('${dir.path}/test.db')));
    addTearDown(fileDb.close);

    final row = await fileDb.customSelect('PRAGMA journal_mode').getSingle();

    expect(row.read<String>('journal_mode').toLowerCase(), 'wal');
  });

  test('foreign key checks are enabled', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();

    expect(row.read<int>('foreign_keys'), 1);
  });

  test('schema v1 migrates pomodoro cycle_round with default zero', () async {
    final dir = await Directory.systemTemp.createTemp('dd_pomodoro_migration');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/legacy.db';

    final initial = AppDatabase(NativeDatabase(File(path)));
    await initial.into(initial.pomodoroLogs).insert(
          PomodoroLogsCompanion.insert(
            id: 'legacy-log',
            durationMinutes: 25,
            startedAt: 100,
            endedAt: 200,
            createdAt: 100,
            updatedAt: 200,
          ),
        );
    await initial.customStatement(
      'ALTER TABLE pomodoro_logs RENAME TO pomodoro_logs_v2',
    );
    await initial.customStatement('''
      CREATE TABLE pomodoro_logs (
        id TEXT NOT NULL PRIMARY KEY,
        todo_id TEXT,
        duration_minutes INTEGER NOT NULL,
        mode TEXT NOT NULL DEFAULT 'pomodoro',
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await initial.customStatement('''
      INSERT INTO pomodoro_logs (
        id, todo_id, duration_minutes, mode, started_at, ended_at,
        created_at, updated_at, deleted_at
      )
      SELECT id, todo_id, duration_minutes, mode, started_at, ended_at,
        created_at, updated_at, deleted_at
      FROM pomodoro_logs_v2
    ''');
    await initial.customStatement('DROP TABLE pomodoro_logs_v2');
    await initial.customStatement('PRAGMA user_version = 1');
    await initial.close();

    final migrated = AppDatabase(NativeDatabase(File(path)));
    addTearDown(migrated.close);
    final row = await (migrated.select(migrated.pomodoroLogs)
          ..where((log) => log.id.equals('legacy-log')))
        .getSingle();
    final version =
        await migrated.customSelect('PRAGMA user_version').getSingle();

    expect(row.cycleRound, 0);
    expect(version.read<int>('user_version'), 2);
  });
}
