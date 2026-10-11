import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

const builtInDashboardKinds = <String>[
  'matrix',
  'today_focus',
  'pomodoro_mini',
  'habits_quick',
  'memos_snapshot',
  'schedule_stream',
  'kpi_bar',
  'sop_daily',
];

class WidgetCatalogDrawer extends StatelessWidget {
  const WidgetCatalogDrawer({
    super.key,
    required this.controller,
    this.closeOnAdd = false,
  });

  final DashboardController controller;
  final bool closeOnAdd;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final definitions = builtInDashboardKinds
                .map(controller.registry.definitionOf)
                .whereType<DailyWidgetDefinition<dynamic>>()
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        '＋ 添加模块',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      for (final definition in definitions)
                        ListTile(
                          key: Key('catalog-add-${definition.kind}'),
                          leading: Icon(definition.icon),
                          title: Text(definition.name),
                          subtitle: Text(
                            '${definition.defaultSize.w} × ${definition.defaultSize.h}',
                          ),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            controller.add(definition.kind);
                            if (closeOnAdd) Navigator.maybePop(context);
                          },
                        ),
                      if (controller.ordered.isNotEmpty) ...[
                        const Divider(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '当前页面',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        for (final instance in controller.ordered)
                          ListTile(
                            dense: true,
                            title: Text(
                              controller.registry
                                      .definitionOf(instance.kind)
                                      ?.name ??
                                  instance.kind,
                            ),
                            subtitle: Text('${instance.w} × ${instance.h}'),
                            trailing: IconButton(
                              key: Key('catalog-remove-${instance.id}'),
                              tooltip: '移除',
                              onPressed: () => controller.remove(instance.id),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
