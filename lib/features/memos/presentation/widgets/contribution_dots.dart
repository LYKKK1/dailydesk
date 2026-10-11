import 'package:flutter/material.dart';

List<int> last30DaysCounts(
  Map<String, List<String>> byDate, {
  DateTime? today,
}) {
  final anchor = today ?? DateTime.now();
  final day = DateTime(anchor.year, anchor.month, anchor.day);
  return List<int>.generate(30, (index) {
    final date = day.subtract(Duration(days: 29 - index));
    return byDate[_ymd(date)]?.length ?? 0;
  });
}

class ContributionDots extends StatelessWidget {
  const ContributionDots({
    super.key,
    required this.counts,
    this.today,
  });

  final List<int> counts;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final visibleCounts = counts.length >= 30
        ? counts.sublist(counts.length - 30)
        : <int>[...List.filled(30 - counts.length, 0), ...counts];

    return Semantics(
      label: '最近 30 天创作活跃度',
      child: Wrap(
        key: const Key('contribution-dots'),
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var index = 0; index < visibleCounts.length; index++)
            Tooltip(
              message:
                  '${_shortDate(index, today)} · ${visibleCounts[index]} 条',
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: contributionDotColor(visibleCounts[index]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _shortDate(int index, DateTime? anchor) {
    final now = anchor ?? DateTime.now();
    final date = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: 29 - index));
    return '${date.month}/${date.day}';
  }
}

Color contributionDotColor(int count) => switch (count) {
      0 => const Color(0xFFE7E9EA),
      1 => const Color(0xFFB8E6C5),
      2 => const Color(0xFF66C783),
      3 => const Color(0xFF2F9E55),
      _ => const Color(0xFF176B3A),
    };

String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
