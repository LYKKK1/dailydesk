import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/dashboard/layout_transfer.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:flutter/material.dart';

const _defaultWidgetSpecs = <_DefaultWidgetSpec>[
  _DefaultWidgetSpec('kpi_bar', 12, 2),
  _DefaultWidgetSpec('sop_daily', 8, 6),
  _DefaultWidgetSpec('today_focus', 4, 6),
  _DefaultWidgetSpec('pomodoro_mini', 4, 4),
  _DefaultWidgetSpec('matrix', 6, 6),
  _DefaultWidgetSpec('memos_snapshot', 6, 4),
  _DefaultWidgetSpec('habits_quick', 4, 4),
  _DefaultWidgetSpec('schedule_stream', 4, 4),
];

LayoutPage createDefaultDashboard({
  WidgetRegistry? registry,
  String name = '默认工作台',
}) {
  return LayoutPage(
    id: newUlid(),
    name: name,
    widgets: [
      for (final spec in _defaultWidgetSpecs)
        _createDefaultWidget(spec, registry),
    ],
  );
}

WidgetInstance _createDefaultWidget(
  _DefaultWidgetSpec spec,
  WidgetRegistry? registry,
) {
  final definition = registry?.definitionOf(spec.kind);
  final size = definition?.defaultSize;
  return WidgetInstance(
    id: newUlid(),
    kind: spec.kind,
    w: size?.w ?? spec.w,
    h: size?.h ?? spec.h,
    config: _definitionConfig(definition),
  );
}

Map<String, dynamic> _definitionConfig(
  DailyWidgetDefinition<dynamic>? definition,
) {
  final config = definition?.defaultConfig();
  if (config is! Map) return {};

  return {
    for (final entry in config.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

class _DefaultWidgetSpec {
  const _DefaultWidgetSpec(this.kind, this.w, this.h);

  final String kind;
  final int w;
  final int h;
}

enum _PageAction { rename, duplicate, delete }

class PageTabs extends StatefulWidget {
  const PageTabs({
    super.key,
    required this.pages,
    required this.activePageId,
    this.registry,
    this.onPagesChanged,
    this.onActivePageChanged,
  });

  final List<LayoutPage> pages;
  final String activePageId;
  final WidgetRegistry? registry;
  final ValueChanged<List<LayoutPage>>? onPagesChanged;
  final ValueChanged<String>? onActivePageChanged;

  @override
  State<PageTabs> createState() => _PageTabsState();
}

class _PageTabsState extends State<PageTabs> {
  late List<LayoutPage> _pages;
  late String _activePageId;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant PageTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages != widget.pages ||
        oldWidget.activePageId != widget.activePageId) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _pages = List<LayoutPage>.of(widget.pages);
    if (_pages.isEmpty) {
      _pages.add(createDefaultDashboard(registry: widget.registry));
    }
    _activePageId = _pages.any((page) => page.id == widget.activePageId)
        ? widget.activePageId
        : _pages.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('工作台', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              tooltip: _editing ? '完成排序' : '排序页面',
              onPressed: () => setState(() => _editing = !_editing),
              icon: Icon(_editing ? Icons.check : Icons.drag_indicator),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              onPressed: _addBlankPage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ 空白页'),
            ),
            OutlinedButton.icon(
              onPressed: _addDefaultPage,
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
              label: const Text('+ 默认布局页'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(height: 44, child: _buildTabStrip()),
      ],
    );
  }

  Widget _buildTabStrip() {
    if (_editing) {
      return ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: _pages.length,
        onReorder: _reorder,
        itemBuilder: (context, index) {
          final page = _pages[index];
          return ReorderableDragStartListener(
            key: ValueKey(page.id),
            index: index,
            child: _buildTab(page),
          );
        },
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _pages.length,
      separatorBuilder: (context, index) => const SizedBox(width: 6),
      itemBuilder: (context, index) => _buildTab(_pages[index]),
    );
  }

  Widget _buildTab(LayoutPage page) {
    final selected = page.id == _activePageId;
    return GestureDetector(
      onSecondaryTapDown: (details) => _showPageMenu(
        page,
        details.globalPosition,
      ),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          key: Key('page-tab-${page.id}'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => _selectPage(page.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(page.name),
                const SizedBox(width: 4),
                PopupMenuButton<_PageAction>(
                  tooltip: '页面操作',
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  onSelected: (action) => _runPageAction(page, action),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _PageAction.rename,
                      child: Text('重命名'),
                    ),
                    PopupMenuItem(
                      value: _PageAction.duplicate,
                      child: Text('复制本页'),
                    ),
                    PopupMenuItem(
                      value: _PageAction.delete,
                      child: Text('删除'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectPage(String id) {
    if (_activePageId == id) return;
    setState(() => _activePageId = id);
    widget.onActivePageChanged?.call(id);
  }

  void _addBlankPage() {
    final page = LayoutPage(
      id: newUlid(),
      name: '新工作台 ${_pages.length + 1}',
      widgets: const [],
    );
    _appendAndSelect(page);
  }

  void _addDefaultPage() {
    final page = createDefaultDashboard(
      registry: widget.registry,
      name: '默认工作台 ${_pages.length + 1}',
    );
    _appendAndSelect(page);
  }

  void _appendAndSelect(LayoutPage page) {
    setState(() {
      _pages = [..._pages, page];
      _activePageId = page.id;
    });
    _emit();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final page = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, page);
    });
    _emit();
  }

  Future<void> _showPageMenu(LayoutPage page, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_PageAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: _PageAction.rename, child: Text('重命名')),
        PopupMenuItem(value: _PageAction.duplicate, child: Text('复制本页')),
        PopupMenuItem(value: _PageAction.delete, child: Text('删除')),
      ],
    );
    if (action != null && mounted) {
      await _runPageAction(page, action);
    }
  }

  Future<void> _runPageAction(
    LayoutPage page,
    _PageAction action,
  ) async {
    switch (action) {
      case _PageAction.rename:
        await _renamePage(page);
      case _PageAction.duplicate:
        _appendAndSelect(copyPage(page));
      case _PageAction.delete:
        await _deletePage(page);
    }
  }

  Future<void> _renamePage(LayoutPage page) async {
    final controller = TextEditingController(text: page.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名页面'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '页面名称'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;

    setState(() {
      _pages = [
        for (final item in _pages)
          if (item.id == page.id)
            LayoutPage(id: item.id, name: trimmed, widgets: item.widgets)
          else
            item,
      ];
    });
    _emit();
  }

  Future<void> _deletePage(LayoutPage page) async {
    final confirmed = await ConfirmModal.show(
      context: context,
      title: '删除页面',
      message: '页面布局将被删除，习惯打卡等本地数据不会因此清除。',
      confirmText: '删除',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      if (_pages.length == 1) {
        final replacement = createDefaultDashboard(registry: widget.registry);
        _pages = [replacement];
        _activePageId = replacement.id;
      } else {
        final removedIndex = _pages.indexWhere((item) => item.id == page.id);
        _pages = _pages.where((item) => item.id != page.id).toList();
        if (_activePageId == page.id) {
          final nextIndex = removedIndex.clamp(0, _pages.length - 1);
          _activePageId = _pages[nextIndex].id;
        }
      }
    });
    _emit();
  }

  void _emit() {
    widget.onPagesChanged?.call(List<LayoutPage>.unmodifiable(_pages));
    widget.onActivePageChanged?.call(_activePageId);
  }
}

class ConfirmModal extends StatelessWidget {
  const ConfirmModal({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.danger = false,
  });

  final String title;
  final String message;
  final String confirmText;
  final bool danger;

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    bool danger = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmModal(
        title: title,
        message: message,
        confirmText: confirmText,
        danger: danger,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
