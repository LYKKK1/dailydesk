import 'package:dailydesk/features/dashboard/presentation/page_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createDefaultDashboard 按注册表默认尺寸组装八个模块', () {
    final page = createDefaultDashboard();

    expect(page.name, '默认工作台');
    expect(page.widgets.length, 8);
    expect(page.widgets.first.w, 12);
    expect(page.widgets.first.h, 2);
    expect(page.widgets.map((widget) => widget.id).toSet().length, 8);
  });

  testWidgets('PageTabs 可新增空白页并切换到新页', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageTabs(
            pages: [createDefaultDashboard()],
            activePageId: 'initial',
          ),
        ),
      ),
    );

    await tester.tap(find.text('+ 空白页'));
    await tester.pumpAndSettle();

    expect(find.textContaining('新工作台'), findsOneWidget);
  });

  testWidgets('ConfirmModal danger 模式渲染确认与取消', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfirmModal(
            title: '删除页面',
            message: '习惯打卡等本地数据也会清除',
            confirmText: '删除',
            danger: true,
          ),
        ),
      ),
    );

    expect(find.text('删除页面'), findsOneWidget);
    expect(find.textContaining('习惯打卡'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });
}
