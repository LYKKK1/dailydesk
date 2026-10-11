import 'dart:async';
import 'dart:math' as math;

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/review/services/review_summary_generator.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyReviewView extends StatefulWidget {
  const DailyReviewView({
    super.key,
    required this.database,
  });

  final AppDatabase database;

  @override
  State<DailyReviewView> createState() => _DailyReviewViewState();
}

class _DailyReviewViewState extends State<DailyReviewView> {
  static const _quotes = [
    '把今天写下来，明天就会更清楚。',
    '完成比完美更接近自由。',
    '稳定的小步，胜过偶发的冲刺。',
    '注意力在哪里，成果就在哪里。',
    '先做最重要的一件事。',
    '清晰的边界保护真正的专注。',
    '复盘不是审判，而是校准。',
    '慢下来，才能看见真正的进展。',
    '把复杂留给系统，把简单留给今天。',
    '每一次完成，都是一次自我确认。',
    '先记录，再优化。',
    '真正有效的方法，往往足够朴素。',
    '今天的遗憾，可以成为明天的线索。',
    '不要用忙碌替代选择。',
    '持续，是最被低估的竞争力。',
    '把承诺写小，把行动做深。',
    '情绪需要被看见，任务需要被拆开。',
    '一个明确的下一步，胜过十个模糊愿望。',
    '留白也是生产力。',
    '结果来自节奏，不来自焦虑。',
    '先把门打开，再考虑走多远。',
    '真正重要的目标值得重复确认。',
    '用事实结束一天，用选择开始一天。',
    '专注不是拒绝世界，而是暂时安放世界。',
    '每天回收一点掌控感。',
    '好的系统会替疲惫的你做决定。',
    '让完成留下证据。',
    '失败是数据，不是身份。',
    '明天只安排三个核心。',
    '今天到此为止，也是一种完成。',
  ];

  final _winsController = TextEditingController();
  final _lossesController = TextEditingController();
  final _selectedTodos = <String>{};

  Timer? _reviewTimer;
  ReviewData? _data;
  String? _markdown;
  bool _loading = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _scheduleReviewPrompt();
  }

  @override
  void dispose() {
    _reviewTimer?.cancel();
    _winsController.dispose();
    _lossesController.dispose();
    super.dispose();
  }

  void _scheduleReviewPrompt() {
    final now = DateTime.now();
    var nextReview = DateTime(now.year, now.month, now.day, 21);
    if (!nextReview.isAfter(now)) {
      nextReview = nextReview.add(const Duration(days: 1));
    }
    _reviewTimer = Timer(nextReview.difference(now), () {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('到晚间复盘时间了'),
            action: SnackBarAction(
              label: '生成',
              onPressed: () => unawaited(_generate()),
            ),
          ),
        );
      _scheduleReviewPrompt();
    });
  }

  Future<void> _generate() async {
    if (_loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await collectDailyData(widget.database);
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _markdown = _render();
      });
    } catch (error) {
      if (mounted) {
        _showMessage('生成失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _render() {
    final data = _data;
    if (data == null) {
      return '';
    }
    return renderMarkdown(
      data,
      wins: _winsController.text,
      losses: _lossesController.text,
      tomorrowTop3: _selectedTodos.toList(),
    );
  }

  void _refreshPreview() {
    if (_data != null && mounted) {
      setState(() => _markdown = _render());
    }
  }

  Future<void> _copyMarkdown() async {
    final markdown = _markdown;
    if (markdown == null || markdown.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _showMessage('复盘 Markdown 已复制');
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleTopThree(String todoId) {
    setState(() {
      if (_selectedTodos.remove(todoId)) {
        return;
      }
      if (_selectedTodos.length < 3) {
        _selectedTodos.add(todoId);
      }
    });
    _refreshPreview();
  }

  @override
  Widget build(BuildContext context) {
    final todoRepository = TodoRepository(widget.database);
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '每日复盘',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '用事实收尾，为明天留下清晰入口',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      key: const Key('generate-review'),
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_data == null ? '生成复盘' : '重新生成'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DailyQuote(quote: _quotes[_quoteIndex()]),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('review-wins'),
                  controller: _winsController,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => _refreshPreview(),
                  decoration: const InputDecoration(
                    labelText: '今日收获',
                    hintText: '今天有哪些值得保留的进展？',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('review-losses'),
                  controller: _lossesController,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => _refreshPreview(),
                  decoration: const InputDecoration(
                    labelText: '今日得失',
                    hintText: '哪些事项超时？主要干扰项是什么？',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '明日核心 Top 3',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${_selectedTodos.length}/3',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<Todo>>(
                  stream: todoRepository.watchTodos(),
                  builder: (context, snapshot) {
                    final todos = (snapshot.data ?? const <Todo>[])
                        .where((todo) => todo.status != 'completed')
                        .toList(growable: false);
                    if (todos.isEmpty) {
                      return Text(
                        '待办池为空',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final todo in todos)
                          ChoiceChip(
                            key: ValueKey('review-todo-${todo.id}'),
                            label: Text(todo.title),
                            selected: _selectedTodos.contains(todo.id),
                            onSelected: (_) => _toggleTopThree(todo.id),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (_markdown != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '复盘预览',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('copy-review'),
                        onPressed: _copyMarkdown,
                        icon: Icon(
                          _copied ? Icons.check : Icons.copy_all_outlined,
                        ),
                        label: const Text('复制 Markdown'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: SelectableText(
                      _markdown!,
                      key: const Key('review-preview'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _quoteIndex() {
    final origin = DateTime(2020);
    return math.max(
          0,
          DateTime.now().difference(origin).inDays,
        ) %
        _quotes.length;
  }
}

class _DailyQuote extends StatelessWidget {
  const _DailyQuote({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quote,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
