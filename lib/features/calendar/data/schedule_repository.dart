import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';

class ScheduleRepository {
  ScheduleRepository(this._db);

  final AppDatabase _db;

  Stream<List<Schedule>> watchSchedulesInRange(DateTime start, DateTime end) =>
      (_db.select(_db.schedules)
            ..where((s) =>
                s.deletedAt.isNull() &
                s.startTime.isBiggerOrEqualValue(start.millisecondsSinceEpoch) &
                s.startTime.isSmallerThanValue(end.millisecondsSinceEpoch)))
          .watch();

  Future<List<Schedule>> overlapping(DateTime start, DateTime end) =>
      (_db.select(_db.schedules)
            ..where((s) =>
                s.deletedAt.isNull() &
                s.startTime.isSmallerThanValue(end.millisecondsSinceEpoch) &
                s.endTime.isBiggerThanValue(start.millisecondsSinceEpoch)))
          .get();

  Future<Schedule> scheduleTodo({
    required String todoId,
    required String title,
    required DateTime start,
    required DateTime end,
    String colorHex = '#4A90E2',
  }) {
    return _db.transaction(() async {
      final timestamp = nowMs();
      final schedule = Schedule(
        id: newUlid(),
        todoId: todoId,
        title: title,
        startTime: start.millisecondsSinceEpoch,
        endTime: end.millisecondsSinceEpoch,
        allDay: false,
        colorHex: colorHex,
        createdAt: timestamp,
        updatedAt: timestamp,
        deletedAt: null,
      );
      await _db.into(_db.schedules).insert(schedule);
      await (_db.update(_db.todos)..where((t) => t.id.equals(todoId))).write(
        TodosCompanion(
          dueDate: Value(_ymd(start)),
          dueTime: Value(_hm(start)),
          updatedAt: Value(nowMs()),
        ),
      );
      return schedule;
    });
  }

  String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _hm(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
