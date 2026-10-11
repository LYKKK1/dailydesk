import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WidgetInstance testInstance() =>
      WidgetInstance(id: 't', kind: 't', w: 4, h: 3);

  test('registerInterval 定时回调执行且 isAlive 为 false 后不再执行', () async {
    var alive = true;
    var count = 0;
    final context = LiveWidgetContext<Map<String, dynamic>>(
      isMounted: () => alive,
      instance: testInstance(),
      onConfigSaved: (_) async {},
      onRerender: () {},
    )..parsedConfig = {};

    context.registerInterval(
      () => count++,
      const Duration(milliseconds: 10),
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));

    alive = false;
    final countAtDisposal = count;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    context.dispose();

    expect(count, greaterThan(1));
    expect(count, countAtDisposal);
  });

  test('dispose 后 cleanup 执行且 isAlive 为 false', () {
    var alive = true;
    final context = LiveWidgetContext<Map<String, dynamic>>(
      isMounted: () => alive,
      instance: testInstance(),
      onConfigSaved: (_) async {},
      onRerender: () {},
    )..parsedConfig = {};
    var cleaned = false;

    context.registerCleanup(() => cleaned = true);
    context.dispose();

    expect(cleaned, isTrue);
    expect(context.isAlive(), isFalse);
  });

  test('saveConfig 不触发 rerender，显式调用才重绘', () async {
    var rerenders = 0;
    var alive = true;
    final context = LiveWidgetContext<Map<String, dynamic>>(
      isMounted: () => alive,
      instance: testInstance(),
      onConfigSaved: (_) async {},
      onRerender: () => rerenders++,
    )..parsedConfig = {};

    await context.saveConfig({'a': 2});
    expect(rerenders, 0);

    context.rerender();
    expect(rerenders, 1);

    context.dispose();
  });
}
