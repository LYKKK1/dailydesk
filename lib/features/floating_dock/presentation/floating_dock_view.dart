import 'dart:async';
import 'dart:io';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/desktop/desktop_providers.dart';
import 'package:dailydesk/core/desktop/window_lifecycle.dart';
import 'package:dailydesk/core/theme/app_colors.dart';
import 'package:dailydesk/features/floating_dock/floating_dock_controller.dart';
import 'package:dailydesk/features/todos/presentation/todo_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class FloatingDockView extends ConsumerStatefulWidget {
  const FloatingDockView({
    super.key,
    this.onOpenWorkbench,
  });

  final VoidCallback? onOpenWorkbench;

  @override
  ConsumerState<FloatingDockView> createState() => _FloatingDockViewState();
}

class _FloatingDockViewState extends ConsumerState<FloatingDockView> {
  final FloatingDockController _controller = FloatingDockController();

  Timer? _hoverTimer;
  Timer? _ticker;
  Stopwatch? _hoverStopwatch;
  DockState _state = DockState.collapsed;
  bool _hovered = false;

  bool _paused = false;
  DateTime? _pauseStartedAt;
  Duration _pausedDuration = Duration.zero;
  Duration _pausedRemaining = Duration.zero;
  String? _lastSessionId;

  Offset? _dragStartWindowPosition;
  Offset _dragDelta = Offset.zero;
  String _edge = 'right';
  double _offset = 0.32;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _lastSessionId != null) {
        setState(() {});
      }
      unawaited(ref.read(pomodoroRepoProvider).reconcileActiveSession());
    });
    unawaited(ref.read(pomodoroRepoProvider).reconcileActiveSession());
    unawaited(_restorePosition());
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _restorePosition() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) {
        return;
      }
      setState(() {
        _edge = preferences.getString('dock_edge') ?? 'right';
        _offset = preferences.getDouble('dock_offset') ?? 0.32;
      });
    } catch (error) {
      debugPrint('Unable to restore dock position: $error');
    }
  }

  bool get _desktopSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  void _onEnter(PointerEnterEvent event) {
    _hovered = true;
    _hoverStopwatch = Stopwatch()..start();
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 160), () {
      if (!mounted || !_hovered) {
        return;
      }
      setState(() {
        _state = _controller.decide(
          hovered: true,
          hoverDuration: _hoverStopwatch!.elapsed,
        );
      });
    });
  }

  void _onExit(PointerExitEvent event) {
    _hovered = false;
    _hoverStopwatch = Stopwatch()..start();
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 410), () {
      if (!mounted || _hovered) {
        return;
      }
      setState(() {
        _state = _controller.decide(
          hovered: false,
          hoverDuration: _hoverStopwatch!.elapsed,
        );
      });
    });
  }

  void _syncSession(PomodoroLog? session) {
    if (_lastSessionId == session?.id) {
      return;
    }
    _lastSessionId = session?.id;
    _paused = false;
    _pauseStartedAt = null;
    _pausedDuration = Duration.zero;
    _pausedRemaining = Duration.zero;
  }

  Duration _remainingFor(PomodoroLog? session) {
    if (session == null) {
      return const Duration(minutes: 25);
    }
    if (_paused) {
      return _pausedRemaining;
    }

    final now = DateTime.now();
    final startedAt = DateTime.fromMillisecondsSinceEpoch(session.startedAt);
    var elapsed = now.difference(startedAt) - _pausedDuration;
    if (_pauseStartedAt != null) {
      elapsed -= now.difference(_pauseStartedAt!);
    }
    final remaining = Duration(minutes: session.durationMinutes) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 99 * 60 * 60);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleSession(PomodoroLog? session) async {
    final repository = ref.read(pomodoroRepoProvider);
    try {
      if (session == null) {
        await repository.startSession();
        await repository.reconcileActiveSession();
        if (mounted) {
          setState(() {
            _paused = false;
            _pauseStartedAt = null;
            _pausedDuration = Duration.zero;
          });
        }
        return;
      }

      setState(() {
        if (_paused) {
          if (_pauseStartedAt != null) {
            _pausedDuration += DateTime.now().difference(_pauseStartedAt!);
          }
          _paused = false;
          _pauseStartedAt = null;
        } else {
          _pausedRemaining = _remainingFor(session);
          _paused = true;
          _pauseStartedAt = DateTime.now();
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('番茄钟操作失败：$error')),
        );
      }
    }
  }

  Future<void> _completeTodo(Todo todo) async {
    try {
      await ref
          .read(todoRepositoryProvider)
          .updateTodo(todo.copyWith(status: 'completed'));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新待办失败：$error')),
        );
      }
    }
  }

  void _openWorkbench() {
    final callback = widget.onOpenWorkbench;
    if (callback != null) {
      callback();
    } else {
      unawaited(WindowLifecycle.instance.restoreAndFocus());
    }
  }

  Future<void> _startDrag(DragStartDetails details) async {
    if (!_desktopSupported) {
      return;
    }
    try {
      _dragStartWindowPosition = await windowManager.getPosition();
      _dragDelta = Offset.zero;
    } catch (error) {
      debugPrint('Unable to start dock drag: $error');
    }
  }

  void _updateDrag(DragUpdateDetails details) {
    final start = _dragStartWindowPosition;
    if (!_desktopSupported || start == null) {
      return;
    }
    _dragDelta += details.delta;
    unawaited(windowManager.setPosition(start + _dragDelta));
  }

  Future<void> _finishDrag(DragEndDetails details) async {
    if (!_desktopSupported || _dragStartWindowPosition == null) {
      return;
    }

    try {
      final position = await windowManager.getPosition();
      final windowSize = await windowManager.getSize();
      final display = await screenRetriever.getPrimaryDisplay();
      final workArea = display.visiblePosition ?? const Offset(0, 0);
      final workSize = display.visibleSize ?? display.size;
      final left = workArea.dx;
      final top = workArea.dy;
      final right = left + workSize.width;
      final bottom = top + workSize.height;
      final centeredOnLeft =
          position.dx + windowSize.width / 2 < left + workSize.width / 2;
      final edge = centeredOnLeft ? 'left' : 'right';
      final y = position.dy.clamp(
        top,
        (bottom - windowSize.height).clamp(top, double.infinity),
      );
      final x =
          centeredOnLeft ? left : (right - windowSize.width).clamp(left, right);
      final snapped = Offset(x.toDouble(), y.toDouble());
      await windowManager.setPosition(snapped);

      final availableHeight = workSize.height - windowSize.height;
      final offsetFraction = availableHeight <= 0
          ? 0.5
          : ((snapped.dy - top) / availableHeight).clamp(0.0, 1.0);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('dock_edge', edge);
      await preferences.setDouble('dock_offset', offsetFraction);
      if (mounted) {
        setState(() {
          _edge = edge;
          _offset = offsetFraction;
        });
      }
    } catch (error) {
      debugPrint('Unable to snap dock to edge: $error');
    } finally {
      _dragStartWindowPosition = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _state == DockState.expanded;
    final radius = BorderRadius.horizontal(
      left: Radius.circular(_edge == 'right' ? 16 : 0),
      right: Radius.circular(_edge == 'left' ? 16 : 0),
    );

    return Align(
      alignment: Alignment(
        _edge == 'right' ? 1 : -1,
        (_offset.clamp(0.0, 1.0) * 2) - 1,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: _onEnter,
        onExit: _onExit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: expanded ? 280 : 4,
          height: expanded ? 420 : 120,
          padding: expanded ? const EdgeInsets.all(14) : EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.72),
            ),
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(-6, 0),
              ),
            ],
          ),
          child: expanded
              ? _buildExpandedContent()
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => unawaited(_startDrag(details)),
                  onPanUpdate: _updateDrag,
                  onPanEnd: (details) => unawaited(_finishDrag(details)),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<PomodoroLog?>(
          stream: ref.watch(pomodoroRepoProvider).watchActiveSession(),
          builder: (context, snapshot) {
            final session = snapshot.data;
            _syncSession(session);
            return Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDuration(_remainingFor(session)),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: session == null ? '开始番茄钟' : (_paused ? '继续' : '暂停'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => unawaited(_toggleSession(session)),
                  icon: Icon(
                    session == null
                        ? Icons.play_arrow_rounded
                        : (_paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded),
                  ),
                ),
              ],
            );
          },
        ),
        const Divider(height: 16),
        Text(
          '今日 Top 3',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Expanded(
          child: StreamBuilder<List<Todo>>(
            stream: ref.watch(todoRepositoryProvider).watchTodayTodos(),
            builder: (context, snapshot) {
              final todos = snapshot.data?.take(3).toList() ?? const <Todo>[];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (todos.isEmpty) {
                return Center(
                  child: Text(
                    '暂无今日待办',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: todos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.priorityColor(todo.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          todo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Checkbox(
                        value: todo.status == 'completed',
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) => unawaited(_completeTodo(todo)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 12),
        TextButton.icon(
          onPressed: _openWorkbench,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('打开主工作台'),
        ),
      ],
    );
  }
}
