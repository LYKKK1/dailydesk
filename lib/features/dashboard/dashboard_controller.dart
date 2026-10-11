import 'dart:async';
import 'dart:collection';

import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:flutter/foundation.dart';

enum DashboardChangeKind { data, layout }

class DashboardController extends ChangeNotifier {
  DashboardController({WidgetRegistry? registry})
      : registry = registry ?? WidgetRegistry(),
        _pages = [
          LayoutPage(id: newUlid(), name: '默认工作台', widgets: []),
        ],
        _activePageId = '';

  final WidgetRegistry registry;
  final List<LayoutPage> _pages;
  String _activePageId;
  String? _selectedWidgetId;

  int _rowHeight = 56;
  int _spacing = 12;
  int _maxWidth = 1440;
  bool _layoutOnly = false;
  DashboardChangeKind _lastChangeKind = DashboardChangeKind.data;
  int _revision = 0;

  List<LayoutPage> get pages => List.unmodifiable(_pages);
  UnmodifiableListView<WidgetInstance> get pageWidgets =>
      UnmodifiableListView(activePage.widgets);
  String get activePageId {
    if (_activePageId.isEmpty || !_containsPage(_activePageId)) {
      _activePageId = _pages.first.id;
    }
    return _activePageId;
  }

  LayoutPage get activePage => _pages.firstWhere(
        (page) => page.id == activePageId,
        orElse: () => _pages.first,
      );

  List<WidgetInstance> get ordered {
    final indexed = pageWidgets.indexed.toList()
      ..sort((a, b) {
        final left = a.$2.config['sortOrder'] as int? ?? a.$1;
        final right = b.$2.config['sortOrder'] as int? ?? b.$1;
        final order = left.compareTo(right);
        return order != 0 ? order : a.$1.compareTo(b.$1);
      });
    return indexed.map((entry) => entry.$2).toList();
  }

  WidgetInstance? get selectedWidget {
    final id = _selectedWidgetId;
    if (id == null) return null;
    for (final widget in pageWidgets) {
      if (widget.id == id) return widget;
    }
    return null;
  }

  String? get selectedWidgetId => _selectedWidgetId;
  int get rowHeight => _rowHeight;
  int get spacing => _spacing;
  int get maxWidth => _maxWidth;
  bool get layoutOnly => _layoutOnly;
  DashboardChangeKind get lastChangeKind => _lastChangeKind;
  int get revision => _revision;

  void load(List<WidgetInstance> widgets) {
    final orderedWidgets = List<WidgetInstance>.of(widgets).indexed.toList()
      ..sort((a, b) {
        final left = a.$2.config['sortOrder'] as int? ?? a.$1;
        final right = b.$2.config['sortOrder'] as int? ?? b.$1;
        final order = left.compareTo(right);
        return order != 0 ? order : a.$1.compareTo(b.$1);
      });
    _pages
      ..clear()
      ..add(
        LayoutPage(
          id: newUlid(),
          name: '默认工作台',
          widgets: orderedWidgets.map((entry) => entry.$2).toList(),
        ),
      );
    _activePageId = _pages.first.id;
    _selectedWidgetId = null;
    _renumber();
    notifyDataChanged();
  }

  void loadLayout(SanitizedLayout layout) {
    _pages
      ..clear()
      ..addAll(layout.pages);
    _activePageId = layout.activePageId;
    _selectedWidgetId = null;
    _renumber();
    notifyDataChanged();
  }

  String addPage(String name, {List<WidgetInstance> widgets = const []}) {
    final page = LayoutPage(
      id: newUlid(),
      name: name.trim().isEmpty ? '未命名工作台' : name.trim(),
      widgets: List.of(widgets),
    );
    _pages.add(page);
    _activePageId = page.id;
    _selectedWidgetId = null;
    _renumber();
    notifyDataChanged();
    return page.id;
  }

  bool renamePage(String id, String name) {
    if (name.trim().isEmpty) return false;
    final index = _pages.indexWhere((page) => page.id == id);
    if (index == -1) return false;
    final old = _pages[index];
    _pages[index] = LayoutPage(
      id: old.id,
      name: name.trim(),
      widgets: old.widgets,
    );
    notifyDataChanged();
    return true;
  }

  bool removePage(String id) {
    if (_pages.length <= 1) return false;
    final index = _pages.indexWhere((page) => page.id == id);
    if (index == -1) return false;
    final wasActive = activePageId == id;
    _pages.removeAt(index);
    if (wasActive) {
      _activePageId = _pages[index.clamp(0, _pages.length - 1)].id;
      _selectedWidgetId = null;
    }
    notifyDataChanged();
    return true;
  }

  bool selectPage(String id) {
    if (!_containsPage(id) || activePageId == id) return false;
    _activePageId = id;
    _selectedWidgetId = null;
    notifyDataChanged();
    return true;
  }

  void reorder({required int oldIndex, required int newIndex}) {
    final list = ordered;
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final insertionIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = list.removeAt(oldIndex);
    list.insert(insertionIndex.clamp(0, list.length), item);
    _replacePageWidgets(list);
    _renumber();
    notifyDataChanged();
  }

  /// 全边框拉伸钳制：列宽 1..12，行数 1..20。
  void resize(String id, {required int w, required int h}) {
    final item = _find(id);
    if (item == null) return;
    final nextW = w.clamp(1, 12);
    final nextH = h.clamp(1, 20);
    if (item.w == nextW && item.h == nextH) return;
    item
      ..w = nextW
      ..h = nextH;
    notifyDataChanged();
  }

  /// 复制组件：深拷贝 config + 全新 id，插到原卡片正后方。
  String? duplicate(String id) {
    final list = ordered;
    final index = list.indexWhere((item) => item.id == id);
    if (index == -1) return null;
    final source = list[index];
    final copy = WidgetInstance(
      id: newUlid(),
      kind: source.kind,
      w: source.w,
      h: source.h,
      config: _deepCopy(source.config),
    );
    list.insert(index + 1, copy);
    _replacePageWidgets(list);
    _renumber();
    _selectedWidgetId = copy.id;
    notifyDataChanged();
    return copy.id;
  }

  void moveForward(String id) {
    final list = ordered;
    final index = list.indexWhere((item) => item.id == id);
    if (index <= 0) return;
    final item = list.removeAt(index);
    list.insert(index - 1, item);
    _replacePageWidgets(list);
    _renumber();
    notifyDataChanged();
  }

  void moveBackward(String id) {
    final list = ordered;
    final index = list.indexWhere((item) => item.id == id);
    if (index == -1 || index >= list.length - 1) return;
    final item = list.removeAt(index);
    list.insert(index + 1, item);
    _replacePageWidgets(list);
    _renumber();
    notifyDataChanged();
  }

  void remove(String id) {
    final before = activePage.widgets.length;
    activePage.widgets.removeWhere((item) => item.id == id);
    if (activePage.widgets.length == before) return;
    if (_selectedWidgetId == id) _selectedWidgetId = null;
    _renumber();
    notifyDataChanged();
  }

  WidgetInstance? add(String kind) {
    final definition = registry.definitionOf(kind);
    if (definition == null) return null;
    final sourceConfig = definition.defaultConfig();
    final widget = WidgetInstance(
      id: newUlid(),
      kind: kind,
      w: definition.defaultSize.w,
      h: definition.defaultSize.h,
      config: sourceConfig is Map
          ? _deepCopy(Map<String, dynamic>.from(sourceConfig))
          : <String, dynamic>{},
    );
    activePage.widgets.add(widget);
    _selectedWidgetId = widget.id;
    _renumber();
    notifyDataChanged();
    return widget;
  }

  void selectWidget(String? id) {
    if (_selectedWidgetId == id) return;
    _selectedWidgetId = id;
    notifyDataChanged();
  }

  void updateConfig(String id, Map<String, dynamic> patch) {
    final item = _find(id);
    if (item == null) return;
    item.config = {
      ...item.config,
      ..._deepCopy(patch),
    };
    notifyDataChanged();
  }

  /// 网格三件套：调行高/间距只重排布局，不重拉组件数据。
  void beginLayoutOnly() {
    if (_layoutOnly) return;
    _layoutOnly = true;
    notifyListeners();
  }

  void endLayoutOnly() {
    if (!_layoutOnly) return;
    _layoutOnly = false;
    notifyListeners();
  }

  void setRowHeight(int value) {
    final next = (value.clamp(24, 96) ~/ 2) * 2;
    if (_rowHeight == next) return;
    _rowHeight = next;
    notifyLayoutChanged();
  }

  void setSpacing(int value) {
    final next = value.clamp(4, 40);
    if (_spacing == next) return;
    _spacing = next;
    notifyLayoutChanged();
  }

  void setMaxWidth(int value) {
    final next = value.clamp(0, 4000);
    if (_maxWidth == next) return;
    _maxWidth = next;
    notifyLayoutChanged();
  }

  void cycleSelectedWidth() {
    final selected = selectedWidget;
    if (selected == null) return;
    const widths = [4, 6, 8, 12];
    final current = widths.indexOf(selected.w);
    resize(selected.id,
        w: widths[(current + 1) % widths.length], h: selected.h);
  }

  /// 导出当前页的规范化 JSON。
  Map<String, dynamic> exportJson() => {
        'version': 1,
        'widgets': ordered.map((widget) => widget.toJson()).toList(),
      };

  Map<String, dynamic> exportLayoutJson() => {
        'version': 1,
        'activePageId': activePageId,
        'pages': _pages.map((page) => page.toJson()).toList(),
      };

  void notifyDataChanged() {
    _lastChangeKind = DashboardChangeKind.data;
    _revision++;
    notifyListeners();
  }

  void notifyLayoutChanged() {
    final previous = _layoutOnly;
    _layoutOnly = true;
    _lastChangeKind = DashboardChangeKind.layout;
    _revision++;
    notifyListeners();
    if (!previous) {
      scheduleMicrotask(() {
        if (!_isDisposed) _layoutOnly = false;
      });
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  WidgetInstance? _find(String id) {
    for (final item in activePage.widgets) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool _containsPage(String id) => _pages.any((page) => page.id == id);

  void _replacePageWidgets(List<WidgetInstance> widgets) {
    final page = activePage;
    activePage.widgets
      ..clear()
      ..addAll(widgets);
    assert(identical(page, activePage));
  }

  void _renumber() {
    for (var pageIndex = 0; pageIndex < _pages.length; pageIndex++) {
      final widgets = _pages[pageIndex].widgets;
      for (var i = 0; i < widgets.length; i++) {
        widgets[i].config['sortOrder'] = i;
      }
    }
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> source) => {
        for (final entry in source.entries)
          entry.key: _deepCopyValue(entry.value),
      };

  static dynamic _deepCopyValue(dynamic value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          '${entry.key}': _deepCopyValue(entry.value),
      };
    }
    if (value is List) return value.map(_deepCopyValue).toList();
    return value;
  }
}
