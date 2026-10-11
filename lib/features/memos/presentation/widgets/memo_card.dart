import 'package:dailydesk/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MemoCard extends StatelessWidget {
  const MemoCard({
    super.key,
    required this.memo,
    this.onConvertToTodo,
    this.onTogglePin,
  });

  final Memo memo;
  final Future<void> Function(Memo memo)? onConvertToTodo;
  final ValueChanged<Memo>? onTogglePin;

  @override
  Widget build(BuildContext context) {
    final color = memoColor(memo.colorHex);
    return AnimatedContainer(
      key: Key('memo-card-${memo.id}'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: markdownBody(memo.content),
              ),
              IconButton(
                key: Key('memo-pin-${memo.id}'),
                tooltip: memo.isPinned ? '取消置顶' : '置顶',
                visualDensity: VisualDensity.compact,
                onPressed:
                    onTogglePin == null ? null : () => onTogglePin!(memo),
                icon: Icon(
                  memo.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (memo.tag?.isNotEmpty == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${memo.tag}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              const Spacer(),
              TextButton(
                key: Key('memo-convert-${memo.id}'),
                onPressed: onConvertToTodo == null
                    ? null
                    : () => onConvertToTodo!(memo),
                child: const Text('转待办 →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget markdownBody(String source) => MarkdownBody(
      data: source,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 15,
          height: 1.45,
          color: Color(0xFF242424),
        ),
        code: const TextStyle(
          fontFamily: 'monospace',
          backgroundColor: Color(0x22000000),
        ),
      ),
    );

Color memoColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return const Color(0xFFF9F9FB);
  return Color(0xFF000000 | value);
}
