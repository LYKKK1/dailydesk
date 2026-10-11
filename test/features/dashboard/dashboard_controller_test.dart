import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WidgetInstance _w(String kind, int order) =>
    WidgetInstance(id: '${kind}_$order', kind: kind, w: 4, h: 3)
      ..config['sortOrder'] = order;

class _Definition extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'sample';

  @override
  String get name => 'Sample';

  @override
  IconData get icon => Icons.widgets;

  @override
  ({int w, int h}) get defaultSize => (w: 6, h: 4);

  @override
  Map<String, dynamic> defaultConfig() => {
        'nested': {'value': 1},
      };

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) => raw;

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();

  @override
  Widget renderSettings(
    BuildContext context,
    WidgetSettingsContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();
}

void main() {
  test('拖拽重排：交换后 sortOrder 重排', () {
    final c = DashboardController();
    final a = _w('todo', 0);
    final b = _w('pomodoro', 1);
    final d = _w('habit', 2);
    c.load([a, b, d]);

    c.reorder(oldIndex: 2, newIndex: 0);

    expect(
        c.ordered.map((w) => w.kind).toList(), ['habit', 'todo', 'pomodoro']);
    expect(c.ordered.map((w) => w.config['sortOrder']).toList(), [0, 1, 2]);
  });

  test('resize 钳制：w 1..12，h 1..20', () {
    final c = DashboardController();
    final a = _w('todo', 0);
    c.load([a]);

    c.resize(a.id, w: 99, h: -3);

    expect(a.w, 12);
    expect(a.h, 1);
  });

  test('复制组件：新 id、深拷贝 config、插到原卡片正后方', () {
    final c = DashboardController();
    final a = _w('todo', 0);
    final b = _w('habit', 1);
    a.config['nested'] = {'value': 2};
    c.load([a, b]);

    final copyId = c.duplicate(a.id);
    final copy = c.ordered[1];
    (copy.config['nested'] as Map<String, dynamic>)['value'] = 9;

    expect(copyId, isNot(a.id));
    expect(c.ordered.map((w) => w.kind).toList(), ['todo', 'todo', 'habit']);
    expect(copy.id, copyId);
    expect(a.config['nested']['value'], 2);
  });

  test('前移后移', () {
    final c = DashboardController();
    final a = _w('todo', 0);
    final b = _w('habit', 1);
    c.load([a, b]);

    c.moveForward(b.id);
    expect(c.ordered.first.kind, 'habit');
    c.moveBackward(b.id);
    expect(c.ordered.first.kind, 'todo');
  });

  test('add 使用注册表默认尺寸与配置', () {
    final registry = WidgetRegistry()..register(_Definition(), builtin: true);
    final c = DashboardController(registry: registry);

    c.add('sample');

    expect(c.ordered.single.kind, 'sample');
    expect(c.ordered.single.w, 6);
    expect(c.ordered.single.h, 4);
    expect(
      (c.ordered.single.config['nested'] as Map<String, dynamic>)['value'],
      1,
    );
  });

  test('页面 CRUD 保持活动页与导出数据一致', () {
    final c = DashboardController()..load([_w('todo', 0)]);
    final secondPageId = c.addPage('周末');

    expect(c.pages, hasLength(2));
    expect(c.activePageId, secondPageId);
    expect(c.ordered, isEmpty);

    c.add('existing-kind');
    expect(c.ordered, isEmpty, reason: '未注册组件不应写入页面');

    c.renamePage(secondPageId, '休息日');
    expect(c.pages.last.name, '休息日');
    expect(c.selectPage(c.pages.first.id), isTrue);
    expect(c.ordered.single.kind, 'todo');

    expect(c.removePage(secondPageId), isTrue);
    expect(c.pages, hasLength(1));
    expect(c.removePage(c.activePageId), isFalse);
  });

  test('网格设置钳制与 layoutOnly 状态', () {
    final c = DashboardController();

    c.beginLayoutOnly();
    c.setRowHeight(101);
    c.setSpacing(1);
    c.setMaxWidth(9000);

    expect(c.layoutOnly, isTrue);
    expect(c.rowHeight, 96);
    expect(c.spacing, 4);
    expect(c.maxWidth, 4000);

    c.endLayoutOnly();
    expect(c.layoutOnly, isFalse);
  });
}
