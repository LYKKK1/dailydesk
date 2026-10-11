import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'window_lifecycle.dart';

class TrayMenuItem {
  const TrayMenuItem(this.key, this.label);

  final String key;
  final String label;
}

List<TrayMenuItem> buildTrayMenu({required bool isPomodoroRunning}) => [
      const TrayMenuItem('open', '打开工作台'),
      TrayMenuItem(
        'pomodoro',
        isPomodoroRunning ? '暂停番茄钟' : '开启番茄钟',
      ),
      const TrayMenuItem('sync', '局域网同步'),
      const TrayMenuItem('quit', '彻底退出'),
    ];

class SystemTrayManager {
  SystemTrayManager({
    this.onCommand,
    this.iconPath = 'assets/app_icon.ico',
  });

  final SystemTray _tray = SystemTray();
  final void Function(String key)? onCommand;
  final String iconPath;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    await _tray.initSystemTray(
      title: 'DailyDesk',
      iconPath: iconPath,
      toolTip: 'DailyDesk',
    );

    final menu = buildTrayMenu(isPomodoroRunning: false)
        .map(
          (item) => MenuItem(
            label: item.label,
            onClicked: () => _handleCommand(item.key),
          ),
        )
        .toList(growable: false);
    await _tray.setContextMenu(menu);

    _tray.registerSystemTrayEventHandler((eventName) {
      if (eventName == 'leftMouseUp') {
        WindowLifecycle.instance.restoreAndFocus();
      } else if (eventName == 'rightMouseUp') {
        _tray.popUpContextMenu();
      }
    });
    _initialized = true;
  }

  Future<void> _handleCommand(String key) async {
    onCommand?.call(key);
    if (key == 'quit') {
      await windowManager.destroy();
    }
  }

  Future<void> dispose() async {
    if (_initialized) {
      await _tray.setImage('');
      _initialized = false;
    }
  }
}
