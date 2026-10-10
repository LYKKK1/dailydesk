import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/calendar/data/schedule_repository.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ScheduleRepository repo;
  late TodoRepository todos;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ScheduleRepository(db);
    todos = TodoRepository(db);
  });
  tearDown(() => db.close());

  test('scheduleTodo 事务联动：生成时间块并回写 todo 截止时间', () async {
    await todos.insertTodo(title: '评审方案', priority: 0);
    final todo = (await db.select(db.todos).get()).single;
    final start = DateTime(2025, 10, 13, 10);
    await repo.scheduleTodo(
      todoId: todo.id,
      title: todo.title,
      start: start,
      end: start.add(const Duration(hours: 1)),
    );
    final blocks = await repo
        .watchSchedulesInRange(DateTime(2025, 10, 13), DateTime(2025, 10, 14))
        .first;
    expect(blocks.single.title, '评审方案');
    final updated = await (db.select(db.todos)
          ..where((t) => t.id.equals(todo.id)))
        .getSingle();
    expect(updated.dueDate, '2025-10-13');
    expect(updated.dueTime, '10:00');
  });

  test('overlapping 检出跨区间重叠', () async {
    final s = DateTime(2025, 10, 13, 9);
    await repo.scheduleTodo(
      todoId: 'x',
      title: 'A',
      start: s,
      end: s.add(const Duration(hours: 2)),
    );
    final hit = await repo.overlapping(
      s.add(const Duration(hours: 1)),
      s.add(const Duration(hours: 3)),
    );
    expect(hit, isNotEmpty);
  });
}
