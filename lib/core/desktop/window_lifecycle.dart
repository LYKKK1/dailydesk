import 'dart:ui';

import 'package:window_manager/window_manager.dart';

enum CloseAction { hideToTray, exit }

CloseAction decideCloseAction({required bool closeToTrayEnabled}) =>
    closeToTrayEnabled ? CloseAction.hideToTray : CloseAction.exit;

class WindowLifecycle with WindowListener {
  WindowLifecycle._();

  static final WindowLifecycle instance = WindowLifecycle._();

  VoidCallback? onCloseRequested;

  Future<void> ensureInitialized() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1200, 820),
      minimumSize: Size(960, 640),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
  }

  Future<void> hideToTray() => windowManager.hide();

  Future<void> restoreAndFocus() async {
    await windowManager.show();
    await windowManager.restore();
    await windowManager.focus();
  }

  @override
  void onWindowClose() {
    onCloseRequested?.call();
  }
}
