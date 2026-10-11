import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/holidays.dart';
import 'package:dailydesk/features/calendar/data/schedule_repository.dart';
import 'package:dailydesk/features/calendar/presentation/calendar_view.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_database.dart';

void main() {
  group('holidayMark', () {
    test('2025-10-01 国庆为休', () {
      expect(holidayMark(DateTime(2025, 10, 1)), '休');
    });

    test('2025-10-11 调休补班为班', () {
      expect(holidayMark(DateTime(2025, 10, 11)), '班');
    });

    test('普通工作日无标记', () {
      expect(holidayMark(DateTime(2025, 10, 13)), isNull);
    });

    test('2026 节假日表已内置', () {
      expect(holidayMark(DateTime(2026, 1, 1)), '休');
      expect(holidayMark(DateTime(2026, 2, 17)), '休');
    });
  });

  group('TimeBlockTimeline', () {
    late AppDatabase db;
    late TodoRepository todoRepo;
    late ScheduleRepository scheduleRepo;

    setUp(() {
      db = createTestDatabase();
      todoRepo = TodoRepository(db);
      scheduleRepo = ScheduleRepository(db);
    });

    tearDown(() => db.close());

    testWidgets('渲染默认工作区间的半小时时间槽', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeBlockTimeline(
              repository: scheduleRepo,
              todos: const [],
              day: DateTime(2025, 10, 13),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(
        find.byKey(const Key('time-slot-2025-10-13-10:00')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('拖入时间槽会创建一小时排期并回写待办日期', (tester) async {
      await todoRepo.insertTodo(title: '安排我');
      final todo = (await db.select(db.todos).get()).single;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeBlockTimeline(
              repository: scheduleRepo,
              todos: [todo],
              day: DateTime(2025, 10, 13),
              initialScrollTime: const TimeOfDay(hour: 10, minute: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final slot = find.byKey(const Key('time-slot-2025-10-13-10:00'));
      await tester.ensureVisible(slot);
      final dragStart = tester.getCenter(find.text('安排我'));
      final dragEnd = tester.getCenter(slot);
      await tester.dragFrom(dragStart, dragEnd - dragStart);
      await tester.pumpAndSettle();

      final schedules = await db.select(db.schedules).get();
      expect(schedules, hasLength(1));
      expect(schedules.single.title, '安排我');
      expect(
        DateTime.fromMillisecondsSinceEpoch(schedules.single.startTime).hour,
        10,
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(schedules.single.startTime).minute,
        0,
      );

      final updated = await (db.select(db.todos)
            ..where((t) => t.id.equals(todo.id)))
          .getSingle();
      expect(updated.dueTime, '10:00');
    });
  });

  testWidgets('CalendarView 支持日周月切换并显示节假日标记', (tester) async {
    final db = createTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarView(
            repository: ScheduleRepository(db),
            todos: const [],
            initialDate: DateTime(2025, 10, 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('日'), findsOneWidget);
    expect(find.text('周'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-day-2025-10-01')), findsOneWidget);
    expect(find.text('休'), findsWidgets);
  });
}
