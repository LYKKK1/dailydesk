import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:drift/drift.dart';

class TodoRepository {
  TodoRepository(this._db);

  final AppDatabase _db;

  Stream<List<Todo>> watchTodos() =>
      (_db.select(_db.todos)..where((t) => t.deletedAt.isNull())).watch();

  /// 今日聚焦：截止日期不晚于今天或已置顶，且尚未完成（spec 5.1）。
  Stream<List<Todo>> watchTodayTodos() {
    final today = _ymd(DateTime.now());
    return (_db.select(_db.todos)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.status.equals('pending') &
              (t.dueDate.isSmallerOrEqualValue(today) | t.isTop.equals(true)))
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.isTop, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> insertTodo({
    required String title,
    int priority = 1,
    String? dueDate,
    String? dueTime,
    String? categoryId,
    int? estimatedPomodoros,
  }) {
    final timestamp = nowMs();
    return _db.into(_db.todos).insert(TodosCompanion.insert(
          id: newUlid(),
          title: title,
          priority: Value(priority),
          dueDate: Value(dueDate),
          dueTime: Value(dueTime),
          categoryId: Value(categoryId),
          estimatedPomodoros: estimatedPomodoros == null
              ? const Value.absent()
              : Value(estimatedPomodoros),
          createdAt: timestamp,
          updatedAt: timestamp,
        ));
  }

  Future<void> updateTodo(Todo todo) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(todo.id)))
          .write(todo.copyWith(updatedAt: nowMs()));

  Future<void> updateIsTop(String id, bool value) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(
          isTop: Value(value),
          updatedAt: Value(nowMs()),
        ),
      );

  Future<void> softDeleteTodo(String id) =>
      (_db.update(_db.todos)..where((t) => t.id.equals(id))).write(
        TodosCompanion(
          deletedAt: Value(nowMs()),
          updatedAt: Value(nowMs()),
        ),
      );

  /// 切换子任务；全部未删除子任务完成时返回所属待办 id。
  Future<String?> toggleSubtask(String subtaskId) async {
    final subtask = await (_db.select(_db.subtasks)
          ..where((s) => s.id.equals(subtaskId)))
        .getSingle();
    await (_db.update(_db.subtasks)..where((s) => s.id.equals(subtaskId)))
        .write(
      SubtasksCompanion(
        isCompleted: Value(!subtask.isCompleted),
        updatedAt: Value(nowMs()),
      ),
    );

    final siblings = await (_db.select(_db.subtasks)
          ..where(
              (s) => s.todoId.equals(subtask.todoId) & s.deletedAt.isNull()))
        .get();
    final allCompleted =
        siblings.isNotEmpty && siblings.every((s) => s.isCompleted);
    return allCompleted ? subtask.todoId : null;
  }

  String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
