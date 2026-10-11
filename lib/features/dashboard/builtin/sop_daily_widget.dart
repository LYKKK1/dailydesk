import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/features/sop/presentation/sop_card.dart';
import 'package:dailydesk/features/sop/services/sop_engine.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

class SopDailyWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'sop_daily';

  @override
  String get name => '每日 SOP';

  @override
  IconData get icon => Icons.rule_folder_outlined;

  @override
  ({int w, int h}) get defaultSize => (w: 6, h: 8);

  @override
  Map<String, dynamic> defaultConfig() => {'slots': const []};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) =>
      dashboardConfig(defaultConfig(), raw);

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) {
    final slots = _slotsFromConfig(ctx.config);
    final pomodoro =
        DashboardServicesScope.maybeOf(context)?.pomodoroRepository;
    return SopCard(
      initialSlots: slots,
      onChanged: (next) => ctx.saveConfig({
        'slots': next.map((slot) => slot.toJson()).toList(),
      }),
      onFocus: pomodoro == null
          ? null
          : (_) async {
              await pomodoro.startSession(mode: 'sop', plannedMinutes: 25);
              await pomodoro.reconcileActiveSession();
            },
    );
  }

  List<SopSlot> _slotsFromConfig(Map<String, dynamic> config) {
    final raw = config['slots'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) => SopSlot.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  @override
  Widget renderSettings(
    BuildContext context,
    WidgetSettingsContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();
}
