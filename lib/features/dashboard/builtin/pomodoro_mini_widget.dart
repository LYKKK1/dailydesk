import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

class PomodoroMiniWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'pomodoro_mini';

  @override
  String get name => '沉浸番茄钟';

  @override
  IconData get icon => Icons.timer_outlined;

  @override
  ({int w, int h}) get defaultSize => (w: 4, h: 4);

  @override
  Map<String, dynamic> defaultConfig() => {'plannedMinutes': 25};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) =>
      dashboardConfig(defaultConfig(), raw);

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) {
    final repository =
        DashboardServicesScope.maybeOf(context)?.pomodoroRepository;
    if (repository == null) {
      return const DashboardUnavailable(
        icon: Icons.timer_off_outlined,
        message: '连接番茄钟数据后显示专注状态',
      );
    }
    return StreamBuilder(
      stream: repository.watchActiveSession(),
      builder: (context, snapshot) {
        final session = snapshot.data;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              session == null ? '准备专注' : '专注进行中',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: session == null ? 0 : null,
                    strokeWidth: 7,
                  ),
                  Center(
                    child: Text(
                      '${session?.durationMinutes ?? ctx.config['plannedMinutes']}'
                      '\n分钟',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: repository.todayFocusMinutes(),
              builder: (context, value) => Text(
                '今日累计 ${value.data ?? 0} 分钟',
                style: Theme.of(context).textTheme.bodySmall,
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
      const SizedBox.shrink();
}
