import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/todos/presentation/widgets/slidable_todo_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_database.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = TodoRepository(db);
  });

  tearDown(() => db.close());

  Future<Todo> insertTodo({
    String title = '滑我',
    int priority = 1,
    String? dueDate,
  }) async {
    await repo.insertTodo(
      title: title,
      priority: priority,
      dueDate: dueDate,
    );
    return (db.select(db.todos)..where((t) => t.title.equals(title)))
        .getSingle();
  }

  Widget host(Todo todo) {
    return MaterialApp(
      home: Scaffold(
        body: SlidableTodoTile(todo: todo, repo: repo),
      ),
    );
  }

  testWidgets('右滑展开绿色完成操作并持久化完成状态', (tester) async {
    final todo = await insertTodo();
    await tester.pumpWidget(host(todo));
    await tester.pumpAndSettle();

    await tester.drag(find.text('滑我'), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    final updated = await (db.select(db.todos)
          ..where((t) => t.id.equals(todo.id)))
        .getSingle();
    expect(updated.status, 'completed');
  });

  testWidgets('左滑可将待办推迟到明天', (tester) async {
    final todo = await insertTodo();
    await tester.pumpWidget(host(todo));
    await tester.pumpAndSettle();

    await tester.drag(find.text('滑我'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('推迟到明天'));
    await tester.pumpAndSettle();

    final updated = await (db.select(db.todos)
          ..where((t) => t.id.equals(todo.id)))
        .getSingle();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final expected =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    expect(updated.dueDate, expected);
  });

  testWidgets('左滑移入收集箱会清空截止日期并取消置顶', (tester) async {
    final todo = await insertTodo(dueDate: '2025-10-13', priority: 0);
    await repo.updateIsTop(todo.id, true);
    final updatedTodo = await (db.select(db.todos)
          ..where((t) => t.id.equals(todo.id)))
        .getSingle();

    await tester.pumpWidget(host(updatedTodo));
    await tester.pumpAndSettle();
    await tester.drag(find.text('滑我'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移入收集箱'));
    await tester.pumpAndSettle();

    final updated = await (db.select(db.todos)
          ..where((t) => t.id.equals(todo.id)))
        .getSingle();
    expect(updated.dueDate, isNull);
    expect(updated.isTop, isFalse);
  });

  testWidgets('左滑删除使用软删除', (tester) async {
    final todo = await insertTodo();
    await tester.pumpWidget(host(todo));
    await tester.pumpAndSettle();

    await tester.drag(find.text('滑我'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    final deleted = await (db.select(db.todos)
          ..where((t) => t.id.equals(todo.id)))
        .getSingle();
    expect(deleted.deletedAt, isNotNull);
  });
}
