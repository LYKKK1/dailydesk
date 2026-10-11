import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final todoRepositoryProvider = Provider<TodoRepository>(
  (ref) => throw UnimplementedError(
    'todoRepositoryProvider must be overridden by the app composition root',
  ),
);
