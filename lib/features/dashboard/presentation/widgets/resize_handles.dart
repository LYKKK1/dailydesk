import 'dart:math' as math;

import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ResizeMode { width, height, both }

class _ResizeStart {
  const _ResizeStart({
    required this.pointer,
    required this.position,
    required this.w,
    required this.h,
  });

  final int pointer;
  final Offset position;
  final int w;
  final int h;
}

class ResizeHandles extends StatefulWidget {
  const ResizeHandles({
    super.key,
    required this.instance,
    required this.controller,
    required this.rowHeight,
    this.columnWidth,
    this.forceLockWidth,
    this.enabled = true,
  });

  final WidgetInstance instance;
  final DashboardController controller;
  final double rowHeight;
  final double? columnWidth;
  final bool? forceLockWidth;
  final bool enabled;

  @override
  State<ResizeHandles> createState() => _ResizeHandlesState();
}

class _ResizeHandlesState extends State<ResizeHandles> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'dashboard-resize');
  _ResizeStart? _start;
  _ResizeMode? _mode;
  Offset? _pointerPosition;
  OverlayEntry? _badgeEntry;
  int? _globalPointer;
  bool _applying = false;
  bool _lockWidth = false;

  @override
  void dispose() {
    _removeGlobalRoute();
    _badgeEntry?.remove();
    _badgeEntry = null;
    _rollbackIfNeeded();
    _focusNode.dispose();
    super.dispose();
  }

  void _startDrag(
    PointerDownEvent event,
    _ResizeMode mode,
    bool lockWidth,
  ) {
    if (!widget.enabled || _start != null) return;
    _focusNode.requestFocus();
    _mode = lockWidth && mode != _ResizeMode.height ? _ResizeMode.height : mode;
    _start = _ResizeStart(
      pointer: event.pointer,
      position: event.position,
      w: widget.instance.w,
      h: widget.instance.h,
    );
    _pointerPosition = event.position;
    widget.controller.beginLayoutOnly();
    _showBadge();
    _globalPointer = event.pointer;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointer);
  }

  void _updateDrag(PointerMoveEvent event, double columnWidth) {
    final start = _start;
    final mode = _mode;
    if (start == null || mode == null || event.pointer != start.pointer) return;
    _pointerPosition = event.position;
    final delta = event.position - start.position;
    final columns = math.max(1, columnWidth);
    final nextW = mode == _ResizeMode.height
        ? start.w
        : start.w + (delta.dx / columns).round();
    final nextH = mode == _ResizeMode.width
        ? start.h
        : start.h + (delta.dy / widget.rowHeight).round();
    _applying = true;
    widget.controller.resize(widget.instance.id, w: nextW, h: nextH);
    _applying = false;
    _refreshBadge();
  }

  void _finishDrag([PointerEvent? event]) {
    final start = _start;
    if (start == null || (event != null && event.pointer != start.pointer)) {
      return;
    }
    _clearDrag();
  }

  void _cancelDrag() {
    if (_start == null) return;
    _rollbackIfNeeded();
    _clearDrag();
  }

  void _handleGlobalPointer(PointerEvent event) {
    if (event.pointer != _globalPointer) return;
    if (event is PointerRemovedEvent || event is PointerCancelEvent) {
      _cancelDrag();
    } else if (event is PointerUpEvent) {
      _finishDrag(event);
    }
  }

  void _rollbackIfNeeded() {
    final start = _start;
    if (start == null || _applying) return;
    if (widget.instance.w != start.w || widget.instance.h != start.h) {
      _applying = true;
      widget.controller.resize(widget.instance.id, w: start.w, h: start.h);
      _applying = false;
    }
  }

  void _clearDrag() {
    _removeGlobalRoute();
    _badgeEntry?.remove();
    _badgeEntry = null;
    _start = null;
    _mode = null;
    _pointerPosition = null;
    widget.controller.endLayoutOnly();
  }

  void _removeGlobalRoute() {
    if (_globalPointer != null) {
      GestureBinding.instance.pointerRouter
          .removeGlobalRoute(_handleGlobalPointer);
      _globalPointer = null;
    }
  }

  void _showBadge() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _badgeEntry = OverlayEntry(
      builder: (context) => _ResizeBadge(
        position: _pointerPosition ?? Offset.zero,
        width: widget.instance.w,
        height: widget.instance.h,
        rowHeight: widget.rowHeight,
      ),
    );
    overlay.insert(_badgeEntry!);
  }

  void _refreshBadge() {
    final entry = _badgeEntry;
    if (entry == null) return;
    entry.markNeedsBuild();
  }

  void _nudge(LogicalKeyboardKey key, bool lockWidth) {
    final instance = widget.instance;
    var w = instance.w;
    var h = instance.h;
    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        if (!lockWidth) w--;
        break;
      case LogicalKeyboardKey.arrowRight:
        if (!lockWidth) w++;
        break;
      case LogicalKeyboardKey.arrowUp:
        h--;
        break;
      case LogicalKeyboardKey.arrowDown:
        h++;
        break;
    }
    widget.controller.resize(instance.id, w: w, h: h);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final lockWidth = _lockWidth;
    if (event.logicalKey == LogicalKeyboardKey.escape && _start != null) {
      _cancelDrag();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _nudge(event.logicalKey, lockWidth);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columnWidth = widget.columnWidth ?? availableWidth / 12;
        final lockWidth = widget.forceLockWidth ?? availableWidth < 900;
        _lockWidth = lockWidth;
        return Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKeyEvent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_start != null)
                IgnorePointer(
                  child: CustomPaint(
                    key: const Key('resize-dashed-frame'),
                    painter: _DashedBorderPainter(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              if (!lockWidth)
                Positioned(
                  key: const Key('resize-right'),
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) =>
                          _startDrag(event, _ResizeMode.width, lockWidth),
                      onPointerMove: (event) => _updateDrag(event, columnWidth),
                      onPointerUp: _finishDrag,
                      onPointerCancel: (_) => _cancelDrag(),
                    ),
                  ),
                ),
              Positioned(
                key: const Key('resize-bottom'),
                left: 0,
                right: 0,
                bottom: 0,
                height: 8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeRow,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) =>
                        _startDrag(event, _ResizeMode.height, lockWidth),
                    onPointerMove: (event) => _updateDrag(event, columnWidth),
                    onPointerUp: _finishDrag,
                    onPointerCancel: (_) => _cancelDrag(),
                  ),
                ),
              ),
              Positioned(
                key: const Key('resize-corner'),
                right: 0,
                bottom: 0,
                width: 12,
                height: 12,
                child: MouseRegion(
                  cursor: lockWidth
                      ? SystemMouseCursors.resizeRow
                      : SystemMouseCursors.resizeDownRight,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) => _startDrag(
                      event,
                      lockWidth ? _ResizeMode.height : _ResizeMode.both,
                      lockWidth,
                    ),
                    onPointerMove: (event) => _updateDrag(event, columnWidth),
                    onPointerUp: _finishDrag,
                    onPointerCancel: (_) => _cancelDrag(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResizeBadge extends StatelessWidget {
  const _ResizeBadge({
    required this.position,
    required this.width,
    required this.height,
    required this.rowHeight,
  });

  final Offset position;
  final int width;
  final int height;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final percent = (width / 12 * 100).round();
    return Positioned(
      left: position.dx + 12,
      top: position.dy + 12,
      child: IgnorePointer(
        child: Material(
          key: const Key('resize-badge'),
          elevation: 6,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              '📐 宽: $width 列 ($percent%) · 高: ${(height * rowHeight).round()}px',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(8),
        ),
      );
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
              distance, math.min(distance + dash, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
