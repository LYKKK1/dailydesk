import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/holidays.dart';
import 'package:dailydesk/features/calendar/data/schedule_repository.dart';
import 'package:dailydesk/features/calendar/presentation/time_block_timeline.dart';
import 'package:flutter/material.dart';

export 'time_block_timeline.dart';

enum CalendarMode { day, week, month }

class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
    this.repository,
    this.todos = const [],
    this.initialDate,
  });

  final ScheduleRepository? repository;
  final List<Todo> todos;
  final DateTime? initialDate;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarMode _mode = CalendarMode.day;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CalendarHeader(
          selectedDate: _selectedDate,
          onPrevious: () => _moveSelection(-1),
          onNext: () => _moveSelection(1),
          onToday: () {
            final today = DateTime.now();
            setState(() {
              _selectedDate = DateTime(today.year, today.month, today.day);
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<CalendarMode>(
            segments: const [
              ButtonSegment(value: CalendarMode.day, label: Text('日')),
              ButtonSegment(value: CalendarMode.week, label: Text('周')),
              ButtonSegment(value: CalendarMode.month, label: Text('月')),
            ],
            selected: {_mode},
            onSelectionChanged: (value) {
              setState(() => _mode = value.single);
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    final repository = widget.repository;
    return switch (_mode) {
      CalendarMode.day => repository == null
          ? const _RepositoryRequired()
          : TimeBlockTimeline(
              repository: repository,
              todos: widget.todos,
              day: _selectedDate,
            ),
      CalendarMode.week => repository == null
          ? const _RepositoryRequired()
          : _WeekView(
              repository: repository,
              selectedDate: _selectedDate,
            ),
      CalendarMode.month => _MonthView(
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
    };
  }

  void _moveSelection(int direction) {
    setState(() {
      _selectedDate = switch (_mode) {
        CalendarMode.day => _selectedDate.add(Duration(days: direction)),
        CalendarMode.week => _selectedDate.add(Duration(days: direction * 7)),
        CalendarMode.month => DateTime(
            _selectedDate.year,
            _selectedDate.month + direction,
            1,
          ),
      };
    });
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final mark = holidayMark(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: '上一页',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${selectedDate.year} 年 ${selectedDate.month} 月 '
                  '${selectedDate.day} 日',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (mark != null) ...[
                  const SizedBox(width: 8),
                  _HolidayBadge(mark: mark),
                ],
              ],
            ),
          ),
          TextButton(onPressed: onToday, child: const Text('今天')),
          IconButton(
            tooltip: '下一页',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _HolidayBadge extends StatelessWidget {
  const _HolidayBadge({required this.mark});

  final String mark;

  @override
  Widget build(BuildContext context) {
    final resting = mark == '休';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: resting
            ? const Color(0xFFE5484D).withAlpha(30)
            : const Color(0xFF3B82F6).withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mark,
        style: TextStyle(
          color: resting ? const Color(0xFFE5484D) : const Color(0xFF3B82F6),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RepositoryRequired extends StatelessWidget {
  const _RepositoryRequired();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('需要注入日程仓库'));
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.repository,
    required this.selectedDate,
  });

  final ScheduleRepository repository;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(
      Duration(days: selectedDate.weekday - DateTime.monday),
    );
    final end = start.add(const Duration(days: 7));

    return StreamBuilder<List<Schedule>>(
      stream: repository.watchSchedulesInRange(start, end),
      builder: (context, snapshot) {
        final schedules = snapshot.data ?? const <Schedule>[];
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < 7; index++)
                Expanded(
                  child: _WeekColumn(
                    date: start.add(Duration(days: index)),
                    schedules: schedules.where((schedule) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        schedule.startTime,
                      );
                      return date.year == start.year &&
                          date.month == start.month &&
                          date.day == start.day + index;
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.date,
    required this.schedules,
  });

  final DateTime date;
  final List<Schedule> schedules;

  @override
  Widget build(BuildContext context) {
    final mark = holidayMark(date);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text('周${_weekdayName(date.weekday)}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}'),
              if (mark != null) ...[
                const SizedBox(width: 3),
                Text(
                  mark,
                  style: TextStyle(
                    fontSize: 11,
                    color: mark == '休'
                        ? const Color(0xFFE5484D)
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final schedule in schedules)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _parseHex(
                        schedule.colorHex,
                      ).withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      schedule.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(selectedDate.year, selectedDate.month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    const dayNames = ['一', '二', '三', '四', '五', '六', '日'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              for (final day in dayNames)
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.05,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                final date = start.add(Duration(days: index));
                return _MonthCell(
                  date: date,
                  inCurrentMonth: date.month == selectedDate.month,
                  selected: _sameDay(date, selectedDate),
                  onTap: () => onSelected(date),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.date,
    required this.inCurrentMonth,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool inCurrentMonth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mark = holidayMark(date);
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      key: Key('calendar-day-${_ymd(date)}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : inCurrentMonth
                  ? Colors.transparent
                  : colorScheme.surfaceContainerHighest.withAlpha(90),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: inCurrentMonth
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (mark != null) _HolidayBadge(mark: mark),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _weekdayName(int weekday) =>
    const ['一', '二', '三', '四', '五', '六', '日'][weekday - 1];

String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Color _parseHex(String value) {
  final parsed = int.tryParse(value.replaceFirst('#', ''), radix: 16);
  if (parsed == null) {
    return const Color(0xFF4A90E2);
  }
  return Color(0xFF000000 | (parsed & 0x00FFFFFF));
}
