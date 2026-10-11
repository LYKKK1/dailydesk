import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

class MemosSnapshotWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'memos_snapshot';

  @override
  String get name => '灵感碎片';

  @override
  IconData get icon => Icons.sticky_note_2_outlined;

  @override
  ({int w, int h}) get defaultSize => (w: 4, h: 4);

  @override
  Map<String, dynamic> defaultConfig() => {'limit': 6};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) =>
      dashboardConfig(defaultConfig(), raw);

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) {
    final repository = DashboardServicesScope.maybeOf(context)?.memoRepository;
    if (repository == null) {
      return const DashboardUnavailable(message: '连接便签数据后显示灵感快照');
    }
    return StreamBuilder<List<Memo>>(
      stream: repository.watchMemos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final memos =
            snapshot.data!.take(ctx.config['limit'] as int? ?? 6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardPanelTitle(title: '灵感碎片 · ${memos.length}'),
            const SizedBox(height: 6),
            if (memos.isEmpty)
              const Expanded(child: DashboardUnavailable(message: '还没有便签'))
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: memos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final memo = memos[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (memo.isPinned) ...[
                            const Icon(Icons.push_pin, size: 14),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              memo.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
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
