import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';

class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  Stream<List<Habit>> watchHabits() =>
      (_db.select(_db.habits)..where((habit) => habit.deletedAt.isNull()))
          .watch();

  Future<void> insertHabit({
    required String name,
    required String frequencyType,
    int? targetDaysPerWeek,
  }) async {
    final now = nowMs();
    await _db.into(_db.habits).insert(
          HabitsCompanion.insert(
            id: newUlid(),
            name: name,
            frequencyType: frequencyType,
            targetDaysPerWeek: Value(targetDaysPerWeek),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> toggleCheckIn(String habitId, String recordDate) async {
    final existing = await (_db.select(_db.habitRecords)
          ..where(
            (record) =>
                record.habitId.equals(habitId) &
                record.recordDate.equals(recordDate),
          ))
        .get();

    if (existing.isNotEmpty) {
      final row = existing.single;
      final now = nowMs();
      await (_db.update(_db.habitRecords)
            ..where((record) => record.id.equals(row.id)))
          .write(
        HabitRecordsCompanion(
          deletedAt: Value(row.deletedAt == null ? now : null),
          updatedAt: Value(now),
        ),
      );
      return;
    }

    final now = nowMs();
    await _db.into(_db.habitRecords).insert(
          HabitRecordsCompanion.insert(
            id: '${habitId}_$recordDate',
            habitId: habitId,
            recordDate: recordDate,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<List<String>> recordDates(String habitId) async {
    final records = await (_db.select(_db.habitRecords)
          ..where(
            (record) =>
                record.habitId.equals(habitId) & record.deletedAt.isNull(),
          ))
        .get();

    return records.map((record) => record.recordDate).toSet().toList()..sort();
  }

  static int currentStreak(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    final dates = sortedDates.toSet();
    var anchor = DateTime.now();

    if (!dates.contains(_ymd(anchor))) {
      anchor = anchor.subtract(const Duration(days: 1));
      if (!dates.contains(_ymd(anchor))) return 0;
    }

    var streak = 0;
    while (dates.contains(_ymd(anchor))) {
      streak++;
      anchor = anchor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static double strengthScore(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    final dates = sortedDates.toSet();
    final today = DateTime.now();
    var score = 0.0;

    for (var daysAgo = 0; daysAgo < 60; daysAgo++) {
      final date = today.subtract(Duration(days: daysAgo));
      if (dates.contains(_ymd(date))) {
        score += 1 / (daysAgo + 1);
      }
    }

    return (score / 4.6).clamp(0.0, 1.0).toDouble();
  }

  static String _ymd(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
