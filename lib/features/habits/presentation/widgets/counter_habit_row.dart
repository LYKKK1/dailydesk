import 'dart:math' as math;

import 'package:dailydesk/core/audio/sound_manager.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:flutter/material.dart';

class CounterHabitRow extends StatelessWidget {
  const CounterHabitRow({
    super.key,
    required this.habit,
    this.currentValue = 0,
    this.target = 2000,
    this.step = 250,
    this.unit = 'ml',
    this.weekCompleted = const [],
    this.onChanged,
  });

  final Habit habit;
  final int currentValue;
  final int target;
  final int step;
  final String unit;
  final List<bool> weekCompleted;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final safeTarget = math.max(1, target);
    final progress = (currentValue / safeTarget).clamp(0.0, 1.0).toDouble();
    final completedDays = List<bool>.generate(
      7,
      (index) => index < weekCompleted.length && weekCompleted[index],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _habitColor(habit.colorHex).withAlpha(30),
                  child: Icon(
                    _habitIcon(habit.iconName),
                    color: _habitColor(habit.colorHex),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '$currentValue / $target $unit',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  key: const Key('counter-habit-decrement'),
                  tooltip: '减少 $step $unit',
                  onPressed: onChanged == null ? null : () => _change(-step),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  key: const Key('counter-habit-increment'),
                  onPressed: onChanged == null ? null : () => _change(step),
                  icon: const Icon(Icons.add),
                  label: Text('+$step$unit'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '本周',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                for (var day = 0; day < completedDays.length; day++)
                  Tooltip(
                    message: '周${day + 1}',
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completedDays[day]
                            ? _habitColor(habit.colorHex)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _change(int delta) {
    final next = math.max(0, currentValue + delta);
    onChanged?.call(next);
    if (target > 0 && currentValue < target && next >= target) {
      SoundManager.instance.playPop();
    }
  }
}

IconData _habitIcon(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('water') || normalized.contains('drink')) {
    return Icons.water_drop_outlined;
  }
  if (normalized.contains('run') || normalized.contains('walk')) {
    return Icons.directions_run;
  }
  if (normalized.contains('read')) {
    return Icons.menu_book_outlined;
  }
  return Icons.check_circle_outline;
}

Color _habitColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null) {
    return const Color(0xFF52C41A);
  }
  return Color(0xFF000000 | value);
}
