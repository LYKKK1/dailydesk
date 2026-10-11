import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/features/dashboard/presentation/widgets/resize_handles.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

WidgetInstance _instance() =>
    WidgetInstance(id: 'resizable', kind: 'known', w: 4, h: 3);

Widget _harness({
  required WidgetInstance instance,
  required DashboardController controller,
  double width = 1000,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: 240,
            child: ResizeHandles(
              instance: instance,
              controller: controller,
              rowHeight: 50,
              columnWidth: 50,
              forceLockWidth: false,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('宽屏暴露右边、底边和右下角手柄', (tester) async {
    final instance = _instance();
    final controller = DashboardController()..load([instance]);

    await tester.pumpWidget(
      _harness(instance: instance, controller: controller),
    );

    expect(find.byKey(const Key('resize-right')), findsOneWidget);
    expect(find.byKey(const Key('resize-bottom')), findsOneWidget);
    expect(find.byKey(const Key('resize-corner')), findsOneWidget);
  });

  testWidgets('窄屏隐藏右边缘并且对角手柄只调整高度', (tester) async {
    final instance = _instance();
    final controller = DashboardController()..load([instance]);
    await tester.pumpWidget(
      _harness(instance: instance, controller: controller, width: 700),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 700,
              height: 240,
              child: ResizeHandles(
                instance: instance,
                controller: controller,
                rowHeight: 50,
                columnWidth: 50,
                forceLockWidth: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('resize-right')), findsNothing);
    expect(find.byKey(const Key('resize-corner')), findsOneWidget);
  });

  testWidgets('聚焦右边手柄后方向键逐列调整', (tester) async {
    final instance = _instance();
    final controller = DashboardController()..load([instance]);
    await tester.pumpWidget(
      _harness(instance: instance, controller: controller),
    );

    await tester.tap(find.byKey(const Key('resize-right')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(instance.w, 5);
  });

  testWidgets('Escape 取消进行中的拉伸并恢复起始尺寸', (tester) async {
    final instance = _instance();
    final controller = DashboardController()..load([instance]);
    await tester.pumpWidget(
      _harness(instance: instance, controller: controller),
    );
    final handle = find.byKey(const Key('resize-right'));

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(instance.w, greaterThan(4));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(instance.w, 4);
    expect(instance.h, 3);
    await gesture.up();
  });
}
