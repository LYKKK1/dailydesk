import 'package:flutter/material.dart';

const kDesktopBreakpoint = 900.0;

class AppDestination {
  const AppDestination({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const kDefaultDestinations = <AppDestination>[
  AppDestination(
    key: 'dashboard',
    label: '今日聚焦',
    icon: Icons.dashboard_outlined,
  ),
  AppDestination(
    key: 'todos',
    label: '待办',
    icon: Icons.checklist,
  ),
  AppDestination(
    key: 'calendar',
    label: '日历',
    icon: Icons.calendar_month,
  ),
  AppDestination(
    key: 'memos',
    label: '便签',
    icon: Icons.sticky_note_2,
  ),
  AppDestination(
    key: 'habits',
    label: '习惯',
    icon: Icons.local_fire_department,
  ),
  AppDestination(
    key: 'pomodoro',
    label: '番茄专注',
    icon: Icons.timer_outlined,
  ),
  AppDestination(
    key: 'review',
    label: '每日复盘',
    icon: Icons.rate_review_outlined,
  ),
  AppDestination(
    key: 'copilot',
    label: 'AI 智囊',
    icon: Icons.smart_toy_outlined,
  ),
  AppDestination(
    key: 'sync',
    label: '局域网同步',
    icon: Icons.sync_alt_rounded,
  ),
];

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.desktopBody,
    required this.mobileBody,
    this.title,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.destinations = kDefaultDestinations,
  });

  final Widget desktopBody;
  final Widget mobileBody;
  final String? title;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<AppDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > kDesktopBreakpoint;
    if (isDesktop) {
      return Scaffold(
        appBar: title == null ? null : AppBar(title: Text(title!)),
        body: Row(
          children: [
            SizedBox(
              width: 220,
              child: Drawer(
                child: _NavigationDrawerList(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                ),
              ),
            ),
            Expanded(child: desktopBody),
          ],
        ),
      );
    }

    final mobileDestinations = destinations.take(5).toList(growable: false);
    final mobileIndex = selectedIndex.clamp(0, mobileDestinations.length - 1);
    return Scaffold(
      body: mobileBody,
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final item in mobileDestinations)
            NavigationDestination(
              icon: Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _NavigationDrawerList extends StatelessWidget {
  const _NavigationDrawerList({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      itemCount: destinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = destinations[index];
        final selected = index == selectedIndex;
        return ListTile(
          key: Key('nav-${item.key}'),
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          selected: selected,
          selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.65),
          leading: Icon(item.icon, size: 20),
          title: Text(item.label),
          onTap: () => onDestinationSelected?.call(index),
        );
      },
    );
  }
}
