import 'package:dailydesk/core/audio/sound_manager.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/theme/app_colors.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/todos/presentation/todo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'matrix_view.dart';
export 'todo_providers.dart';

class TodoListView extends ConsumerStatefulWidget {
  const TodoListView({super.key, this.onFocusRequested});

  final ValueChanged<Todo>? onFocusRequested;

  @override
  ConsumerState<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends ConsumerState<TodoListView> {
  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(todoRepositoryProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '今日聚焦'),
              Tab(text: '收集箱'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: _QuickAddForm(repository: repository),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _TodoList(
                  stream: repository.watchFocusTodos(),
                  repository: repository,
                  emptyLabel: '今天没有待办',
                  onFocusRequested: widget.onFocusRequested,
                ),
                _TodoList(
                  stream: repository.watchInboxTodos(),
                  repository: repository,
                  emptyLabel: '收集箱是空的',
                  onFocusRequested: widget.onFocusRequested,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddForm extends StatefulWidget {
  const _QuickAddForm({required this.repository});

  final TodoRepository repository;

  @override
  State<_QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends State<_QuickAddForm> {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _dueTimeController = TextEditingController();
  int _priority = 1;
  int _pomodoroBudget = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _dueTimeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    final dueTime = _normalizeTime(_dueTimeController.text);
    await widget.repository.insertTodo(
      title: title,
      priority: _priority,
      dueDate: dueTime == null ? null : _ymd(DateTime.now()),
      dueTime: dueTime,
      estimatedPomodoros: _pomodoroBudget,
    );
    _titleController.clear();
    _dueTimeController.clear();
  }

  void _restoreTitleFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _titleFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('todo-title-input'),
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: '快速添加待办',
                      prefixIcon: Icon(Icons.add_task),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _submit,
                  tooltip: '添加',
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<int>(
                  key: const Key('todo-priority-input'),
                  value: _priority,
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    for (var priority = 0; priority < 4; priority++)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(
                          'P$priority',
                          style: TextStyle(
                            color: AppColors.priorityColor(priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                      _restoreTitleFocus();
                    }
                  },
                ),
                DropdownButton<int>(
                  key: const Key('todo-pomodoro-input'),
                  value: _pomodoroBudget,
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    for (var count = 1; count <= 3; count++)
                      DropdownMenuItem(value: count, child: Text('$count')),
                  ],
                  selectedItemBuilder: (context) => [
                    for (var count = 1; count <= 3; count++)
                      Center(child: Text('🍅$count')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _pomodoroBudget = value);
                      _restoreTitleFocus();
                    }
                  },
                ),
                SizedBox(
                  width: 108,
                  child: TextField(
                    key: const Key('todo-due-time-input'),
                    controller: _dueTimeController,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      hintText: '17:00',
                      prefixIcon: Icon(
                        Icons.schedule,
                        color: colorScheme.primary,
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String? _normalizeTime(String raw) {
    final value = raw.trim();
    final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) {
      return null;
    }
    final hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  static String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.stream,
    required this.repository,
    required this.emptyLabel,
    required this.onFocusRequested,
  });

  final Stream<List<Todo>> stream;
  final TodoRepository repository;
  final String emptyLabel;
  final ValueChanged<Todo>? onFocusRequested;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Todo>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final todos = snapshot.requireData;
        if (todos.isEmpty) {
          return Center(child: Text(emptyLabel));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: todos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final todo = todos[index];
            return _TodoRow(
              key: ValueKey(todo.id),
              todo: todo,
              repository: repository,
              onFocusRequested: onFocusRequested,
            );
          },
        );
      },
    );
  }
}

class _TodoRow extends StatefulWidget {
  const _TodoRow({
    super.key,
    required this.todo,
    required this.repository,
    required this.onFocusRequested,
  });

  final Todo todo;
  final TodoRepository repository;
  final ValueChanged<Todo>? onFocusRequested;

  @override
  State<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends State<_TodoRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final completed = todo.status == 'completed';
    final priorityColor = AppColors.priorityColor(todo.priority);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          dense: true,
          leading: Checkbox(
            value: completed,
            onChanged: completed ? null : (_) => _complete(),
          ),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              decoration: completed ? TextDecoration.lineThrough : null,
              color: completed
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface,
            ),
            child: Text(todo.title),
          ),
          subtitle: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'P${todo.priority}',
                style: TextStyle(
                  color: priorityColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (todo.dueTime != null) Text(todo.dueTime!),
              Text('🍅${todo.estimatedPomodoros}'),
            ],
          ),
          children: [
            const ListTile(
              dense: true,
              leading: Icon(Icons.subdirectory_arrow_right),
              title: Text('暂无子任务'),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: _hovered ? 1 : 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: '立即专注',
                    onPressed: () => widget.onFocusRequested?.call(todo),
                    icon: const Icon(Icons.play_arrow),
                  ),
                  PopupMenuButton<int>(
                    tooltip: '切换优先级',
                    icon: const Icon(Icons.label_outline),
                    onSelected: _changePriority,
                    itemBuilder: (context) => [
                      for (var priority = 0; priority < 4; priority++)
                        PopupMenuItem(
                          value: priority,
                          child: Text('P$priority'),
                        ),
                    ],
                  ),
                  IconButton(
                    tooltip: '快速删除',
                    onPressed: () => widget.repository.softDeleteTodo(todo.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete() async {
    await Future.wait([
      widget.repository.updateTodo(
        widget.todo.copyWith(status: 'completed'),
      ),
      SoundManager.instance.playPop(),
    ]);
  }

  Future<void> _changePriority(int priority) {
    return widget.repository.updateTodo(
      widget.todo.copyWith(priority: priority),
    );
  }
}
