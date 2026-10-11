import 'package:flutter/material.dart';

/// Builds a 52-week matrix. Each outer list is a week and each inner list
/// contains Monday through Sunday, with the oldest week first.
List<List<int>> heatmapMatrix(
  List<String> dates, {
  DateTime? today,
}) {
  final completedDates = dates.toSet();
  final anchor = today ?? DateTime.now();
  final todayDate = DateTime(anchor.year, anchor.month, anchor.day);
  final thisMonday = todayDate.subtract(
    Duration(days: todayDate.weekday - DateTime.monday),
  );
  final firstMonday = thisMonday.subtract(const Duration(days: 7 * 51));

  return List<List<int>>.generate(52, (week) {
    return List<int>.generate(7, (day) {
      final date = firstMonday.add(Duration(days: week * 7 + day));
      if (date.isAfter(todayDate)) {
        return 0;
      }
      return completedDates.contains(_ymd(date)) ? 1 : 0;
    });
  });
}

class HabitHeatmap extends StatelessWidget {
  const HabitHeatmap({
    super.key,
    required this.dates,
    this.intensityByDate = const {},
    this.today,
    this.cellSize = 10,
  });

  final List<String> dates;
  final Map<String, double> intensityByDate;
  final DateTime? today;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final matrix = heatmapMatrix(dates, today: today);
    final dateMatrix = _dateMatrix(today ?? DateTime.now());
    final gap = cellSize * 0.3;
    const weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return Semantics(
      label: '最近 52 周习惯热力图',
      child: SingleChildScrollView(
        key: const Key('habit-heatmap'),
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                for (var day = 0; day < 7; day++)
                  SizedBox(
                    width: 18,
                    height: cellSize + gap,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        day.isEven ? weekdayLabels[day] : '',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            for (var week = 0; week < matrix.length; week++)
              Padding(
                padding: EdgeInsets.only(right: gap),
                child: Column(
                  children: [
                    for (var day = 0; day < 7; day++)
                      Tooltip(
                        message: _tooltip(
                          dateMatrix[week][day],
                          intensityByDate[_ymd(dateMatrix[week][day])],
                        ),
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          margin: EdgeInsets.only(bottom: gap),
                          decoration: BoxDecoration(
                            color: habitHeatmapColor(
                              matrix[week][day] == 0
                                  ? 0
                                  : intensityByDate[
                                          _ymd(dateMatrix[week][day])] ??
                                      1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _tooltip(DateTime date, double? intensity) {
    final percent = ((intensity ?? 0) * 100).round();
    return '${date.month}/${date.day} · $percent%';
  }
}

Color habitHeatmapColor(double intensity) {
  if (intensity <= 0) {
    return const Color(0xFFEBEDF0);
  }
  final alpha = switch (intensity) {
    < 0.25 => 0.25,
    < 0.5 => 0.5,
    < 0.75 => 0.75,
    _ => 1.0,
  };
  return const Color(0xFF52C41A).withAlpha((alpha * 255).round());
}

List<List<DateTime>> _dateMatrix(DateTime today) {
  final todayDate = DateTime(today.year, today.month, today.day);
  final thisMonday = todayDate.subtract(
    Duration(days: todayDate.weekday - DateTime.monday),
  );
  final firstMonday = thisMonday.subtract(const Duration(days: 7 * 51));
  return List<List<DateTime>>.generate(52, (week) {
    return List<DateTime>.generate(
      7,
      (day) => firstMonday.add(Duration(days: week * 7 + day)),
    );
  });
}

String _ymd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
