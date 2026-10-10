import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/foundation.dart';

typedef RegistryChangeListener = void Function(String kind, bool registered);

class WidgetRegistry {
  final Map<String, DailyWidgetDefinition<dynamic>> _byKind = {};
  final Set<String> _builtinKinds = {};
  final List<RegistryChangeListener> _listeners = [];

  VoidCallback register(
    DailyWidgetDefinition<dynamic> definition, {
    bool builtin = false,
  }) {
    if (_builtinKinds.contains(definition.kind)) {
      throw ArgumentError('Built-in kind "${definition.kind}" is protected');
    }
    _byKind[definition.kind] = definition;
    if (builtin) {
      _builtinKinds.add(definition.kind);
    }
    _notify(definition.kind, true);
    return () => unregister(definition.kind);
  }

  void unregister(String kind) {
    if (_byKind.remove(kind) != null) {
      _notify(kind, false);
    }
  }

  DailyWidgetDefinition<dynamic>? definitionOf(String kind) => _byKind[kind];

  bool isWidgetKind(String? kind) => kind != null && kind.isNotEmpty;

  VoidCallback onRegistryChange(RegistryChangeListener listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notify(String kind, bool registered) {
    for (final listener in List<RegistryChangeListener>.of(_listeners)) {
      listener(kind, registered);
    }
  }
}
