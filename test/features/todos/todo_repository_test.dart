import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TodoRepository(db);
  });
  tearDown(() => db.close());

  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('插入自动生成 ULID 与时间戳', () async {
    await repo.insertTodo(title: '写周报', priority: 0);
    final all = await repo.watchTodos().first;
    expect(all.single.title, '写周报');
    expect(all.single.id.length, 26); // ULID 长度
    expect(all.single.createdAt, greaterThan(0));
  });

  test('watchTodayTodos 聚合 过期+今日+置顶，排除未来未置顶', () async {
    final now = DateTime.now();
    await repo.insertTodo(
      title: '过期任务',
      priority: 1,
      dueDate: ymd(now.subtract(const Duration(days: 1))),
    );
    await repo.insertTodo(title: '今日任务', priority: 1, dueDate: ymd(now));
    await repo.insertTodo(
      title: '未来任务',
      priority: 1,
      dueDate: ymd(now.add(const Duration(days: 5))),
    );
    final titles =
        (await repo.watchTodayTodos().first).map((t) => t.title).toSet();
    expect(titles, containsAll(['过期任务', '今日任务']));
    expect(titles.contains('未来任务'), isFalse);
  });

  test('置顶任务进入今日视图', () async {
    await repo.insertTodo(title: '置顶无日期', priority: 1);
    final t = (await repo.watchTodos().first).single;
    await repo.updateIsTop(t.id, true);
    final titles = (await repo.watchTodayTodos().first).map((x) => x.title);
    expect(titles, contains('置顶无日期'));
  });

  test('软删除不物理删除（供同步）', () async {
    await repo.insertTodo(title: '将删');
    final all = await repo.watchTodos().first;
    await repo.softDeleteTodo(all.single.id);
    expect(await repo.watchTodos().first, isEmpty);
    final raw =
        await db.customSelect('SELECT COUNT(*) c FROM todos').getSingle();
    expect(raw.read<int>('c'), 1);
  });

  test('更新待办时自动刷新 updated_at', () async {
    await repo.insertTodo(title: '原标题');
    final original = (await repo.watchTodos().first).single;

    await repo.updateTodo(original.copyWith(title: '新标题', updatedAt: 1));

    final updated = (await repo.watchTodos().first).single;
    expect(updated.title, '新标题');
    expect(updated.updatedAt, greaterThan(1));
  });

  test('全部子任务完成后返回主任务 id', () async {
    await repo.insertTodo(title: '主任务');
    final todo = (await repo.watchTodos().first).single;
    await db.into(db.subtasks).insert(SubtasksCompanion.insert(
          id: 'sub-1',
          todoId: todo.id,
          title: '子任务 1',
          createdAt: 1,
          updatedAt: 1,
        ));
    await db.into(db.subtasks).insert(SubtasksCompanion.insert(
          id: 'sub-2',
          todoId: todo.id,
          title: '子任务 2',
          createdAt: 1,
          updatedAt: 1,
        ));

    expect(await repo.toggleSubtask('sub-1'), isNull);
    expect(await repo.toggleSubtask('sub-2'), todo.id);
  });
}
