import 'dart:async';

import 'package:dailydesk/features/sop/services/sop_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

List<SopSlot> defaultSopTemplate() => [
      SopSlot(
        title: '晨间唤醒',
        time: '08:30',
        checkpoints: const ['温水 500ml', '开窗', '查看日历'],
      ),
      SopSlot(title: '深度工作 I', time: '09:30', checkpoints: const []),
      SopSlot(title: '午休', time: '12:00', checkpoints: const []),
      SopSlot(title: '深度工作 II', time: '14:00', checkpoints: const []),
      SopSlot(title: '晚间复盘', time: '21:00', checkpoints: const []),
    ];

class SopCard extends StatefulWidget {
  const SopCard({
    super.key,
    this.initialSlots = const [],
    this.onChanged,
    this.onFocus,
    this.clock,
  });

  final List<SopSlot> initialSlots;
  final ValueChanged<List<SopSlot>>? onChanged;
  final Future<void> Function(SopSlot slot)? onFocus;
  final DateTime Function()? clock;

  @override
  State<SopCard> createState() => _SopCardState();
}

class _SopCardState extends State<SopCard> {
  late List<SopSlot> _slots;
  Timer? _ticker;
  late DateTime _now;
  late int _dayKey;
  final Set<int> _expanded = {};

  DateTime get _clock => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _now = _clock;
    _dayKey = _dateKey(_now);
    _slots = widget.initialSlots.isEmpty
        ? defaultSopTemplate()
        : _cloneSlots(widget.initialSlots);
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant SopCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSlots != widget.initialSlots &&
        widget.initialSlots.isNotEmpty) {
      _slots = _cloneSlots(widget.initialSlots);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    final now = _clock;
    final nextDay = _dateKey(now);
    if (!mounted) return;
    if (nextDay != _dayKey) {
      _dayKey = nextDay;
      _slots = SopEngine.dailyReset(_slots);
      _notifyChanged();
    }
    setState(() => _now = now);
  }

  void _notifyChanged() => widget.onChanged?.call(_cloneSlots(_slots));

  static List<SopSlot> _cloneSlots(List<SopSlot> source) => source
      .map(
        (slot) => SopSlot(
          title: slot.title,
          time: slot.time,
          checkpoints: List.of(slot.checkpoints),
          done: slot.done,
        ),
      )
      .toList();

  void _toggleDone(int index) {
    setState(() => _slots[index].done = !_slots[index].done);
    _notifyChanged();
  }

  void _reset() {
    setState(() => _slots = SopEngine.dailyReset(_slots));
    _notifyChanged();
  }

  Future<void> _focus(SopSlot slot) async {
    final callback = widget.onFocus;
    if (callback == null) return;
    try {
      await callback(slot);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('无法启动专注：$error')),
      );
    }
  }

  Future<void> _edit() async {
    final edited = await showDialog<List<SopSlot>>(
      context: context,
      builder: (context) => _SopEditorDialog(slots: _slots),
    );
    if (edited == null || !mounted) return;
    setState(() => _slots = edited);
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final (done, total, percentage) = SopEngine.progress(_slots);
    final active = SopEngine.activeSlotIndex(_slots, _now);
    final next = SopEngine.untilNext(_slots, _now);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SOP · $done/$total 完成 (${(percentage * 100).round()}%)',
                style: theme.textTheme.titleSmall,
              ),
            ),
            IconButton(
              key: const Key('sop-reset'),
              tooltip: '重置今日进度',
              visualDensity: VisualDensity.compact,
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 18),
            ),
            IconButton(
              key: const Key('sop-edit'),
              tooltip: '编辑节点',
              visualDensity: VisualDensity.compact,
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: percentage),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _slots.length,
            itemBuilder: (context, index) {
              final slot = _slots[index];
              final isActive = index == active;
              return AnimatedContainer(
                key: isActive ? const Key('active-slot') : null,
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.7)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.45)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 4),
                      leading: Checkbox(
                        value: slot.done,
                        onChanged: (_) => _toggleDone(index),
                      ),
                      title: Text(
                        slot.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        isActive
                            ? '${slot.time} · 距下一节点 ${next.inMinutes} 分钟'
                            : slot.time,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '开始专注',
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.onFocus == null
                                ? null
                                : () => _focus(slot),
                            icon: const Text('🍅'),
                          ),
                          if (slot.checkpoints.isNotEmpty)
                            IconButton(
                              tooltip: '细项',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() {
                                if (!_expanded.add(index)) {
                                  _expanded.remove(index);
                                }
                              }),
                              icon: Icon(
                                _expanded.contains(index)
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_expanded.contains(index))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(52, 0, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in slot.checkpoints)
                              Text('• $item', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                ),
              )
                  .animate(target: isActive ? 1 : 0)
                  .fade(begin: 0.72, end: 1, duration: 900.ms);
            },
          ),
        ),
      ],
    );
  }

  static int _dateKey(DateTime value) =>
      value.year * 10000 + value.month * 100 + value.day;
}

class _SopEditorDialog extends StatefulWidget {
  const _SopEditorDialog({required this.slots});

  final List<SopSlot> slots;

  @override
  State<_SopEditorDialog> createState() => _SopEditorDialogState();
}

class _SopEditorDialogState extends State<_SopEditorDialog> {
  late List<SopSlot> _draft;

  @override
  void initState() {
    super.initState();
    _draft = _SopCardState._cloneSlots(widget.slots);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑 SOP 节点'),
      content: SizedBox(
        width: 440,
        height: 380,
        child: ListView.builder(
          itemCount: _draft.length,
          itemBuilder: (context, index) {
            final slot = _draft[index];
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: slot.title,
                    decoration: const InputDecoration(labelText: '节点'),
                    onChanged: (value) => _draft[index] = SopSlot(
                      title: value,
                      time: slot.time,
                      checkpoints: slot.checkpoints,
                      done: slot.done,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: TextFormField(
                    initialValue: slot.time,
                    decoration: const InputDecoration(labelText: '时间'),
                    onChanged: (value) => _draft[index] = SopSlot(
                      title: slot.title,
                      time: value,
                      checkpoints: slot.checkpoints,
                      done: slot.done,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: () => setState(() => _draft.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(
            () => _draft.add(
              SopSlot(title: '新节点', time: '12:00', checkpoints: const []),
            ),
          ),
          child: const Text('＋ 节点'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _draft),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
