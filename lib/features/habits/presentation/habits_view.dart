import 'dart:async';
import 'dart:math' as math;

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';
import 'package:dailydesk/features/habits/presentation/widgets/counter_habit_row.dart';
import 'package:dailydesk/features/habits/presentation/widgets/habit_heatmap.dart';
import 'package:flutter/material.dart';

enum _HeatmapRange {
  week('周'),
  month('月'),
  year('年');

  const _HeatmapRange(this.label);

  final String label;
}

class HabitsView extends StatefulWidget {
  const HabitsView({
    super.key,
    required this.repository,
  });

  final HabitRepository repository;

  @override
  State<HabitsView> createState() => _HabitsViewState();
}

class _HabitsViewState extends State<HabitsView> {
  StreamSubscription<List<Habit>>? _habitsSubscription;
  List<Habit> _habits = const [];
  Map<String, List<String>> _records = const {};
  Set<String> _busyHabitIds = const {};
  _HeatmapRange _range = _HeatmapRange.year;
  Object? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _habitsSubscription = widget.repository.watchHabits().listen(
      _handleHabits,
      onError: (Object error) {
        if (mounted) {
          setState(() => _error = error);
        }
      },
    );
  }

  @override
  void dispose() {
    unawaited(_habitsSubscription?.cancel());
    super.dispose();
  }

  void _handleHabits(List<Habit> habits) {
    if (!mounted) {
      return;
    }
    setState(() {
      _habits = habits;
      _error = null;
    });
    unawaited(_reloadRecords());
  }

  Future<void> _reloadRecords() async {
    final generation = ++_loadGeneration;
    try {
      final entries = await Future.wait([
        for (final habit in _habits)
          widget.repository
              .recordDates(habit.id)
              .then((dates) => MapEntry(habit.id, dates)),
      ]);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _records = Map.fromEntries(entries);
        _error = null;
      });
    } catch (error) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _toggle(Habit habit) async {
    if (_busyHabitIds.contains(habit.id)) {
      return;
    }
    setState(() => _busyHabitIds = {..._busyHabitIds, habit.id});
    try {
      await widget.repository.toggleCheckIn(habit.id, _ymd(DateTime.now()));
      await _reloadRecords();
    } finally {
      if (mounted) {
        setState(() {
          _busyHabitIds = {..._busyHabitIds}..remove(habit.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _habits.isEmpty) {
      return Center(child: Text('习惯数据加载失败：$_error'));
    }

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
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
                          '习惯追踪',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '让微小行动形成可见的长期轨迹',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SegmentedButton<_HeatmapRange>(
                    segments: [
                      for (final range in _HeatmapRange.values)
                        ButtonSegment(
                          value: range,
                          label: Text(range.label),
                        ),
                    ],
                    selected: {_range},
                    onSelectionChanged: (selection) {
                      setState(() => _range = selection.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildHeatmap(context),
              const SizedBox(height: 20),
              Text(
                '今日习惯',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (_habits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('还没有习惯，先添加一个吧')),
                )
              else
                for (final habit in _habits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _isCounterHabit(habit)
                        ? _buildCounterHabit(habit)
                        : _HabitCard(
                            habit: habit,
                            dates: _records[habit.id] ?? const [],
                            busy: _busyHabitIds.contains(habit.id),
                            onToggle: () => unawaited(_toggle(habit)),
                          ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final activityDates = <String>{
      for (final dates in _records.values) ...dates,
    }.toList();
    final intensity = <String, double>{
      for (final date in activityDates) date: _completionRate(date),
    };

    if (_range == _HeatmapRange.year) {
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
              Text(
                '年度达成率',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 98,
                child: HabitHeatmap(
                  dates: activityDates,
                  intensityByDate: intensity,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dates = _range == _HeatmapRange.week
        ? _datesInWeek(DateTime.now())
        : _datesInMonth(DateTime.now());
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
            Text(
              _range == _HeatmapRange.week ? '本周达成率' : '本月达成率',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final date in dates)
                  Tooltip(
                    message:
                        '${date.month}/${date.day} · ${(_completionRate(_ymd(date)) * 100).round()}%',
                    child: Container(
                      width: _range == _HeatmapRange.week ? 30 : 18,
                      height: _range == _HeatmapRange.week ? 30 : 18,
                      decoration: BoxDecoration(
                        color: habitHeatmapColor(
                          date.isAfter(DateTime.now())
                              ? 0
                              : _completionRate(_ymd(date)),
                        ),
                        borderRadius: BorderRadius.circular(4),
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

  Widget _buildCounterHabit(Habit habit) {
    final config = _counterConfig(habit);
    final today = _ymd(DateTime.now());
    final dates = _records[habit.id] ?? const <String>[];
    final week = _datesInWeek(DateTime.now());
    return CounterHabitRow(
      habit: habit,
      currentValue: dates.contains(today) ? config.step : 0,
      target: config.target,
      step: config.step,
      unit: config.unit,
      weekCompleted: [
        for (final date in week) dates.contains(_ymd(date)),
      ],
      onChanged: (_) => unawaited(_toggle(habit)),
    );
  }

  double _completionRate(String date) {
    if (_habits.isEmpty) {
      return 0;
    }
    final completed = _habits
        .where((habit) => (_records[habit.id] ?? const []).contains(date))
        .length;
    return completed / _habits.length;
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.dates,
    required this.busy,
    required this.onToggle,
  });

  final Habit habit;
  final List<String> dates;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(habit.colorHex);
    final today = _ymd(DateTime.now());
    final checked = dates.contains(today);
    final strength = HabitRepository.strengthScore(dates);
    final streak = HabitRepository.currentStreak(dates);
    final best = _bestStreak(dates);

    return Card(
      key: ValueKey('habit-${habit.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withAlpha(30),
              child: Icon(_habitIcon(habit.iconName), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FrequencyBadge(habit: habit),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        '🔥 连击 $streak 天',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '最佳 $best 天',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: strength,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(999),
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(strength * 100).round()}% 健康度',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Checkbox(
              key: ValueKey('habit-check-${habit.id}'),
              value: checked,
              onChanged: busy ? null : (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyBadge extends StatelessWidget {
  const _FrequencyBadge({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final label = switch (habit.frequencyType) {
      'weekdays' => '工作日',
      'times_per_week' => '${habit.targetDaysPerWeek ?? 3}/7',
      'counter' => '数值',
      _ => '每日',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

bool _isCounterHabit(Habit habit) =>
    habit.frequencyType == 'counter' || habit.iconName.startsWith('counter:');

({int target, int step, String unit}) _counterConfig(Habit habit) {
  final parts = habit.iconName.split(':');
  final target = parts.length > 1 ? int.tryParse(parts[1]) ?? 2000 : 2000;
  final step = parts.length > 2 ? int.tryParse(parts[2]) ?? 250 : 250;
  final unit = parts.length > 3 && parts[3].isNotEmpty ? parts[3] : 'ml';
  return (target: math.max(1, target), step: math.max(1, step), unit: unit);
}

List<DateTime> _datesInWeek(DateTime today) {
  final monday = DateTime(today.year, today.month, today.day)
      .subtract(Duration(days: today.weekday - DateTime.monday));
  return List<DateTime>.generate(
      7, (index) => monday.add(Duration(days: index)));
}

List<DateTime> _datesInMonth(DateTime today) {
  final days = DateTime(today.year, today.month + 1, 0).day;
  return List<DateTime>.generate(
    days,
    (index) => DateTime(today.year, today.month, index + 1),
  );
}

int _bestStreak(List<String> dates) {
  if (dates.isEmpty) {
    return 0;
  }
  final sorted = dates.toSet().map(DateTime.parse).toList()..sort();
  var best = 1;
  var current = 1;
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index].difference(sorted[index - 1]).inDays == 1) {
      current++;
      best = math.max(best, current);
    } else {
      current = 1;
    }
  }
  return best;
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

Color _parseColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null) {
    return const Color(0xFF52C41A);
  }
  return Color(0xFF000000 | value);
}

String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
