import 'dart:async';

import 'package:dailydesk/features/quick_capture/nlp_quick_parser.dart';
import 'package:dailydesk/features/todos/presentation/todo_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickCaptureView extends ConsumerStatefulWidget {
  const QuickCaptureView({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  ConsumerState<QuickCaptureView> createState() => _QuickCaptureViewState();
}

class _QuickCaptureViewState extends ConsumerState<QuickCaptureView> {
  final TextEditingController _textController = TextEditingController();
  late final FocusNode _focusNode;
  bool _hasFocused = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (_focusNode.hasFocus) {
          _hasFocused = true;
        } else if (_hasFocused && !_submitting) {
          _dismiss();
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _textController.clear();
    widget.onDismiss();
  }

  Future<void> _submit(String raw) async {
    final value = raw.trim();
    if (value.isEmpty || _submitting) {
      return;
    }

    final parsed = parseCapture(value);
    setState(() => _submitting = true);
    try {
      await ref.read(todoRepositoryProvider).insertTodo(
            title: parsed.title.isEmpty ? value : parsed.title,
            priority: parsed.priority ?? 1,
            dueDate: parsed.dueDate,
            dueTime: parsed.dueTime,
            categoryId: parsed.tag,
          );

      if (!mounted) {
        return;
      }

      // TODO(hook-sound): play the 40 ms pop sound when Task 3.1 lands.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已写入收集箱'),
          duration: Duration(milliseconds: 700),
        ),
      );
      _dismiss();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error')),
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 660,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.98),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Icon(Icons.bolt_rounded, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('quick-capture-input'),
                    controller: _textController,
                    focusNode: _focusNode,
                    autofocus: true,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) => unawaited(_submit(value)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '记录待办或灵感，例如：明天下午3点开会 !P0 #工作',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: '保存',
                          onPressed: () =>
                              unawaited(_submit(_textController.text)),
                          icon: const Icon(Icons.keyboard_return_rounded),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
