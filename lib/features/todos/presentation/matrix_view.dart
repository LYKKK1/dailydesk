import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/theme/app_colors.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/todos/presentation/todo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatrixView extends ConsumerWidget {
  const MatrixView({super.key});

  // Eisenhower geometry: urgent work sits on the top row, important work
  // sits on the left column. This keeps P0 -> P2 a horizontal move.
  static const _gridPriorities = [0, 2, 1, 3];

  static const _titles = [
    'P0 紧急且重要',
    'P1 重要不紧急',
    'P2 紧急不重要',
    'P3 不紧急不重要',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(todoRepositoryProvider);

    return StreamBuilder<List<Todo>>(
      stream: repository.watchTodos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = snapshot.requireData
            .where((todo) => todo.status != 'completed')
            .toList();
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final priority = _gridPriorities[index];
            return _Quadrant(
              key: Key('matrix-quadrant-$priority'),
              title: _titles[priority],
              priority: priority,
              todos: todos.where((todo) => todo.priority == priority).toList(),
              repository: repository,
            );
          },
        );
      },
    );
  }
}

class _Quadrant extends StatefulWidget {
  const _Quadrant({
    super.key,
    required this.title,
    required this.priority,
    required this.todos,
    required this.repository,
  });

  final String title;
  final int priority;
  final List<Todo> todos;
  final TodoRepository repository;

  @override
  State<_Quadrant> createState() => _QuadrantState();
}

class _QuadrantState extends State<_Quadrant> {
  bool _draggingOver = false;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(widget.priority);

    return DragTarget<Todo>(
      onWillAcceptWithDetails: (details) =>
          details.data.priority != widget.priority,
      onAcceptWithDetails: (details) => widget.repository.updateTodo(
        details.data.copyWith(priority: widget.priority),
      ),
      onLeave: (_) => setState(() => _draggingOver = false),
      builder: (context, candidateData, rejectedData) {
        if (candidateData.isNotEmpty && !_draggingOver) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _draggingOver = true);
            }
          });
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _draggingOver ? color : color.withAlpha(60),
              width: _draggingOver ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.todos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    return _DraggableTodo(todo: widget.todos[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableTodo extends StatelessWidget {
  const _DraggableTodo({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final card = _TodoCard(todo: todo);
    return Draggable<Todo>(
      data: todo,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: card,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(todo.priority);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                todo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
