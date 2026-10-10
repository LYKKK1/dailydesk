import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HabitRepository(db);
  });

  tearDown(() => db.close());

  String ymd(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  test('打卡幂等：同日重复 toggle 为取消', () async {
    await repo.insertHabit(name: '饮水', frequencyType: 'daily');
    final habit = (await db.select(db.habits).get()).single;

    await repo.toggleCheckIn(habit.id, '2025-10-10');
    expect(await repo.recordDates(habit.id), ['2025-10-10']);

    await repo.toggleCheckIn(habit.id, '2025-10-10');
    expect(await repo.recordDates(habit.id), isEmpty);
  });

  group('currentStreak 纯函数', () {
    test('连续日期跨月边界后保持连续', () {
      final today = DateTime.now();
      final dates = [
        ymd(today.subtract(const Duration(days: 2))),
        ymd(today.subtract(const Duration(days: 1))),
        ymd(today),
      ];

      expect(HabitRepository.currentStreak(dates), 3);
    });

    test('跳日中断', () {
      final today = DateTime.now();
      final dates = [
        ymd(today.subtract(const Duration(days: 2))),
        ymd(today),
      ];

      expect(HabitRepository.currentStreak(dates), 1);
    });

    test('今天未打但昨天连着，streak 保留', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(HabitRepository.currentStreak([ymd(yesterday)]), 1);
    });

    test('空列表为 0', () {
      expect(HabitRepository.currentStreak([]), 0);
    });
  });

  test('strengthScore 在 0~1 区间且近期打卡得分更高', () {
    final today = DateTime.now();
    final recent = [
      ymd(today),
      ymd(today.subtract(const Duration(days: 1))),
    ];
    final old = [ymd(today.subtract(const Duration(days: 50)))];

    expect(
      HabitRepository.strengthScore(recent),
      greaterThan(HabitRepository.strengthScore(old)),
    );
    expect(HabitRepository.strengthScore(recent), lessThanOrEqualTo(1.0));
    expect(HabitRepository.strengthScore(recent), greaterThanOrEqualTo(0.0));
  });
}
