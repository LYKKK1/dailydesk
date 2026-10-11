import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class QuickCaptureService {
  QuickCaptureService({required this.onTriggered});

  final VoidCallback onTriggered;

  HotKey? _hotKey;

  Future<void> init() async {
    if (_hotKey != null) {
      return;
    }

    final hotKey = HotKey(
      key: PhysicalKeyboardKey.space,
      modifiers: const [HotKeyModifier.alt],
    );
    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => onTriggered(),
      );
      _hotKey = hotKey;
    } on MissingPluginException catch (error) {
      debugPrint('Quick capture hotkey unavailable: $error');
    } on PlatformException catch (error) {
      debugPrint('Quick capture hotkey registration failed: $error');
    }
  }

  Future<void> dispose() async {
    final hotKey = _hotKey;
    if (hotKey == null) {
      return;
    }

    try {
      await hotKeyManager.unregister(hotKey);
    } on MissingPluginException catch (error) {
      debugPrint('Quick capture hotkey unavailable during disposal: $error');
    } on PlatformException catch (error) {
      debugPrint('Quick capture hotkey unregister failed: $error');
    } finally {
      _hotKey = null;
    }
  }
}
