import 'package:dailydesk/widgets_infra/sanitize_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('三种输入形态兼容：裸数组 / 包装 / 单页', () {
    final page = {
      'id': 'p1',
      'name': '工作台',
      'widgets': [
        {'id': 'w1', 'kind': 'todo', 'w': 4, 'h': 3},
      ],
    };

    expect(sanitizeLayout([page]).pages.length, 1);
    expect(
        sanitizeLayout({
          'pages': [page]
        }).pages.length,
        1);
    expect(sanitizeLayout(page).pages.length, 1);
  });

  test('孤儿 activePageId 自动回退第一页', () {
    final result = sanitizeLayout({
      'activePageId': 'ghost',
      'pages': [
        {'id': 'p1', 'name': 'A', 'widgets': []},
        {'id': 'p2', 'name': 'B', 'widgets': []},
      ],
    });

    expect(result.activePageId, 'p1');
  });

  test('坏 widget 被丢弃，页面其余保留', () {
    final result = sanitizeLayout({
      'pages': [
        {
          'id': 'p1',
          'name': 'A',
          'widgets': [
            {'id': 'w1', 'kind': 'todo', 'w': 4, 'h': 3},
            {'bad': true},
            {'id': 'w2', 'kind': '', 'w': 4, 'h': 3},
          ],
        },
      ],
    });

    expect(result.pages.single.widgets.length, 1);
  });

  test('w/h 钳制进 1..12 / 1..20', () {
    final result = sanitizeLayout({
      'pages': [
        {
          'id': 'p1',
          'name': 'A',
          'widgets': [
            {'id': 'w1', 'kind': 'todo', 'w': 99, 'h': -3},
          ],
        },
      ],
    });

    final widget = result.pages.single.widgets.single;
    expect(widget.w, 12);
    expect(widget.h, 1);
  });

  test('全垃圾输入兜底出默认页', () {
    final result = sanitizeLayout(42);

    expect(result.pages.length, 1);
    expect(result.pages.first.name, '默认工作台');
  });
}
