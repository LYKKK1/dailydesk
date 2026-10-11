import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/dashboard/builtin/definition_support.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

class HabitsQuickWidgetDefinition
    extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'habits_quick';

  @override
  String get name => '习惯快栏';

  @override
  IconData get icon => Icons.task_alt;

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
    final repository = DashboardServicesScope.maybeOf(context)?.habitRepository;
    if (repository == null) {
      return const DashboardUnavailable(message: '连接习惯数据后显示打卡栏');
    }
    return StreamBuilder<List<Habit>>(
      stream: repository.watchHabits(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final habits =
            snapshot.data!.take(ctx.config['limit'] as int? ?? 6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardPanelTitle(title: '习惯快栏 · ${habits.length}'),
            const SizedBox(height: 6),
            if (habits.isEmpty)
              const Expanded(child: DashboardUnavailable(message: '还没有习惯'))
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: habits.length,
                  itemBuilder: (context, index) => _HabitToggle(
                    repository: repository,
                    habit: habits[index],
                  ),
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

class _HabitToggle extends StatefulWidget {
  const _HabitToggle({required this.repository, required this.habit});

  final HabitRepository repository;
  final Habit habit;

  @override
  State<_HabitToggle> createState() => _HabitToggleState();
}

class _HabitToggleState extends State<_HabitToggle> {
  bool _checked = false;
  bool _busy = false;

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dates = await widget.repository.recordDates(widget.habit.id);
    if (mounted) setState(() => _checked = dates.contains(_today));
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.toggleCheckIn(widget.habit.id, _today);
      if (mounted) setState(() => _checked = !_checked);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(widget.habit.name, maxLines: 1),
      trailing: IconButton(
        onPressed: _busy ? null : _toggle,
        tooltip: _checked ? '取消打卡' : '完成打卡',
        icon: Icon(
          _checked ? Icons.check_circle : Icons.circle_outlined,
          color: _checked ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }
}
