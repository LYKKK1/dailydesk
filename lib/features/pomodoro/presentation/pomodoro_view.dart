import 'dart:async';
import 'dart:math' as math;

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:dailydesk/features/pomodoro/services/pomodoro_foreground_service.dart';
import 'package:dailydesk/features/pomodoro/services/white_noise_service.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:flutter/material.dart';

enum CycleKind { focus, shortBreak, longBreak }

class PomodoroCycle {
  const PomodoroCycle._();

  /// Returns the break reached after the supplied completed focus rounds.
  static ({CycleKind kind, int minutes}) pomodoroStep(int completedRounds) {
    final breakInfo = PomodoroRepository.breakForCompletedRound(
      completedRounds + 1,
    );
    return (
      kind: breakInfo.mode == PomodoroRepository.longBreakMode
          ? CycleKind.longBreak
          : CycleKind.shortBreak,
      minutes: breakInfo.minutes,
    );
  }

  /// Displays the current 1-based round followed by the remaining rounds.
  static String roundDots({required int completedRounds, required int total}) {
    if (total <= 0) {
      return '';
    }
    final safeCompleted = completedRounds.clamp(0, total - 1);
    final doneCount = math.min(total, safeCompleted + 1);
    final done = List.filled(doneCount, '🍅').join(' ');
    final todo = List.filled(total - doneCount, '⚪').join(' ');
    return [done, todo].where((part) => part.isNotEmpty).join(' ');
  }
}

enum PomodoroMode {
  classic('经典 25/5/15'),
  flowtime('正向心流'),
  countdown('倒计时');

  const PomodoroMode(this.label);

  final String label;

  String get repositoryValue => switch (this) {
        PomodoroMode.classic => 'pomodoro',
        PomodoroMode.flowtime => 'flowtime',
        PomodoroMode.countdown => 'countdown',
      };
}

class PomodoroView extends StatefulWidget {
  const PomodoroView({
    super.key,
    required this.repository,
    this.todoRepository,
    this.foregroundService,
  });

  final PomodoroRepository repository;
  final TodoRepository? todoRepository;
  final PomodoroForegroundService? foregroundService;

  @override
  State<PomodoroView> createState() => _PomodoroViewState();
}

class _PomodoroViewState extends State<PomodoroView> {
  static const _countdownChoices = [15, 30, 45, 60];

  Timer? _ticker;
  Stream<List<Todo>>? _todoStream;

  PomodoroMode _mode = PomodoroMode.classic;
  int _countdownMinutes = 30;
  int _cycleRound = 0;
  bool _busy = false;
  bool _reconciling = false;
  String? _selectedTodoId;
  String? _foregroundSessionId;
  late final PomodoroForegroundService _foregroundService;

  final _noiseEnabled = <String, bool>{
    for (final key in WhiteNoiseService.tracks.keys) key: false,
  };
  final _noiseVolumes = <String, double>{
    for (final key in WhiteNoiseService.tracks.keys) key: 0.6,
  };

  @override
  void initState() {
    super.initState();
    _foregroundService =
        widget.foregroundService ?? PomodoroForegroundService();
    _todoStream = widget.todoRepository?.watchTodos();
    unawaited(_reconcileAndSyncForegroundService());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        unawaited(_reconcileAndSyncForegroundService());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(WhiteNoiseService.instance.stopAll());
    super.dispose();
  }

  int get _selectedMinutes =>
      _mode == PomodoroMode.countdown ? _countdownMinutes : 25;

  Future<void> _start() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.startSession(
        todoId: _selectedTodoId,
        mode: _mode.repositoryValue,
        plannedMinutes: _mode == PomodoroMode.flowtime ? 0 : _selectedMinutes,
      );
      final session = await widget.repository.reconcileActiveSession();
      if (session != null) {
        await _startForegroundService(session, showError: true);
      }
      if (mounted) {
        final cycleRound = await widget.repository.currentCycleRound();
        setState(() {
          _cycleRound = cycleRound;
        });
      }
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finish(PomodoroLog session) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final elapsedMinutes = math.max(
        1,
        DateTime.now()
            .difference(
              DateTime.fromMillisecondsSinceEpoch(session.startedAt),
            )
            .inMinutes,
      );
      final actualMinutes = session.mode == 'flowtime'
          ? elapsedMinutes
          : math.max(1, session.durationMinutes);
      final nextSession = await widget.repository.finishSession(
        session.id,
        actualMinutes: actualMinutes,
      );
      await _stopForegroundService();
      if (nextSession != null) {
        await _startForegroundService(nextSession, showError: true);
      }
      if (mounted) {
        final cycleRound = await widget.repository.currentCycleRound();
        setState(() {
          _cycleRound = cycleRound;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancel(PomodoroLog session) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.cancelSession(session.id);
      await _stopForegroundService();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reconcileAndSyncForegroundService() async {
    if (_reconciling) {
      return;
    }
    _reconciling = true;
    try {
      final session = await widget.repository.reconcileActiveSession();
      final cycleRound = await widget.repository.currentCycleRound();
      if (mounted) {
        setState(() => _cycleRound = cycleRound);
      }
      if (session == null) {
        if (_foregroundSessionId != null) {
          await _stopForegroundService();
        }
        return;
      }
      if (_foregroundSessionId != session.id) {
        if (_foregroundSessionId != null) {
          await _stopForegroundService();
        }
        await _startForegroundService(session);
      }
    } catch (error) {
      debugPrint('Unable to reconcile Pomodoro session: $error');
    } finally {
      _reconciling = false;
    }
  }

  Future<void> _startForegroundService(
    PomodoroLog session, {
    bool showError = false,
  }) async {
    try {
      await _foregroundService.start(
        startedAt: DateTime.fromMillisecondsSinceEpoch(session.startedAt),
        plannedMinutes: session.durationMinutes,
        mode: session.mode,
      );
      _foregroundSessionId = session.id;
    } catch (error) {
      // The persisted session remains valid if Android notification/service
      // startup is unavailable (for example, notification permission denied).
      if (showError && mounted) {
        _showMessage(error.toString());
      }
      debugPrint('Unable to start Pomodoro foreground service: $error');
    }
  }

  Future<void> _stopForegroundService() async {
    try {
      await _foregroundService.stop();
    } catch (error) {
      debugPrint('Unable to stop Pomodoro foreground service: $error');
    } finally {
      _foregroundSessionId = null;
    }
  }

  Future<void> _toggleNoise(String key) async {
    final next = !(_noiseEnabled[key] ?? false);
    try {
      await WhiteNoiseService.instance.toggle(
        key,
        volume: _noiseVolumes[key] ?? 0.6,
      );
      if (mounted) {
        setState(() => _noiseEnabled[key] = next);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _noiseEnabled[key] = false);
      }
      _showMessage('音频资源不可用');
    }
  }

  Future<void> _changeNoiseVolume(String key, double volume) async {
    setState(() => _noiseVolumes[key] = volume);
    try {
      await WhiteNoiseService.instance.setVolume(key, volume);
    } catch (_) {
      if (mounted) {
        _showMessage('无法调整音量');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '专注番茄钟',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '把注意力留给此刻最重要的一件事',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _openZenMode(context),
                    icon: const Icon(Icons.fullscreen),
                    label: const Text('禅模式'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                PomodoroCycle.roundDots(
                  completedRounds: _cycleRound,
                  total: 4,
                ),
                key: const Key('pomodoro-round-dots'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              SegmentedButton<PomodoroMode>(
                segments: [
                  for (final mode in PomodoroMode.values)
                    ButtonSegment(
                      value: mode,
                      label: Text(mode.label),
                    ),
                ],
                selected: {_mode},
                onSelectionChanged: _busy
                    ? null
                    : (selection) {
                        setState(() => _mode = selection.first);
                      },
              ),
              if (_mode == PomodoroMode.countdown) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final minutes in _countdownChoices)
                      ChoiceChip(
                        label: Text('$minutes 分钟'),
                        selected: _countdownMinutes == minutes,
                        onSelected: (_) {
                          setState(() => _countdownMinutes = minutes);
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: StreamBuilder<PomodoroLog?>(
                    stream: widget.repository.watchActiveSession(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('无法读取专注状态：${snapshot.error}'),
                        );
                      }
                      final session = snapshot.data;
                      return Column(
                        children: [
                          _buildTimerPanel(context, session),
                          const SizedBox(height: 16),
                          _buildTodoSelector(),
                          const SizedBox(height: 18),
                          _buildAmbience(context),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerPanel(BuildContext context, PomodoroLog? session) {
    final elapsed = session == null
        ? Duration.zero
        : DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(session.startedAt),
          );
    final planned = Duration(
      minutes: session?.durationMinutes ?? _selectedMinutes,
    );
    final isFlowtime = session?.mode == 'flowtime';
    final isBreak = session?.mode == PomodoroRepository.shortBreakMode ||
        session?.mode == PomodoroRepository.longBreakMode;
    final remaining = isFlowtime
        ? Duration.zero
        : planned - elapsed < Duration.zero
            ? Duration.zero
            : planned - elapsed;
    final progress = session == null
        ? 0.0
        : isFlowtime
            ? (elapsed.inSeconds % 60) / 60
            : planned.inMilliseconds == 0
                ? 1.0
                : (elapsed.inMilliseconds / planned.inMilliseconds)
                    .clamp(0.0, 1.0)
                    .toDouble();
    final display = isFlowtime ? elapsed : remaining;

    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _TimerRingPainter(
                  progress: progress,
                  trackColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  progressColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(display),
                      key: const Key('pomodoro-time'),
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session == null
                          ? '准备开始'
                          : isFlowtime
                              ? '正向心流'
                              : isBreak
                                  ? session.mode ==
                                          PomodoroRepository.longBreakMode
                                      ? '长休'
                                      : '短休'
                                  : '保持专注',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            if (session == null)
              FilledButton.icon(
                key: const Key('pomodoro-start'),
                onPressed: _busy ? null : _start,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始专注'),
              )
            else ...[
              FilledButton.icon(
                onPressed: _busy ? null : () => _finish(session),
                icon: const Icon(Icons.check),
                label: const Text('完成本轮'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _cancel(session),
                icon: const Icon(Icons.stop),
                label: const Text('放弃'),
              ),
            ],
          ],
        ),
        if (session == null) ...[
          const SizedBox(height: 8),
          Text(
            '下一阶段：${_nextBreakLabel()}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildTodoSelector() {
    final stream = _todoStream;
    if (stream == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<Todo>>(
      stream: stream,
      builder: (context, snapshot) {
        final todos = (snapshot.data ?? const <Todo>[])
            .where((todo) => todo.status != 'completed')
            .toList(growable: false);
        final hasSelected = todos.any((todo) => todo.id == _selectedTodoId);
        return Row(
          children: [
            const Icon(Icons.link, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: const Key('pomodoro-todo-selector'),
                value: hasSelected ? _selectedTodoId : null,
                decoration: const InputDecoration(
                  labelText: '关联待办',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('不关联待办'),
                  ),
                  for (final todo in todos)
                    DropdownMenuItem<String?>(
                      value: todo.id,
                      child: Text(
                        todo.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _selectedTodoId = value),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmbience(BuildContext context) {
    final anyPlaying = _noiseEnabled.values.any((playing) => playing);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '白噪音混音',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _WaveBars(active: anyPlaying),
              ],
            ),
            const SizedBox(height: 8),
            for (final entry in WhiteNoiseService.tracks.entries)
              _NoiseTrackRow(
                key: ValueKey('noise-${entry.key}'),
                trackKey: entry.key,
                label: entry.value,
                enabled: _noiseEnabled[entry.key] ?? false,
                volume: _noiseVolumes[entry.key] ?? 0.6,
                onToggle: () => unawaited(_toggleNoise(entry.key)),
                onVolumeChanged: (value) =>
                    unawaited(_changeNoiseVolume(entry.key, value)),
              ),
          ],
        ),
      ),
    );
  }

  String _nextBreakLabel() {
    final next = PomodoroCycle.pomodoroStep(_cycleRound);
    return next.kind == CycleKind.longBreak
        ? '长休 ${next.minutes} 分钟'
        : '短休 ${next.minutes} 分钟';
  }

  Future<void> _openZenMode(BuildContext context) async {
    final session = await widget.repository.reconcileActiveSession();
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ZenMode(
          startedAt: session == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(session.startedAt),
          plannedMinutes: session?.durationMinutes ?? _selectedMinutes,
          flowtime: session?.mode == 'flowtime',
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

class _NoiseTrackRow extends StatelessWidget {
  const _NoiseTrackRow({
    super.key,
    required this.trackKey,
    required this.label,
    required this.enabled,
    required this.volume,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  final String trackKey;
  final String label;
  final bool enabled;
  final double volume;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 132,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        IconButton(
          key: ValueKey('noise-toggle-$trackKey'),
          tooltip: enabled ? '关闭$label' : '播放$label',
          onPressed: onToggle,
          icon: Icon(
            enabled ? Icons.pause_circle : Icons.play_circle_outline,
          ),
        ),
        Expanded(
          child: Slider(
            value: volume,
            onChanged: onVolumeChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(volume * 100).round()}',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _WaveBars extends StatefulWidget {
  const _WaveBars({required this.active});

  final bool active;

  @override
  State<_WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<_WaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _WaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) {
      return;
    }
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: widget.active ? 1 : 0.25,
      child: SizedBox(
        width: 44,
        height: 24,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < 4; index++) ...[
                  Container(
                    width: 6,
                    height: widget.active
                        ? 8.0 +
                            16.0 *
                                (0.5 +
                                    0.5 *
                                        math.sin(
                                          (_controller.value * math.pi * 2) +
                                              index,
                                        ))
                        : 8.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  if (index != 3) const SizedBox(width: 4),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ZenMode extends StatefulWidget {
  const _ZenMode({
    required this.startedAt,
    required this.plannedMinutes,
    required this.flowtime,
  });

  final DateTime? startedAt;
  final int plannedMinutes;
  final bool flowtime;

  @override
  State<_ZenMode> createState() => _ZenModeState();
}

class _ZenModeState extends State<_ZenMode> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = widget.startedAt;
    final elapsed = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
    final planned = Duration(minutes: widget.plannedMinutes);
    final remaining =
        planned - elapsed < Duration.zero ? Duration.zero : planned - elapsed;
    final display = widget.flowtime
        ? elapsed
        : startedAt == null
            ? planned
            : remaining;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatDuration(display),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton.filledTonal(
                tooltip: '退出禅模式',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final totalSeconds = math.max(0, value.inSeconds);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
