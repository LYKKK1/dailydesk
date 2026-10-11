import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';

class MergeDecision {
  const MergeDecision({
    required this.takeRemote,
    this.resurrect = false,
  });

  final bool takeRemote;
  final bool resurrect;
}

/// Last-write-wins decision for one row.
MergeDecision decideLww({
  required int localUpdatedAt,
  required int remoteUpdatedAt,
  required int? localDeletedAt,
  required int? remoteDeletedAt,
}) {
  if (remoteUpdatedAt <= localUpdatedAt) {
    return const MergeDecision(takeRemote: false);
  }

  if (remoteDeletedAt != null) {
    return const MergeDecision(takeRemote: true);
  }

  if (localDeletedAt != null) {
    return const MergeDecision(takeRemote: true, resurrect: true);
  }

  return const MergeDecision(takeRemote: true);
}

class MergeResult {
  MergeResult(this.applied, this.conflictsCopied);

  final int applied;
  final int conflictsCopied;
}

const _concurrentWindowMs = 30000;

/// Applies a complete diff inside one transaction.
Future<MergeResult> applyDiff(
  AppDatabase db,
  Map<String, dynamic> diff,
) async {
  var applied = 0;
  var conflictsCopied = 0;
  final rawTables = diff['tables'];
  if (rawTables != null && rawTables is! Map) {
    throw const FormatException('diff.tables must be an object');
  }
  final tables = (rawTables as Map?) ?? const <String, dynamic>{};

  await db.transaction(() async {
    final memoResult = await _mergeMemos(db, _rowsFor(tables, 'memos'));
    applied += memoResult.$1;
    conflictsCopied += memoResult.$2;

    applied += await _mergePlainRows<Todo>(
      rows: _rowsFor(tables, 'todos'),
      decode: Todo.fromJson,
      readLocal: (id) => (db.select(db.todos)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull(),
      insertRemote: (remote) => db.into(db.todos).insert(remote),
      updateRemote: (remote) => (db.update(db.todos)
            ..where((row) => row.id.equals(remote.id)))
          .write(remote.toCompanion(false)),
      updatedAt: (remote) => remote.updatedAt,
      deletedAt: (remote) => remote.deletedAt,
    );

    applied += await _mergePlainRows<Subtask>(
      rows: _rowsFor(tables, 'subtasks'),
      decode: Subtask.fromJson,
      readLocal: (id) => (db.select(db.subtasks)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull(),
      insertRemote: (remote) => db.into(db.subtasks).insert(remote),
      updateRemote: (remote) => (db.update(db.subtasks)
            ..where((row) => row.id.equals(remote.id)))
          .write(remote.toCompanion(false)),
      updatedAt: (remote) => remote.updatedAt,
      deletedAt: (remote) => remote.deletedAt,
    );

    applied += await _mergePlainRows<Schedule>(
      rows: _rowsFor(tables, 'schedules'),
      decode: Schedule.fromJson,
      readLocal: (id) => (db.select(db.schedules)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull(),
      insertRemote: (remote) => db.into(db.schedules).insert(remote),
      updateRemote: (remote) => (db.update(db.schedules)
            ..where((row) => row.id.equals(remote.id)))
          .write(remote.toCompanion(false)),
      updatedAt: (remote) => remote.updatedAt,
      deletedAt: (remote) => remote.deletedAt,
    );

    applied += await _mergePlainRows<PomodoroLog>(
      rows: _rowsFor(tables, 'pomodoro_logs'),
      decode: (raw) {
        final normalized = _normalizeRow(raw);
        normalized.putIfAbsent('cycleRound', () => 0);
        return PomodoroLog.fromJson(normalized);
      },
      readLocal: (id) => (db.select(db.pomodoroLogs)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull(),
      insertRemote: (remote) => db.into(db.pomodoroLogs).insert(remote),
      updateRemote: (remote) => (db.update(db.pomodoroLogs)
            ..where((row) => row.id.equals(remote.id)))
          .write(remote.toCompanion(false)),
      updatedAt: (remote) => remote.updatedAt,
      deletedAt: (remote) => remote.deletedAt,
    );

    applied += await _mergePlainRows<Habit>(
      rows: _rowsFor(tables, 'habits'),
      decode: Habit.fromJson,
      readLocal: (id) => (db.select(db.habits)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull(),
      insertRemote: (remote) => db.into(db.habits).insert(remote),
      updateRemote: (remote) => (db.update(db.habits)
            ..where((row) => row.id.equals(remote.id)))
          .write(remote.toCompanion(false)),
      updatedAt: (remote) => remote.updatedAt,
      deletedAt: (remote) => remote.deletedAt,
    );

    applied += await _mergeHabitRecords(db, _rowsFor(tables, 'habit_records'));

    applied += await _mergePlainRows<WidgetLayout>(
      rows: _rowsFor(tables, 'widget_layouts'),
      decode: WidgetLayout.fromJson,
      readLocal: (id) => (db.select(db.widgetLayouts)
            ..where((row) => row.id.equals(id)))
          .getSingleOrNull(),
      insertRemote: (remote) => db.into(db.widgetLayouts).insert(remote),
      updateRemote: (remote) => (db.update(db.widgetLayouts)
            ..where((row) => row.id.equals(remote.id)))
          .write(remote.toCompanion(false)),
      updatedAt: (remote) => remote.updatedAt,
      deletedAt: (remote) => remote.deletedAt,
    );
  });

  return MergeResult(applied, conflictsCopied);
}

Future<(int, int)> _mergeMemos(
  AppDatabase db,
  List<dynamic> rows,
) async {
  var applied = 0;
  var conflictsCopied = 0;

  for (final raw in rows) {
    final remote = Memo.fromJson(_normalizeRow(raw));
    final local = await (db.select(db.memos)
          ..where((row) => row.id.equals(remote.id)))
        .getSingleOrNull();

    if (local == null) {
      await db.into(db.memos).insert(remote);
      applied++;
      continue;
    }

    final decision = decideLww(
      localUpdatedAt: local.updatedAt,
      remoteUpdatedAt: remote.updatedAt,
      localDeletedAt: local.deletedAt,
      remoteDeletedAt: remote.deletedAt,
    );
    if (!decision.takeRemote) {
      continue;
    }

    final delta = (remote.updatedAt - local.updatedAt).abs();
    if (delta < _concurrentWindowMs && remote.content != local.content) {
      final backupTimestamp = DateTime.now();
      final displayTimestamp =
          backupTimestamp.toString().split('.').first.replaceFirst('T', ' ');
      await db.into(db.memos).insert(
            MemosCompanion.insert(
              id: newUlid(),
              content: '[同步冲突备份-$displayTimestamp] ${local.content}',
              tag: Value(local.tag),
              colorHex: Value(local.colorHex),
              isPinned: const Value(false),
              createdAt: nowMs(),
              updatedAt: nowMs(),
            ),
          );
      conflictsCopied++;
    }

    await (db.update(db.memos)..where((row) => row.id.equals(remote.id)))
        .write(remote.toCompanion(false));
    applied++;
  }

  return (applied, conflictsCopied);
}

Future<int> _mergeHabitRecords(
  AppDatabase db,
  List<dynamic> rows,
) async {
  var applied = 0;

  for (final raw in rows) {
    final remote = HabitRecord.fromJson(_normalizeRow(raw));
    final local = await (db.select(db.habitRecords)
          ..where(
            (row) =>
                row.id.equals(remote.id) |
                (row.habitId.equals(remote.habitId) &
                    row.recordDate.equals(remote.recordDate)),
          )
          ..limit(1))
        .getSingleOrNull();
    if (local == null) {
      await db.into(db.habitRecords).insert(remote);
      applied++;
      continue;
    }

    final decision = decideLww(
      localUpdatedAt: local.updatedAt,
      remoteUpdatedAt: remote.updatedAt,
      localDeletedAt: local.deletedAt,
      remoteDeletedAt: remote.deletedAt,
    );
    if (!decision.takeRemote) {
      continue;
    }

    await (db.update(db.habitRecords)..where((row) => row.id.equals(local.id)))
        .write(remote.toCompanion(false));
    applied++;
  }

  return applied;
}

Future<int> _mergePlainRows<T extends DataClass>({
  required List<dynamic> rows,
  required T Function(Map<String, dynamic>) decode,
  required Future<T?> Function(String id) readLocal,
  required Future<void> Function(T remote) insertRemote,
  required Future<void> Function(T remote) updateRemote,
  required int Function(T remote) updatedAt,
  required int? Function(T remote) deletedAt,
}) async {
  var applied = 0;

  for (final raw in rows) {
    final remote = decode(_normalizeRow(raw));
    final local = await readLocal(_idOf(remote));
    if (local == null) {
      await insertRemote(remote);
      applied++;
      continue;
    }

    final decision = decideLww(
      localUpdatedAt: updatedAt(local),
      remoteUpdatedAt: updatedAt(remote),
      localDeletedAt: deletedAt(local),
      remoteDeletedAt: deletedAt(remote),
    );
    if (!decision.takeRemote) {
      continue;
    }

    await updateRemote(remote);
    applied++;
  }

  return applied;
}

String _idOf(DataClass row) {
  final value = row.toJson()['id'];
  if (value is! String) {
    throw const FormatException('row.id must be a string');
  }
  return value;
}

List<dynamic> _rowsFor(Map<dynamic, dynamic> tables, String table) {
  final rows = tables[table];
  if (rows == null) {
    return const [];
  }
  if (rows is! List) {
    throw FormatException('diff.tables.$table must be a list');
  }
  return rows;
}

Map<String, dynamic> _normalizeRow(dynamic raw) {
  if (raw is! Map) {
    throw const FormatException('diff row must be an object');
  }

  final row = Map<String, dynamic>.from(raw);
  for (final entry in Map<String, dynamic>.from(row).entries) {
    if (!entry.key.contains('_')) {
      continue;
    }
    final camelKey = _camelCase(entry.key);
    row.putIfAbsent(camelKey, () => entry.value);
  }
  return row;
}

String _camelCase(String value) {
  final parts = value.split('_');
  if (parts.isEmpty) {
    return value;
  }
  return parts.first +
      parts.skip(1).map((part) {
        if (part.isEmpty) {
          return '';
        }
        return '${part[0].toUpperCase()}${part.substring(1)}';
      }).join();
}
