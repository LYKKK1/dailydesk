import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/features/dashboard/presentation/widgets/widget_catalog_drawer.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CatalogDefinition extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'matrix';

  @override
  String get name => 'Catalog Test';

  @override
  IconData get icon => Icons.widgets_outlined;

  @override
  ({int w, int h}) get defaultSize => (w: 4, h: 3);

  @override
  Map<String, dynamic> defaultConfig() => {};

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
  testWidgets('抽屉可添加并移除模块', (tester) async {
    final registry = WidgetRegistry()..register(_CatalogDefinition());
    final controller = DashboardController(registry: registry);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WidgetCatalogDrawer(controller: controller)),
      ),
    );

    await tester.tap(find.byKey(const Key('catalog-add-matrix')));
    await tester.pump();
    expect(controller.ordered, hasLength(1));

    await tester.tap(
      find.byKey(Key('catalog-remove-${controller.ordered.single.id}')),
    );
    await tester.pump();
    expect(controller.ordered, isEmpty);
  });
}
