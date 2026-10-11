import 'package:dailydesk/core/desktop/window_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('关闭动作决策：默认隐藏到托盘', () {
    expect(
      decideCloseAction(closeToTrayEnabled: true),
      CloseAction.hideToTray,
    );
  });

  test('用户关闭托盘常驻时为真退出', () {
    expect(decideCloseAction(closeToTrayEnabled: false), CloseAction.exit);
  });
}
