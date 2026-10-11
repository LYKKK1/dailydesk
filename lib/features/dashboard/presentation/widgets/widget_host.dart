import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/features/dashboard/presentation/widgets/resize_handles.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:flutter/material.dart';

class WidgetHost extends StatefulWidget {
  const WidgetHost({
    super.key,
    required this.instance,
    required this.registry,
    required this.editMode,
    this.controller,
    this.rowHeight = 56,
    this.columnWidth,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.dragHandleBuilder,
  });

  final WidgetInstance instance;
  final WidgetRegistry registry;
  final bool editMode;
  final DashboardController? controller;
  final double rowHeight;
  final double? columnWidth;
  final VoidCallback? onDragStarted;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final Widget Function(BuildContext context, Widget child)? dragHandleBuilder;

  @override
  State<WidgetHost> createState() => _WidgetHostState();
}

class _WidgetHostState extends State<WidgetHost> {
  DailyWidgetDefinition<dynamic>? _definition;
  WidgetContext<dynamic>? _liveContext;
  DashboardController? _fallbackController;

  @override
  void initState() {
    super.initState();
    _bindDefinition();
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant WidgetHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);
    }
    if (oldWidget.instance != widget.instance ||
        oldWidget.registry != widget.registry ||
        oldWidget.instance.kind != widget.instance.kind) {
      _disposeLiveContext();
      _bindDefinition();
    } else {
      _refreshParsedConfig();
    }
  }

  void _bindDefinition() {
    _definition = widget.registry.definitionOf(widget.instance.kind);
    final definition = _definition;
    if (definition == null) return;
    final rawConfig = Map<String, dynamic>.of(widget.instance.config);
    final normalized = definition.normalizeConfig(rawConfig);
    if (normalized is Map<String, dynamic>) {
      _liveContext = LiveWidgetContext<Map<String, dynamic>>(
        isMounted: () => mounted,
        instance: widget.instance,
        onConfigSaved: _saveConfig,
        onRerender: () {
          if (mounted) setState(() {});
        },
      )..parsedConfig = normalized;
    } else {
      _liveContext = LiveWidgetContext<dynamic>(
        isMounted: () => mounted,
        instance: widget.instance,
        onConfigSaved: _saveConfig,
        onRerender: () {
          if (mounted) setState(() {});
        },
      )..parsedConfig = normalized;
    }
  }

  void _refreshParsedConfig() {
    final context = _liveContext;
    final definition = _definition;
    if (context == null || definition == null) return;
    final normalized = definition.normalizeConfig(
      Map<String, dynamic>.of(widget.instance.config),
    );
    if (context is LiveWidgetContext<Map<String, dynamic>> &&
        normalized is Map<String, dynamic>) {
      context.parsedConfig = normalized;
    } else if (context is LiveWidgetContext<dynamic>) {
      context.parsedConfig = normalized;
    }
  }

  Future<void> _saveConfig(Map<String, dynamic> patch) async {
    widget.instance.config = {
      ...widget.instance.config,
      ...patch,
    };
    widget.controller?.updateConfig(widget.instance.id, patch);
    if (mounted) {
      setState(_refreshParsedConfig);
    }
  }

  void _handleControllerChanged() {
    final controller = widget.controller;
    if (controller == null || !mounted) return;
    final exists = controller.pageWidgets
        .any((instance) => instance.id == widget.instance.id);
    if (!exists) {
      setState(() {});
      return;
    }
    setState(_refreshParsedConfig);
  }

  void _disposeLiveContext() {
    final context = _liveContext;
    if (context is LiveWidgetContext<dynamic>) context.dispose();
    _liveContext = null;
    _definition = null;
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    _fallbackController?.dispose();
    _disposeLiveContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definition = _definition;
    final content = definition == null
        ? _PlaceholderWidget(instance: widget.instance)
        : Builder(
            builder: (context) => definition.render(context, _liveContext!),
          );

    return AnimatedContainer(
      duration: widget.controller?.layoutOnly == true
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: content,
          ),
          if (widget.editMode) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 36,
              child: _EditHeader(
                instance: widget.instance,
                controller: widget.controller,
                onDragStarted: widget.onDragStarted,
                onDragUpdate: widget.onDragUpdate,
                onDragEnd: widget.onDragEnd,
                dragHandleBuilder: widget.dragHandleBuilder,
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: _EditActions(
                instance: widget.instance,
                controller: widget.controller,
              ),
            ),
            ResizeHandles(
              instance: widget.instance,
              controller: widget.controller ??
                  (_fallbackController ??= DashboardController()
                    ..load([widget.instance])),
              rowHeight: widget.rowHeight,
              columnWidth: widget.columnWidth,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderWidget extends StatelessWidget {
  const _PlaceholderWidget({required this.instance});

  final WidgetInstance instance;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('placeholder-widget'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.extension_off_outlined, size: 32),
          const SizedBox(height: 8),
          Text('组件 ${instance.kind} 未安装'),
          const SizedBox(height: 4),
          Text(
            '配置已保留，安装扩展后即可恢复',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.instance,
    required this.controller,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.dragHandleBuilder,
  });

  final WidgetInstance instance;
  final DashboardController? controller;
  final VoidCallback? onDragStarted;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final Widget Function(BuildContext context, Widget child)? dragHandleBuilder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            key: Key('cycle-width-${instance.id}'),
            tooltip: '循环列宽',
            visualDensity: VisualDensity.compact,
            onPressed: controller?.cycleSelectedWidth,
            icon: const Icon(Icons.width_full, size: 18),
          ),
          _buildGrip(context),
        ],
      ),
    );
  }

  Widget _buildGrip(BuildContext context) {
    final grip = Listener(
      key: Key('widget-grip-${instance.id}'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onDragStarted?.call(),
      onPointerMove: (event) =>
          onDragUpdate?.call(event.position - event.localPosition),
      onPointerUp: (_) => onDragEnd?.call(),
      onPointerCancel: (_) => onDragEnd?.call(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Text('⋮⋮', style: TextStyle(fontSize: 18)),
      ),
    );
    return dragHandleBuilder?.call(context, grip) ?? grip;
  }
}

class _EditActions extends StatelessWidget {
  const _EditActions({
    required this.instance,
    required this.controller,
  });

  final WidgetInstance instance;
  final DashboardController? controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: Key('move-forward-${instance.id}'),
            tooltip: '前移',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller?.moveForward(instance.id),
            icon: const Icon(Icons.arrow_back, size: 17),
          ),
          IconButton(
            key: Key('move-backward-${instance.id}'),
            tooltip: '后移',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller?.moveBackward(instance.id),
            icon: const Icon(Icons.arrow_forward, size: 17),
          ),
          IconButton(
            key: Key('duplicate-${instance.id}'),
            tooltip: '复制',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller?.duplicate(instance.id),
            icon: const Icon(Icons.copy_outlined, size: 17),
          ),
          IconButton(
            key: Key('delete-${instance.id}'),
            tooltip: '删除',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller?.remove(instance.id),
            icon: const Icon(Icons.close, size: 17),
          ),
        ],
      ),
    );
  }
}
