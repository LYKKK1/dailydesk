import 'dart:async';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/theme/app_colors.dart';
import 'package:dailydesk/features/memos/data/memo_repository.dart';
import 'package:dailydesk/features/memos/presentation/widgets/contribution_dots.dart';
import 'package:dailydesk/features/memos/presentation/widgets/memo_card.dart';
import 'package:dailydesk/features/memos/presentation/widgets/tag_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MemosView extends StatefulWidget {
  const MemosView({
    super.key,
    required this.repository,
    this.onTogglePin,
  });

  final MemoRepository repository;
  final ValueChanged<Memo>? onTogglePin;

  @override
  State<MemosView> createState() => _MemosViewState();
}

class _MemosViewState extends State<MemosView> {
  final _composerController = TextEditingController();
  final _pinOverrides = <String, bool>{};

  String? _selectedTag;
  int _selectedColor = 0;
  String? _composerTag = '闪念';
  bool _publishing = false;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final content = _composerController.text.trim();
    if (content.isEmpty || _publishing) return;
    setState(() => _publishing = true);
    try {
      await widget.repository.insertMemo(
        content: content,
        tag: _composerTag,
        colorHex: _colorHex(AppColors.morandiPalette[_selectedColor]),
      );
      _composerController.clear();
      if (!mounted) return;
      if (Scaffold.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已发布')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _convert(Memo memo) async {
    await widget.repository.convertToTodo(memo.id);
    unawaited(SystemSound.play(SystemSoundType.click));
    if (!mounted) return;
    if (Scaffold.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已转待办')),
      );
    }
  }

  void _togglePin(Memo memo) {
    final next = !(_pinOverrides[memo.id] ?? memo.isPinned);
    setState(() => _pinOverrides[memo.id] = next);
    widget.onTogglePin?.call(memo);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(
                LogicalKeyboardKey.enter,
                control: true,
              ): () => unawaited(_publish()),
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 14),
                _buildComposer(context),
                const SizedBox(height: 10),
                TagFilterBar(
                  selectedTag: _selectedTag,
                  onSelected: (tag) => setState(() => _selectedTag = tag),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildFeed()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '灵感随手记',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                '捕捉一闪而过的想法',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        StreamBuilder<List<Memo>>(
          stream: widget.repository.watchMemos(),
          builder: (context, snapshot) {
            final byDate = <String, List<String>>{};
            for (final memo in snapshot.data ?? const <Memo>[]) {
              final date = DateTime.fromMillisecondsSinceEpoch(memo.createdAt);
              final key = _ymd(date);
              byDate.putIfAbsent(key, () => []).add(memo.content);
            }
            return ContributionDots(counts: last30DaysCounts(byDate));
          },
        ),
      ],
    );
  }

  Widget _buildComposer(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('memo-composer'),
              controller: _composerController,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: '现在在想什么？支持 Markdown',
                border: InputBorder.none,
              ),
            ),
            const Divider(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final tag in memoFilterTags)
                  ChoiceChip(
                    key: ValueKey('memo-composer-tag-$tag'),
                    label: Text('#$tag'),
                    selected: _composerTag == tag,
                    onSelected: (_) => setState(() => _composerTag = tag),
                  ),
                const SizedBox(width: 8),
                for (var index = 0;
                    index < AppColors.morandiPalette.length;
                    index++)
                  _ColorDot(
                    color: AppColors.morandiPalette[index],
                    selected: _selectedColor == index,
                    onTap: () => setState(() => _selectedColor = index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Ctrl+Enter 发布',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _publishing ? null : () => unawaited(_publish()),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('发布'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder<List<Memo>>(
      stream: widget.repository.watchMemos(tag: _selectedTag),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }
        final memos = snapshot.data ?? const <Memo>[];
        if (memos.isEmpty) {
          return const Center(child: Text('还没有便签，写下第一条灵感吧'));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 280).floor().clamp(1, 4);
            final columnItems = List.generate(columns, (_) => <Memo>[]);
            for (var index = 0; index < memos.length; index++) {
              columnItems[index % columns].add(memos[index]);
            }
            return SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < columns; index++) ...[
                    Expanded(
                      child: Column(
                        children: [
                          for (final memo in columnItems[index])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MemoCard(
                                memo: memo.copyWith(
                                  isPinned:
                                      _pinOverrides[memo.id] ?? memo.isPinned,
                                ),
                                onConvertToTodo: _convert,
                                onTogglePin: _togglePin,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (index != columns - 1) const SizedBox(width: 12),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _colorHex(Color color) {
    final rgb = (color.r * 255).round() << 16 |
        (color.g * 255).round() << 8 |
        (color.b * 255).round();
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '便签底色',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black12,
              width: selected ? 2 : 1,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 14, color: Colors.black87)
              : null,
        ),
      ),
    );
  }
}
