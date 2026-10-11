import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDefinition extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'fake';

  @override
  String get name => 'Fake';

  @override
  IconData get icon => Icons.abc;

  @override
  ({int w, int h}) get defaultSize => (w: 4, h: 3);

  @override
  Map<String, dynamic> defaultConfig() => {'limit': 3};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) => raw;

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();

  @override
  Widget renderSettings(
    BuildContext context,
    WidgetSettingsContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();
}

void main() {
  test('register supports lookup and returned disposer unregisters', () {
    final registry = WidgetRegistry();
    final dispose = registry.register(_FakeDefinition(), builtin: true);

    expect(registry.definitionOf('fake'), isNotNull);
    dispose();
    expect(registry.definitionOf('fake'), isNull);
  });

  test('built-in kinds cannot be overwritten', () {
    final registry = WidgetRegistry();
    registry.register(_FakeDefinition(), builtin: true);

    expect(
      () => registry.register(_FakeDefinition()),
      throwsArgumentError,
    );
  });

  test('unknown non-empty kinds remain valid', () {
    final registry = WidgetRegistry();

    expect(registry.isWidgetKind('third-party'), isTrue);
    expect(registry.isWidgetKind(''), isFalse);
    expect(registry.isWidgetKind(null), isFalse);
  });

  test('registry listeners receive registration changes', () {
    final registry = WidgetRegistry();
    String? changedKind;
    bool? registered;
    registry.onRegistryChange((kind, isRegistered) {
      changedKind = kind;
      registered = isRegistered;
    });

    registry.register(_FakeDefinition(), builtin: true);

    expect(changedKind, 'fake');
    expect(registered, isTrue);
  });
}
