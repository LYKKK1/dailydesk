import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

class TodayFocusWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'today_focus';

  @override
  String get name => '今日聚焦';

  @override
  IconData get icon => Icons.center_focus_strong_outlined;

  @override
  ({int w, int h}) get defaultSize => (w: 4, h: 4);

  @override
  Map<String, dynamic> defaultConfig() => {'limit': 5};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) =>
      dashboardConfig(defaultConfig(), raw);

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) {
    final repository = DashboardServicesScope.maybeOf(context)?.todoRepository;
    if (repository == null) {
      return const DashboardUnavailable(message: '连接待办数据后显示今日聚焦');
    }
    return StreamBuilder<List<Todo>>(
      stream: repository.watchTodayTodos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final todos = snapshot.data!.take(ctx.config['limit'] as int? ?? 5);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardPanelTitle(
              title: '今日核心 · ${snapshot.data!.length}',
              trailing: const Icon(Icons.bolt, size: 17),
            ),
            const SizedBox(height: 8),
            if (snapshot.data!.isEmpty)
              const Expanded(child: DashboardUnavailable(message: '今天没有待处理任务'))
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: todos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final todo = todos.elementAt(index);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        todo.isTop
                            ? Icons.push_pin_outlined
                            : Icons.radio_button_unchecked,
                        size: 18,
                      ),
                      title: Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: todo.dueDate == null
                          ? null
                          : Text('${todo.dueDate} ${todo.dueTime ?? ''}'),
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
}
