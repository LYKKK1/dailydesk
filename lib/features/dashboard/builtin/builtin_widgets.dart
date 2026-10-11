import 'package:dailydesk/features/dashboard/builtin/habits_quick_widget.dart';
import 'package:dailydesk/features/dashboard/builtin/kpi_bar_widget.dart';
import 'package:dailydesk/features/dashboard/builtin/matrix_widget.dart';
import 'package:dailydesk/features/dashboard/builtin/memos_snapshot_widget.dart';
import 'package:dailydesk/features/dashboard/builtin/pomodoro_mini_widget.dart';
import 'package:dailydesk/features/dashboard/builtin/schedule_stream_widget.dart';
import 'package:dailydesk/features/dashboard/builtin/sop_daily_widget.dart';
import 'package:dailydesk/features/dashboard/builtin/today_focus_widget.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';

final List<DailyWidgetDefinition<dynamic>> builtInDashboardDefinitions = [
  MatrixWidgetDefinition(),
  TodayFocusWidgetDefinition(),
  PomodoroMiniWidgetDefinition(),
  HabitsQuickWidgetDefinition(),
  MemosSnapshotWidgetDefinition(),
  ScheduleStreamWidgetDefinition(),
  KpiBarWidgetDefinition(),
  SopDailyWidgetDefinition(),
];

void registerBuiltInDashboardWidgets(WidgetRegistry registry) {
  for (final definition in builtInDashboardDefinitions) {
    if (registry.definitionOf(definition.kind) == null) {
      registry.register(definition, builtin: true);
    }
  }
}
