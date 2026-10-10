import 'dart:io';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
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

    final row = await fileDb
        .customSelect('PRAGMA journal_mode')
        .getSingle();

    expect(row.read<String>('journal_mode').toLowerCase(), 'wal');
  });

  test('foreign key checks are enabled', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();

    expect(row.read<int>('foreign_keys'), 1);
  });
}
