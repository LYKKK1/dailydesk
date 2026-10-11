import 'package:dailydesk/features/calendar/data/schedule_repository.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';
import 'package:dailydesk/features/memos/data/memo_repository.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:flutter/widgets.dart';

class DashboardServices {
  const DashboardServices({
    this.todoRepository,
    this.pomodoroRepository,
    this.habitRepository,
    this.memoRepository,
    this.scheduleRepository,
  });

  final TodoRepository? todoRepository;
  final PomodoroRepository? pomodoroRepository;
  final HabitRepository? habitRepository;
  final MemoRepository? memoRepository;
  final ScheduleRepository? scheduleRepository;
}

class DashboardServicesScope extends InheritedWidget {
  const DashboardServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final DashboardServices services;

  static DashboardServices? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DashboardServicesScope>()
      ?.services;

  @override
  bool updateShouldNotify(DashboardServicesScope oldWidget) =>
      oldWidget.services != services;
}
