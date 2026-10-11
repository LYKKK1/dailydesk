import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';

/// Extracts records changed after [lastSyncedAt], including tombstones.
Future<Map<String, dynamic>> buildDiff(
  AppDatabase db,
  int lastSyncedAt, {
  int Function()? clock,
}) async {
  final tables = <String, dynamic>{};

  tables['todos'] = await (db.select(db.todos)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);
  tables['subtasks'] = await (db.select(db.subtasks)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);
  tables['schedules'] = await (db.select(db.schedules)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);
  tables['memos'] = await (db.select(db.memos)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);
  tables['pomodoro_logs'] = await (db.select(db.pomodoroLogs)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);
  tables['habits'] = await (db.select(db.habits)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);
  tables['habit_records'] = await (db.select(db.habitRecords)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);
  tables['widget_layouts'] = await (db.select(db.widgetLayouts)
        ..where((row) => row.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then(_serializeRows);

  return {
    'v': 1,
    'generated_at': (clock ?? nowMs)(),
    'tables': tables,
  };
}

List<Map<String, dynamic>> _serializeRows<T extends DataClass>(
  List<T> rows,
) =>
    rows.map(_serializeRow).toList(growable: false);

Map<String, dynamic> _serializeRow(DataClass row) {
  final json = Map<String, dynamic>.from(row.toJson());
  for (final entry in Map<String, dynamic>.from(json).entries) {
    final snakeKey = _snakeCase(entry.key);
    json.putIfAbsent(snakeKey, () => entry.value);
  }
  return json;
}

String _snakeCase(String value) => value.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
