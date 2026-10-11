import 'package:dailydesk/features/dashboard/builtin/builtin_widgets.dart';
import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/features/dashboard/presentation/dashboard_grid.dart';
import 'package:dailydesk/features/dashboard/presentation/widgets/widget_catalog_drawer.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.controller,
    this.services = const DashboardServices(),
    this.initialEditMode = false,
  });

  final DashboardController controller;
  final DashboardServices services;
  final bool initialEditMode;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool _editMode;

  @override
  void initState() {
    super.initState();
    _editMode = widget.initialEditMode;
    registerBuiltInDashboardWidgets(widget.controller.registry);
  }

  @override
  void didUpdateWidget(covariant DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      registerBuiltInDashboardWidgets(widget.controller.registry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return DashboardServicesScope(
      services: widget.services,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Scaffold(
            key: _scaffoldKey,
            endDrawer: WidgetCatalogDrawer(controller: controller),
            body: SafeArea(
              child: Column(
                children: [
                  _DashboardToolbar(
                    controller: controller,
                    editMode: _editMode,
                    onToggleEdit: () => setState(() => _editMode = !_editMode),
                    onAdd: () => _scaffoldKey.currentState?.openEndDrawer(),
                    onSettings: _openGridSettings,
                    onAddPage: _addPage,
                    onPageMenu: _showPageMenu,
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildGrid(context, controller)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BuildContext context, DashboardController controller) {
    final widgets = controller.ordered;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final content = widgets.isEmpty
            ? const _EmptyDashboard()
            : DashboardGrid(
                widgets: widgets,
                controller: controller,
                editMode: _editMode,
                compact: compact,
              );

        final maxWidth = controller.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth == 0 ? double.infinity : maxWidth.toDouble(),
            ),
            child: content,
          ),
        );
      },
    );
  }

  Future<void> _addPage() async {
    final name = await _promptText(
      title: '新建工作台',
      hint: '例如：周末',
    );
    if (name == null || name.trim().isEmpty) return;
    widget.controller.addPage(name);
  }

  Future<void> _showPageMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('重命名当前工作台'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除当前工作台'),
              enabled: widget.controller.pages.length > 1,
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final active = widget.controller.activePage;
    if (action == 'rename') {
      final name = await _promptText(
        title: '重命名工作台',
        initialValue: active.name,
      );
      if (name != null) widget.controller.renamePage(active.id, name);
    } else if (action == 'delete') {
      widget.controller.removePage(active.id);
    }
  }

  Future<String?> _promptText({
    required String title,
    String hint = '',
    String initialValue = '',
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _openGridSettings() {
    final controller = widget.controller;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('网格设置', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _GridSlider(
                  label: '行高 ${controller.rowHeight}px',
                  value: controller.rowHeight.toDouble(),
                  min: 24,
                  max: 96,
                  divisions: 36,
                  onChanged: (value) {
                    controller.setRowHeight(value.round());
                    setSheetState(() {});
                  },
                ),
                _GridSlider(
                  label: '间距 ${controller.spacing}px',
                  value: controller.spacing.toDouble(),
                  min: 4,
                  max: 40,
                  divisions: 36,
                  onChanged: (value) {
                    controller.setSpacing(value.round());
                    setSheetState(() {});
                  },
                ),
                _GridSlider(
                  label: controller.maxWidth == 0
                      ? '最大宽度 不限'
                      : '最大宽度 ${controller.maxWidth}px',
                  value: controller.maxWidth.toDouble(),
                  min: 0,
                  max: 4000,
                  divisions: 40,
                  onChanged: (value) {
                    controller.setMaxWidth(value.round());
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardToolbar extends StatelessWidget {
  const _DashboardToolbar({
    required this.controller,
    required this.editMode,
    required this.onToggleEdit,
    required this.onAdd,
    required this.onSettings,
    required this.onAddPage,
    required this.onPageMenu,
  });

  final DashboardController controller;
  final bool editMode;
  final VoidCallback onToggleEdit;
  final VoidCallback onAdd;
  final VoidCallback onSettings;
  final VoidCallback onAddPage;
  final VoidCallback onPageMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final page in controller.pages)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(page.name),
                        selected: page.id == controller.activePageId,
                        onSelected: (_) => controller.selectPage(page.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            key: const Key('dashboard-add-page'),
            tooltip: '新建工作台',
            onPressed: onAddPage,
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            key: const Key('dashboard-page-menu'),
            tooltip: '工作台操作',
            onPressed: onPageMenu,
            icon: const Icon(Icons.more_horiz),
          ),
          IconButton(
            key: const Key('dashboard-grid-settings'),
            tooltip: '网格设置',
            onPressed: onSettings,
            icon: const Icon(Icons.tune),
          ),
          FilledButton.tonalIcon(
            key: const Key('dashboard-edit-toggle'),
            onPressed: onToggleEdit,
            icon: Icon(editMode ? Icons.done : Icons.edit_outlined),
            label: Text(editMode ? '完成' : '编辑布局'),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            key: const Key('dashboard-add-module'),
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('添加模块'),
          ),
        ],
      ),
    );
  }
}

class _GridSlider extends StatelessWidget {
  const _GridSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 44),
          SizedBox(height: 10),
          Text('当前工作台还没有模块'),
          SizedBox(height: 4),
          Text('从右上角添加模块开始拼装'),
        ],
      ),
    );
  }
}
