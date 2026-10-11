import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/theme/app_colors.dart';
import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

class MatrixWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'matrix';

  @override
  String get name => '四象限看板';

  @override
  IconData get icon => Icons.grid_view_rounded;

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
    final repository = DashboardServicesScope.maybeOf(context)?.todoRepository;
    if (repository == null) {
      return const DashboardUnavailable(message: '连接待办数据后显示四象限');
    }
    return StreamBuilder<List<Todo>>(
      stream: repository.watchTodos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final todos = snapshot.data!;
        final limit = ctx.config['limit'] as int? ?? 8;
        const labels = ['立即做', '计划做', '委托', '稍后做'];
        return GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.45,
          children: [
            for (var priority = 0; priority < labels.length; priority++)
              _Quadrant(
                label: labels[priority],
                color: AppColors.priorityColor(priority),
                todos: todos
                    .where((todo) => todo.priority == priority)
                    .take(limit)
                    .toList(),
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

class _Quadrant extends StatelessWidget {
  const _Quadrant({
    required this.label,
    required this.color,
    required this.todos,
  });

  final String label;
  final Color color;
  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '$label · ${todos.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: todos.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '暂无任务',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: todos.length,
                      itemBuilder: (context, index) => Text(
                        '• ${todos[index].title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
