import 'dart:async';

import 'package:flutter/widgets.dart';

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
