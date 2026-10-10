import 'package:flutter/material.dart';

const kDesktopBreakpoint = 900.0;

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.desktopBody,
    required this.mobileBody,
    this.title,
  });

  final Widget desktopBody;
  final Widget mobileBody;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > kDesktopBreakpoint;
    if (isDesktop) {
      return Scaffold(
        appBar: title == null ? null : AppBar(title: Text(title!)),
        body: Row(
          children: [
            const SizedBox(
              width: 220,
              child: Drawer(child: _NavigationDrawerList()),
            ),
            Expanded(child: desktopBody),
          ],
        ),
      );
    }

    return Scaffold(
      body: mobileBody,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: '今日聚焦',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: '日历',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2),
            label: '便签',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department),
            label: '习惯',
          ),
        ],
      ),
    );
  }
}

class _NavigationDrawerList extends StatelessWidget {
  const _NavigationDrawerList();

  @override
  Widget build(BuildContext context) => ListView();
}
