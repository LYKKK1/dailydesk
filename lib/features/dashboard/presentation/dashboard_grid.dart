import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/features/dashboard/presentation/widgets/widget_host.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/material.dart';

/// Two-dimensional 12-column dashboard layout.
///
/// Widgets keep their declared column span and flow into rows so two half-width
/// cards actually render side by side instead of each consuming a full row.
class DashboardGrid extends StatelessWidget {
  const DashboardGrid({
    super.key,
    required this.widgets,
    required this.controller,
    required this.editMode,
    this.compact = false,
  });

  final List<WidgetInstance> widgets;
  final DashboardController controller;
  final bool editMode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = _packRows(widgets);
    final spacing = controller.spacing.toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth =
            compact ? constraints.maxWidth : constraints.maxWidth / 12;
        return ListView.builder(
          padding: EdgeInsets.all(spacing + 4),
          itemCount: rows.length,
          itemBuilder: (context, rowIndex) {
            final row = rows[rowIndex];
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < row.length; index++) ...[
                    Expanded(
                      flex: row[index].span,
                      child: _GridSlot(
                        key: ValueKey(row[index].instance.id),
                        instance: row[index].instance,
                        controller: controller,
                        editMode: editMode,
                        columnWidth: columnWidth,
                      ),
                    ),
                    if (index != row.length - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<List<_GridSlotData>> _packRows(List<WidgetInstance> source) {
    if (compact) {
      return [
        for (var index = 0; index < source.length; index++)
          [
            _GridSlotData(
              instance: source[index],
              span: 12,
            ),
          ],
      ];
    }

    final rows = <List<_GridSlotData>>[];
    var current = <_GridSlotData>[];
    var used = 0;
    for (final item in source) {
      final span = item.w.clamp(1, 12);
      if (used + span > 12 && current.isNotEmpty) {
        rows.add(current);
        current = <_GridSlotData>[];
        used = 0;
      }
      current.add(
        _GridSlotData(
          instance: item,
          span: span,
        ),
      );
      used += span;
      if (used >= 12) {
        rows.add(current);
        current = <_GridSlotData>[];
        used = 0;
      }
    }
    if (current.isNotEmpty) {
      rows.add(current);
    }
    return rows;
  }
}

class _GridSlotData {
  const _GridSlotData({
    required this.instance,
    required this.span,
  });

  final WidgetInstance instance;
  final int span;
}

class _GridSlot extends StatelessWidget {
  const _GridSlot({
    super.key,
    required this.instance,
    required this.controller,
    required this.editMode,
    required this.columnWidth,
  });

  final WidgetInstance instance;
  final DashboardController controller;
  final bool editMode;
  final double columnWidth;

  @override
  Widget build(BuildContext context) {
    final height = (instance.h * controller.rowHeight).clamp(140, 800);
    return SizedBox(
      height: height.toDouble(),
      child: WidgetHost(
        instance: instance,
        registry: controller.registry,
        controller: controller,
        editMode: editMode,
        rowHeight: controller.rowHeight.toDouble(),
        columnWidth: columnWidth,
        onDragStarted: () => controller.selectWidget(instance.id),
      ),
    );
  }
}
