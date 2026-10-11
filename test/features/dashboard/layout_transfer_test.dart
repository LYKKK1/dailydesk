import 'dart:convert';

import 'package:dailydesk/features/dashboard/layout_transfer.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';
import 'package:flutter_test/flutter_test.dart';

LayoutPage _page(String id, String name) => LayoutPage(
      id: id,
      name: name,
      widgets: [
        WidgetInstance(
          id: 'w-$id',
          kind: 'todo',
          w: 4,
          h: 3,
          config: {
            'nested': {'value': 1},
          },
        ),
      ],
    );

void main() {
  test('导出带版本号且 round-trip 保留 kind/尺寸', () {
    final json = exportJson([_page('p1', '工作台')], 'p1');

    expect(json, contains('"version": 1'));
    final back = importPages(json, []);
    expect(back.single.name, '工作台');
    expect(back.single.widgets.single.kind, 'todo');
    expect(back.single.widgets.single.w, 4);
  });

  test('导入 id 全部重新生成，绝不与现有冲突', () {
    final json = exportJson([_page('p1', 'A')], 'p1');

    final imported = importPages(json, [_page('p1', 'A')]);

    expect(imported.single.id, isNot('p1'));
    expect(imported.single.widgets.single.id, isNot('w-p1'));
  });

  test('导入追加不覆盖：只返回新导入集合', () {
    final json = exportJson([_page('x', '外来页')], 'x');
    final existing = [_page('p1', '本地页')];

    final imported = importPages(json, existing);

    expect(imported.single.name, '外来页');
    expect(existing.single.name, '本地页');
  });

  test('复制页面：新 id + 副本名 + widget id 重生成', () {
    final source = _page('p1', '冲刺');
    final copy = copyPage(source);

    expect(copy.id, isNot(source.id));
    expect(copy.name, '冲刺 副本');
    expect(copy.widgets.single.id, isNot(source.widgets.single.id));
    expect(copy.widgets.single.kind, 'todo');
  });

  test('垃圾输入导入得到空集合（不崩）', () {
    expect(importPages('not json at all', []), isEmpty);
  });

  test('兼容裸数组、包装和单页，并清洗坏 widget', () {
    final pageJson = _page('p1', 'A').toJson();
    final badWidget = {
      ...pageJson,
      'widgets': [
        {'id': 'w1', 'kind': 'todo', 'w': 99, 'h': -3},
        {'bad': true},
      ],
    };

    expect(
        importPages(jsonEncode([badWidget]), []).single.widgets.single.w, 12);
    expect(
      importPages(
          jsonEncode({
            'pages': [badWidget]
          }),
          []).single.widgets.single.w,
      12,
    );
    expect(importPages(jsonEncode(badWidget), []).single.widgets.single.w, 12);
  });

  test('空页面和非法页面不生成兜底默认页', () {
    expect(importPages('{"pages": []}', []), isEmpty);
    expect(importPages('{}', []), isEmpty);
  });

  test('导入和复制时深拷贝 config', () {
    final importedSource = _page('p1', 'A');
    final copiedSource = _page('p2', 'B');
    final imported = importPages(
      jsonEncode({
        'pages': [importedSource.toJson()]
      }),
      [],
    ).single;
    final copied = copyPage(copiedSource);

    (imported.widgets.single.config['nested']
        as Map<String, dynamic>)['value'] = 9;
    (copied.widgets.single.config['nested'] as Map<String, dynamic>)['value'] =
        9;

    expect(
      (importedSource.widgets.single.config['nested']
          as Map<String, dynamic>)['value'],
      1,
    );
    expect(
      (copiedSource.widgets.single.config['nested']
          as Map<String, dynamic>)['value'],
      1,
    );
  });
}
