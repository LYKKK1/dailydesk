import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/features/dashboard/presentation/widgets/widget_host.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _KnownDefinition extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'known';

  @override
  String get name => 'Known';

  @override
  IconData get icon => Icons.widgets;

  @override
  ({int w, int h}) get defaultSize => (w: 4, h: 3);

  @override
  Map<String, dynamic> defaultConfig() => {'limit': 2};

  @override
  Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) => {
        'limit': raw['limit'] is int ? raw['limit'] : 2,
      };

  @override
  Widget render(
    BuildContext context,
    WidgetContext<Map<String, dynamic>> ctx,
  ) =>
      Text('limit ${ctx.config['limit']}');

  @override
  Widget renderSettings(
    BuildContext context,
    WidgetSettingsContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();
}

WidgetInstance _instance(String kind) => WidgetInstance(
      id: '${kind}_id',
      kind: kind,
      w: 4,
      h: 3,
      config: {'limit': 7, 'preserved': true},
    );

void main() {
  testWidgets('未知 kind 渲染占位卡片，数据不丢', (tester) async {
    final unknown = _instance('future-plugin');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WidgetHost(
            instance: unknown,
            registry: WidgetRegistry(),
            editMode: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('placeholder-widget')), findsOneWidget);
    expect(find.textContaining('future-plugin'), findsOneWidget);
    expect(unknown.config['preserved'], isTrue);
  });

  testWidgets('已知 kind 先规范化配置再交给组件上下文', (tester) async {
    final registry = WidgetRegistry()..register(_KnownDefinition());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WidgetHost(
            instance: _instance('known'),
            registry: registry,
            editMode: false,
          ),
        ),
      ),
    );

    expect(find.text('limit 7'), findsOneWidget);
  });

  testWidgets('编辑模式显示拖拽手柄和完整操作组', (tester) async {
    final registry = WidgetRegistry()..register(_KnownDefinition());
    final instance = _instance('known');
    final controller = DashboardController(registry: registry)
      ..load([instance]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 240,
            child: WidgetHost(
              instance: instance,
              registry: registry,
              controller: controller,
              editMode: true,
              rowHeight: 56,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('widget-grip-known_id')), findsOneWidget);
    expect(find.byKey(const Key('move-forward-known_id')), findsOneWidget);
    expect(find.byKey(const Key('move-backward-known_id')), findsOneWidget);
    expect(find.byKey(const Key('duplicate-known_id')), findsOneWidget);
    expect(find.byKey(const Key('delete-known_id')), findsOneWidget);
  });

  testWidgets('编辑操作组删除组件并保留其后方卡片', (tester) async {
    final registry = WidgetRegistry()..register(_KnownDefinition());
    final first = _instance('known');
    final second = WidgetInstance(id: 'second', kind: 'known', w: 4, h: 3);
    final controller = DashboardController(registry: registry)
      ..load([first, second]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WidgetHost(
            instance: first,
            registry: registry,
            controller: controller,
            editMode: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('delete-known_id')));
    await tester.pump();

    expect(controller.ordered, hasLength(1));
    expect(controller.ordered.single.id, 'second');
  });

  testWidgets('组件保存配置回写实例和控制器', (tester) async {
    final definition = _SaveDefinition();
    final registry = WidgetRegistry()..register(definition);
    final instance = _instance('save');
    final controller = DashboardController(registry: registry)
      ..load([instance]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WidgetHost(
            instance: instance,
            registry: registry,
            controller: controller,
            editMode: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('save-config')));
    await tester.pump();

    expect(instance.config['saved'], isTrue);
    expect(controller.ordered.single.config['saved'], isTrue);
  });
}

class _SaveDefinition extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override
  String get kind => 'save';

  @override
  String get name => 'Save';

  @override
  IconData get icon => Icons.save;

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
      TextButton(
        key: const Key('save-config'),
        onPressed: () => ctx.saveConfig({'saved': true}),
        child: const Text('Save'),
      );

  @override
  Widget renderSettings(
    BuildContext context,
    WidgetSettingsContext<Map<String, dynamic>> ctx,
  ) =>
      const SizedBox.shrink();
}
