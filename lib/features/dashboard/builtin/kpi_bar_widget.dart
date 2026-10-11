import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

class KpiBarWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'kpi_bar';

  @override
  String get name => '生产力指标';

  @override
  IconData get icon => Icons.speed_outlined;

  @override
  ({int w, int h}) get defaultSize => (w: 8, h: 3);

  @override
  Map<String, dynamic> defaultConfig() => {};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) =>
      dashboardConfig(defaultConfig(), raw);

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) {
    final services = DashboardServicesScope.maybeOf(context);
    if (services == null) {
      return const DashboardUnavailable(message: '连接数据后显示核心指标');
    }
    return FutureBuilder<_KpiSnapshot>(
      future: _load(services),
      builder: (context, snapshot) {
        final value = snapshot.data;
        return Row(
          children: [
            _Kpi(
              label: '待办',
              value: value == null ? '--' : '${value.pendingTodos}',
              icon: Icons.checklist_rtl,
            ),
            _Kpi(
              label: '专注分钟',
              value: value == null ? '--' : '${value.focusMinutes}',
              icon: Icons.timer_outlined,
            ),
            _Kpi(
              label: '完成率',
              value: value == null
                  ? '--'
                  : '${(value.completionRate * 100).round()}%',
              icon: Icons.trending_up,
            ),
          ],
        );
      },
    );
  }

  Future<_KpiSnapshot> _load(DashboardServices services) async {
    final todos = await services.todoRepository?.watchTodos().first ?? const [];
    final focus = await services.pomodoroRepository?.todayFocusMinutes() ?? 0;
    final completed = todos
        .where((todo) => todo.status == 'completed' || todo.status == 'done')
        .length;
    return _KpiSnapshot(
      pendingTodos: todos.where((todo) => todo.status == 'pending').length,
      focusMinutes: focus,
      completionRate: todos.isEmpty ? 0 : completed / todos.length,
    );
  }

  @override
  Widget renderSettings(
    BuildContext context,
    WidgetSettingsContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();
}

class _KpiSnapshot {
  const _KpiSnapshot({
    required this.pendingTodos,
    required this.focusMinutes,
    required this.completionRate,
  });

  final int pendingTodos;
  final int focusMinutes;
  final double completionRate;
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
