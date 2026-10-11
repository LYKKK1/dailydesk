import 'package:dailydesk/core/utils/sanitize.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

Map<String, dynamic> dashboardConfig(
  Map<String, dynamic> defaults,
  Map<String, dynamic> raw,
) =>
    normalizeWith(defaults, raw);

class DashboardUnavailable extends StatelessWidget {
  const DashboardUnavailable({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class DashboardPanelTitle extends StatelessWidget {
  const DashboardPanelTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DashboardLimitSettings extends StatelessWidget {
  const DashboardLimitSettings({
    super.key,
    required this.settingsContext,
    this.label = '显示数量',
    this.min = 1,
    this.max = 20,
  });

  final WidgetSettingsContext<Map<String, dynamic>> settingsContext;
  final String label;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final current = settingsContext.draft['limit'] as int? ?? min;
    var value = current.clamp(min, max);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            onChanged: (next) {
              value = next.round();
              settingsContext.draft['limit'] = value;
            },
            onChangeEnd: (_) => settingsContext.save(),
          ),
        ],
      ),
    );
  }
}
