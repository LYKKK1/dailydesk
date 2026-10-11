import 'package:dailydesk/features/floating_dock/floating_dock_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('悬停不足 150ms 不展开', () {
    final controller = FloatingDockController();
    expect(
      controller.decide(
        hovered: true,
        hoverDuration: const Duration(milliseconds: 100),
      ),
      DockState.collapsed,
    );
  });

  test('悬停超过 150ms 展开', () {
    final controller = FloatingDockController();
    expect(
      controller.decide(
        hovered: true,
        hoverDuration: const Duration(milliseconds: 200),
      ),
      DockState.expanded,
    );
  });

  test('离开超过 400ms 收缩', () {
    final controller = FloatingDockController();
    controller.decide(
      hovered: true,
      hoverDuration: const Duration(milliseconds: 200),
    );
    expect(
      controller.decide(
        hovered: false,
        hoverDuration: const Duration(milliseconds: 500),
      ),
      DockState.collapsed,
    );
  });
}
