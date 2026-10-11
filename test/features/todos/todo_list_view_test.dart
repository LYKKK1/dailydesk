import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/audio/sound_manager.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/todos/presentation/todo_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Widget host(Widget child) {
    return ProviderScope(
      overrides: [todoRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('今日视图渲染待办并支持勾选完成', (tester) async {
    await repo.insertTodo(title: '任务A', priority: 0);

    await tester.pumpWidget(host(const TodoListView()));
    await tester.pumpAndSettle();

    expect(find.text('任务A'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    final updated = await (db.select(db.todos)
          ..where((t) => t.title.equals('任务A')))
        .getSingle();
    expect(updated.status, 'completed');
  });

  testWidgets('收集箱仅渲染无截止日期且未完成的任务', (tester) async {
    await repo.insertTodo(title: '收集箱任务');
    await repo.insertTodo(title: '今日任务', dueDate: '2025-10-13');

    await tester.pumpWidget(host(const TodoListView()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('收集箱'));
    await tester.pumpAndSettle();

    expect(find.text('收集箱任务'), findsOneWidget);
    expect(find.text('今日任务'), findsNothing);
  });

  testWidgets('行内表单回车插入标题、优先级和番茄预算', (tester) async {
    await tester.pumpWidget(host(const TodoListView()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('todo-title-input')), '任务B');
    await tester.tap(find.byKey(const Key('todo-priority-input')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('P1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('todo-pomodoro-input')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final inserted = await (db.select(db.todos)
          ..where((t) => t.title.equals('任务B')))
        .getSingle();
    expect(inserted.priority, 1);
    expect(inserted.estimatedPomodoros, 2);
  });

  testWidgets('四象限视图按优先级分区渲染', (tester) async {
    await repo.insertTodo(title: '紧急任务', priority: 0);
    await repo.insertTodo(title: '备选任务', priority: 3);

    await tester.pumpWidget(host(const MatrixView()));
    await tester.pumpAndSettle();

    expect(find.text('紧急任务'), findsOneWidget);
    expect(find.text('备选任务'), findsOneWidget);
    expect(find.text('P0 紧急且重要'), findsOneWidget);
    expect(find.text('P3 不紧急不重要'), findsOneWidget);
  });

  testWidgets('拖拽到另一象限后持久化新优先级', (tester) async {
    await repo.insertTodo(title: '跨象限任务', priority: 0);

    await tester.pumpWidget(host(const MatrixView()));
    await tester.pumpAndSettle();

    final todoFinder = find.text('跨象限任务');
    final targetFinder = find.byKey(const Key('matrix-quadrant-2'));
    await tester.drag(todoFinder, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('跨象限任务'), findsOneWidget);
    final updated = await (db.select(db.todos)
          ..where((t) => t.title.equals('跨象限任务')))
        .getSingle();
    expect(updated.priority, 2);
    expect(find.byKey(const Key('matrix-quadrant-2')), findsOneWidget);
    expect(targetFinder, findsOneWidget);
  });

  test('禁用 SoundManager 时播放调用安全返回', () async {
    SoundManager.instance.enabled = false;
    addTearDown(() => SoundManager.instance.enabled = true);

    await SoundManager.instance.playPop();
  });
}
