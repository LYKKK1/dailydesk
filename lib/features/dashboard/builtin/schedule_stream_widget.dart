import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleStreamWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'schedule_stream';

  @override
  String get name => '时间块流';

  @override
  IconData get icon => Icons.view_timeline_outlined;

  @override
  ({int w, int h}) get defaultSize => (w: 6, h: 5);

  @override
  Map<String, dynamic> defaultConfig() => {'limit': 8};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) =>
      dashboardConfig(defaultConfig(), raw);

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) {
    final repository =
        DashboardServicesScope.maybeOf(context)?.scheduleRepository;
    if (repository == null) {
      return const DashboardUnavailable(message: '连接日程数据后显示时间块');
    }
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return StreamBuilder<List<Schedule>>(
      stream: repository.watchSchedulesInRange(start, end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final schedules = snapshot.data!
            .take(ctx.config['limit'] as int? ?? 8)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardPanelTitle(title: '今日时间块 · ${schedules.length}'),
            const SizedBox(height: 8),
            if (schedules.isEmpty)
              const Expanded(child: DashboardUnavailable(message: '今天还没有排期'))
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    final begin =
                        DateTime.fromMillisecondsSinceEpoch(schedule.startTime);
                    final finish =
                        DateTime.fromMillisecondsSinceEpoch(schedule.endTime);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            DateFormat('HH:mm').format(begin),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _parseColor(schedule.colorHex),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${DateFormat('HH:mm').format(begin)} - '
                                  '${DateFormat('HH:mm').format(finish)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget renderSettings(
    BuildContext context,
    WidgetSettingsContext<Map<String, dynamic>> ctx,
  ) =>
      DashboardLimitSettings(settingsContext: ctx);

  Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null
        ? const Color(0xFF4A90E2)
        : Color(0xFF000000 | parsed);
  }
}
