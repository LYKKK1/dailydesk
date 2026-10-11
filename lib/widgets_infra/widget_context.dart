import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';

abstract class WidgetContext<C> {
  C get config;
  Timer registerInterval(void Function() cb, Duration period);
  void registerCleanup(VoidCallback cb);
  bool isAlive();
  Future<void> saveConfig(Map<String, dynamic> patch);
  void rerender();
}

abstract class WidgetSettingsContext<C> {
  C get draft;
  Future<void> save();
}

class LiveWidgetContext<C> extends WidgetContext<C> {
  LiveWidgetContext({
    required bool Function() isMounted,
    required this.instance,
    required this.onConfigSaved,
    required this.onRerender,
  }) : _isMounted = isMounted;

  final bool Function() _isMounted;
  final WidgetInstance instance;
  final Future<void> Function(Map<String, dynamic> patch) onConfigSaved;
  final VoidCallback onRerender;

  final _timers = <Timer>[];
  final _cleanups = <VoidCallback>[];

  C? parsedConfig;
  bool _isDisposed = false;

  @override
  C get config => parsedConfig as C;

  @override
  Timer registerInterval(void Function() cb, Duration period) {
    final timer = Timer.periodic(period, (_) {
      if (isAlive()) cb();
    });
    _timers.add(timer);
    return timer;
  }

  @override
  void registerCleanup(VoidCallback cb) => _cleanups.add(cb);

  @override
  bool isAlive() => !_isDisposed && _isMounted();

  @override
  Future<void> saveConfig(Map<String, dynamic> patch) => onConfigSaved(patch);

  @override
  void rerender() {
    if (isAlive()) onRerender();
  }

  void dispose() {
    _isDisposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final cleanup in _cleanups) {
      cleanup();
    }
    _timers.clear();
    _cleanups.clear();
  }
}
