import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/sync/services/merge_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() => database.close());

  test('LWW 以较新的远端修改为准，并支持删除后复活', () {
    final decision = decideLww(
      localUpdatedAt: 100,
      remoteUpdatedAt: 200,
      localDeletedAt: 100,
      remoteDeletedAt: null,
    );

    expect(decision.takeRemote, isTrue);
    expect(decision.resurrect, isTrue);
  });

  test('旧远端变更不会覆盖本地版本', () {
    final decision = decideLww(
      localUpdatedAt: 300,
      remoteUpdatedAt: 200,
      localDeletedAt: null,
      remoteDeletedAt: null,
    );

    expect(decision.takeRemote, isFalse);
  });

  test('便签在 30 秒并发窗口内修改时生成冲突副本', () async {
    await database.into(database.memos).insert(
          MemosCompanion.insert(
            id: 'memo-1',
            content: '本地版本',
            createdAt: 100,
            updatedAt: 100,
          ),
        );

    final diff = {
      'v': 1,
      'generated_at': 3100,
      'tables': {
        'memos': [
          {
            'id': 'memo-1',
            'content': '远端版本',
            'colorHex': '#F9F9FB',
            'tag': null,
            'isPinned': false,
            'createdAt': 100,
            'updatedAt': 3100,
            'deletedAt': null,
          },
        ],
      },
    };

    final result = await applyDiff(database, diff);
    final rows = await database.select(database.memos).get();

    expect(result.applied, 1);
    expect(result.conflictsCopied, 1);
    expect(rows, hasLength(2));
    expect(
      rows.any((memo) => memo.id == 'memo-1' && memo.content == '远端版本'),
      isTrue,
    );
    expect(
      rows.any((memo) => memo.content.contains('同步冲突备份')),
      isTrue,
    );
  });

  test('普通表的远端墓碑可覆盖较旧本地行', () async {
    await database.into(database.todos).insert(
          TodosCompanion.insert(
            id: 'todo-1',
            title: '任务',
            createdAt: 100,
            updatedAt: 100,
          ),
        );

    final result = await applyDiff(database, {
      'tables': {
        'todos': [
          {
            'id': 'todo-1',
            'title': '任务',
            'description': null,
            'priority': 1,
            'status': 'pending',
            'dueDate': null,
            'dueTime': null,
            'categoryId': null,
            'isTop': false,
            'estimatedPomodoros': 1,
            'actualPomodoros': 0,
            'createdAt': 100,
            'updatedAt': 200,
            'deletedAt': 200,
          },
        ],
      },
    });
    final todo = await (database.select(database.todos)
          ..where((row) => row.id.equals('todo-1')))
        .getSingle();

    expect(result.applied, 1);
    expect(todo.deletedAt, 200);
  });

  test('旧 snake_case 番茄 diff 缺少 cycle_round 时按 0 解码', () async {
    final result = await applyDiff(database, {
      'tables': {
        'pomodoro_logs': [
          {
            'id': 'pomodoro-1',
            'todo_id': null,
            'duration_minutes': 25,
            'mode': 'pomodoro',
            'started_at': 100,
            'ended_at': 200,
            'created_at': 100,
            'updated_at': 200,
            'deleted_at': null,
          },
        ],
      },
    });
    final log = await (database.select(database.pomodoroLogs)
          ..where((row) => row.id.equals('pomodoro-1')))
        .getSingle();

    expect(result.applied, 1);
    expect(log.cycleRound, 0);
  });
}
