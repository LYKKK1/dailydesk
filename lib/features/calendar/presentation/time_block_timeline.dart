import 'dart:math' as math;

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/theme/app_colors.dart';
import 'package:dailydesk/features/calendar/data/schedule_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => throw UnimplementedError(
    'scheduleRepositoryProvider must be overridden by the app composition root',
  ),
);

class TimeBlockTimeline extends StatefulWidget {
  const TimeBlockTimeline({
    super.key,
    required this.repository,
    required this.todos,
    required this.day,
    this.initialScrollTime,
    this.workStart = const TimeOfDay(hour: 8, minute: 30),
    this.workEnd = const TimeOfDay(hour: 20, minute: 30),
  });

  final ScheduleRepository repository;
  final List<Todo> todos;
  final DateTime day;
  final TimeOfDay? initialScrollTime;
  final TimeOfDay workStart;
  final TimeOfDay workEnd;

  @override
  State<TimeBlockTimeline> createState() => _TimeBlockTimelineState();
}

class _TimeBlockTimelineState extends State<TimeBlockTimeline> {
  static const _slotHeight = 48.0;

  late final ScrollController _scrollController;

  DateTime get _dayStart =>
      DateTime(widget.day.year, widget.day.month, widget.day.day);

  int get _startMinutes => _minutes(widget.workStart);

  int get _endMinutes => _minutes(widget.workEnd);

  int get _slotCount => math.max(0, (_endMinutes - _startMinutes) ~/ 30);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final requested = widget.initialScrollTime;
      if (requested == null) {
        return;
      }
      final slot = (_minutes(requested) - _startMinutes) ~/ 30;
      final offset = (slot * _slotHeight - 80).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayEnd = _dayStart.add(const Duration(days: 1));

    return StreamBuilder<List<Schedule>>(
      stream: widget.repository.watchSchedulesInRange(_dayStart, dayEnd),
      builder: (context, snapshot) {
        final schedules = snapshot.data ?? const <Schedule>[];
        return LayoutBuilder(
          builder: (context, constraints) {
            final drawerWidth = math.min(
              224.0,
              math.max(168.0, constraints.maxWidth * 0.29),
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TimelineCanvas(
                    day: _dayStart,
                    schedules: schedules,
                    slotCount: _slotCount,
                    startMinutes: _startMinutes,
                    slotHeight: _slotHeight,
                    scrollController: _scrollController,
                    onSchedule: _schedule,
                  ),
                ),
                if (widget.todos.isNotEmpty) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: drawerWidth,
                    child: _TodoDrawer(todos: widget.todos),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _schedule(Todo todo, int slotMinutes) {
    final start = _dayStart.add(Duration(minutes: slotMinutes));
    return widget.repository.scheduleTodo(
      todoId: todo.id,
      title: todo.title,
      start: start,
      end: start.add(const Duration(hours: 1)),
      colorHex: _hex(AppColors.priorityColor(todo.priority)),
    );
  }

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static String _hex(Color color) {
    final rgb = (color.r * 255).round() << 16 |
        (color.g * 255).round() << 8 |
        (color.b * 255).round();
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _TimelineCanvas extends StatelessWidget {
  const _TimelineCanvas({
    required this.day,
    required this.schedules,
    required this.slotCount,
    required this.startMinutes,
    required this.slotHeight,
    required this.scrollController,
    required this.onSchedule,
  });

  final DateTime day;
  final List<Schedule> schedules;
  final int slotCount;
  final int startMinutes;
  final double slotHeight;
  final ScrollController scrollController;
  final Future<void> Function(Todo todo, int slotMinutes) onSchedule;

  @override
  Widget build(BuildContext context) {
    final totalHeight = slotCount * slotHeight;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      controller: scrollController,
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < slotCount; index++)
              Positioned(
                top: index * slotHeight,
                left: 0,
                right: 0,
                height: slotHeight,
                child: _TimeSlot(
                  key: Key(
                    'time-slot-${_ymd(day)}-${_hm(startMinutes + index * 30)}',
                  ),
                  label: _hm(startMinutes + index * 30),
                  minutes: startMinutes + index * 30,
                  borderColor: colorScheme.outlineVariant,
                  onAccept: onSchedule,
                ),
              ),
            for (final schedule in schedules)
              Positioned(
                top: _top(schedule),
                left: 64,
                right: 8,
                height: _height(schedule),
                child: IgnorePointer(
                  child: _ScheduleBlock(schedule: schedule),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _top(Schedule schedule) {
    final start = DateTime.fromMillisecondsSinceEpoch(schedule.startTime);
    final minutes = start.difference(day).inMinutes;
    return math.max(0, (minutes - startMinutes) / 30 * slotHeight);
  }

  double _height(Schedule schedule) {
    final minutes = Duration(
      milliseconds: schedule.endTime - schedule.startTime,
    ).inMinutes;
    return math.max(24, minutes / 30 * slotHeight - 2);
  }
}

class _TimeSlot extends StatelessWidget {
  const _TimeSlot({
    super.key,
    required this.label,
    required this.minutes,
    required this.borderColor,
    required this.onAccept,
  });

  final String label;
  final int minutes;
  final Color borderColor;
  final Future<void> Function(Todo todo, int slotMinutes) onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Todo>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data, minutes),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primaryContainer.withAlpha(90)
                : Colors.transparent,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: active
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  const _ScheduleBlock({required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(schedule.colorHex);
    final start = DateTime.fromMillisecondsSinceEpoch(schedule.startTime);
    final end = DateTime.fromMillisecondsSinceEpoch(schedule.endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            schedule.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '${_hm(start.hour * 60 + start.minute)}'
            ' - ${_hm(end.hour * 60 + end.minute)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _TodoDrawer extends StatelessWidget {
  const _TodoDrawer({required this.todos});

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            '待办抽屉',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            itemCount: todos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final todo = todos[index];
              final card = _TodoDrawerCard(todo: todo);
              return Draggable<Todo>(
                data: todo,
                feedback: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: card,
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.35, child: card),
                child: card,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TodoDrawerCard extends StatelessWidget {
  const _TodoDrawerCard({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(todo.priority);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _hm(int minutes) {
  final hour = (minutes ~/ 60) % 24;
  final minute = minutes % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

Color _parseHex(String value) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return const Color(0xFF4A90E2);
  }
  return Color(0xFF000000 | (parsed & 0x00FFFFFF));
}
