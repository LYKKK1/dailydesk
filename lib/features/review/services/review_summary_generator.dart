import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:drift/drift.dart';

class ReviewData {
  const ReviewData({
    required this.completedCount,
    required this.overdueCount,
    required this.focusMinutes,
    required this.pomodoroCount,
    required this.habitResults,
  });

  final int completedCount;
  final int overdueCount;
  final int focusMinutes;
  final int pomodoroCount;
  final Map<String, bool> habitResults;
}

Future<ReviewData> collectDailyData(AppDatabase db) async {
  final todos = TodoRepository(db);
  final pomodoro = PomodoroRepository(db);
  final habits = HabitRepository(db);

  final today = DateTime.now();
  final todayKey = _ymd(today);
  final dayStart =
      DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;

  final allTodos = await todos.watchTodos().first;
  final completedCount = allTodos.where((todo) {
    return todo.status == 'completed' && todo.updatedAt >= dayStart;
  }).length;
  final overdueCount = allTodos.where((todo) {
    return todo.status == 'pending' &&
        todo.dueDate != null &&
        todo.dueDate!.compareTo(todayKey) < 0;
  }).length;

  final focusMinutes = await pomodoro.todayFocusMinutes();
  final completedSessions = await pomodoro.todayFocusSessionCount();
  final pomodoroCount =
      completedSessions > 0 ? completedSessions : focusMinutes ~/ 25;
  final habitList = await habits.watchHabits().first;
  final todayHabitRecords = await (db.select(db.habitRecords)
        ..where(
          (record) =>
              record.recordDate.equals(todayKey) & record.deletedAt.isNull(),
        ))
      .get();
  final checkedHabitIds =
      todayHabitRecords.map((record) => record.habitId).toSet();
  final habitResults = <String, bool>{};
  for (final habit in habitList) {
    habitResults[habit.name] = checkedHabitIds.contains(habit.id);
  }

  return ReviewData(
    completedCount: completedCount,
    overdueCount: overdueCount,
    focusMinutes: focusMinutes,
    pomodoroCount: pomodoroCount,
    habitResults: habitResults,
  );
}

String renderMarkdown(
  ReviewData data, {
  String? wins,
  String? losses,
  List<String>? tomorrowTop3,
}) {
  final buffer = StringBuffer()
    ..writeln('# 每日复盘 · ${_ymd(DateTime.now())}')
    ..writeln()
    ..writeln('## 📊 今日成果')
    ..writeln(
      '- ✅ 完成 ${data.completedCount} 项'
      '${data.overdueCount > 0 ? '，⚠️ 逾期未完 ${data.overdueCount} 项' : ''}',
    )
    ..writeln(
      '- 🍅 专注 ${data.focusMinutes} 分钟，累计 ${data.pomodoroCount} 个番茄',
    )
    ..writeln('- 🏃 习惯：');

  if (data.habitResults.isEmpty) {
    buffer.writeln('  - 暂无习惯记录');
  } else {
    data.habitResults.forEach((name, done) {
      buffer.writeln('  - ${done ? '🟢' : '⚪'} $name');
    });
  }

  buffer
    ..writeln()
    ..writeln('## 📝 今日得失');
  if (wins?.trim().isNotEmpty == true) {
    buffer.writeln('- 💡 收获：${wins!.trim()}');
  }
  buffer.writeln(
      '- ❓ 哪些事项超时？主要干扰项是什么？→ ${losses?.trim().isNotEmpty == true ? losses!.trim() : '（待补充）'}');

  buffer
    ..writeln()
    ..writeln('## 🎯 明日核心 (Top 3)');
  final topThree = tomorrowTop3 ?? const <String>[];
  if (topThree.isEmpty) {
    buffer.writeln('- （待补充）');
  } else {
    for (final item in topThree.where((item) => item.trim().isNotEmpty)) {
      buffer.writeln('- ${item.trim()}');
    }
  }

  return buffer.toString();
}

String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
