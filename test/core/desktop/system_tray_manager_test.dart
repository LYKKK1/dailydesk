import 'package:dailydesk/core/desktop/system_tray_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('托盘菜单含四项固定动作', () {
    final menu =
        buildTrayMenu(isPomodoroRunning: false).map((item) => item.key).toSet();
    expect(menu, containsAll(['open', 'pomodoro', 'sync', 'quit']));
  });

  test('番茄进行中时菜单文案切换为暂停', () {
    final pomodoro = buildTrayMenu(isPomodoroRunning: true)
        .firstWhere((item) => item.key == 'pomodoro');
    expect(pomodoro.label, contains('暂停'));
  });
}
