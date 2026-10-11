import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/sync/services/diff_packager.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() => database.close());

  test('提取 checkpoint 之后的变更，并保留软删除墓碑', () async {
    await database.into(database.todos).insert(
          TodosCompanion.insert(
            id: 'old-todo',
            title: '旧任务',
            createdAt: 100,
            updatedAt: 100,
          ),
        );
    await database.into(database.todos).insert(
          TodosCompanion.insert(
            id: 'new-todo',
            title: '新任务',
            createdAt: 300,
            updatedAt: 300,
          ),
        );
    await (database.update(database.todos)
          ..where((todo) => todo.id.equals('old-todo')))
        .write(
      const TodosCompanion(
        deletedAt: Value(400),
        updatedAt: Value(400),
      ),
    );

    final diff = await buildDiff(database, 200, clock: () => 500);
    final todos = (diff['tables'] as Map)['todos'] as List;
    final byId = {
      for (final row in todos) (row as Map)['id']: row,
    };

    expect(diff['generated_at'], 500);
    expect(byId.keys, containsAll(<String>{'old-todo', 'new-todo'}));
    expect((byId['old-todo'] as Map)['deleted_at'], 400);
    expect((byId['new-todo'] as Map)['updated_at'], 300);
  });

  test('没有晚于 checkpoint 的变更时返回空表', () async {
    await database.into(database.todos).insert(
          TodosCompanion.insert(
            id: 'todo',
            title: '任务',
            createdAt: 100,
            updatedAt: 100,
          ),
        );

    final diff = await buildDiff(database, 100, clock: () => 200);

    expect((diff['tables'] as Map)['todos'], isEmpty);
  });
}
