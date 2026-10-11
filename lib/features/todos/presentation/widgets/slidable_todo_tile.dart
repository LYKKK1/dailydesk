import 'package:dailydesk/core/audio/sound_manager.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SlidableTodoTile extends StatelessWidget {
  const SlidableTodoTile({
    super.key,
    required this.todo,
    required this.repo,
  });

  final Todo todo;
  final TodoRepository repo;

  @override
  Widget build(BuildContext context) {
    final completed = todo.status == 'completed';

    return Slidable(
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _complete(),
            backgroundColor: const Color(0xFF52C41A),
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: '完成',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.75,
        openThreshold: 0.25,
        closeThreshold: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _deferToTomorrow(),
            backgroundColor: const Color(0xFFF5A524),
            foregroundColor: Colors.white,
            icon: Icons.update,
            label: '推迟到明天',
          ),
          SlidableAction(
            onPressed: (_) => _moveToInbox(),
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            icon: Icons.inbox,
            label: '移入收集箱',
          ),
          SlidableAction(
            onPressed: (_) => repo.softDeleteTodo(todo.id),
            backgroundColor: const Color(0xFFE5484D),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: completed,
          onChanged: completed ? null : (_) => _complete(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('P${todo.priority}'),
      ),
    );
  }

  Future<void> _complete() async {
    await repo.updateTodo(todo.copyWith(status: 'completed'));
    await HapticFeedback.lightImpact();
    await SoundManager.instance.playPop();
  }

  Future<void> _deferToTomorrow() {
    return repo.updateTodo(
      todo.copyWith(
          dueDate: Value(_ymd(DateTime.now().add(const Duration(days: 1))))),
    );
  }

  Future<void> _moveToInbox() {
    return repo.updateTodo(
      todo.copyWith(
        dueDate: const Value<String?>(null),
        isTop: false,
      ),
    );
  }

  String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
