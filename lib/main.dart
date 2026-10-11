import 'dart:async';
import 'dart:io';

import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/desktop/desktop_providers.dart';
import 'package:dailydesk/core/desktop/system_tray_manager.dart';
import 'package:dailydesk/core/desktop/window_lifecycle.dart';
import 'package:dailydesk/core/theme/app_theme.dart';
import 'package:dailydesk/core/widgets/responsive_scaffold.dart';
import 'package:dailydesk/features/calendar/data/schedule_repository.dart';
import 'package:dailydesk/features/calendar/presentation/calendar_view.dart';
import 'package:dailydesk/features/copilot/presentation/ai_chat_view.dart';
import 'package:dailydesk/features/copilot/services/ai_service.dart';
import 'package:dailydesk/features/dashboard/builtin/builtin_widgets.dart';
import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/features/dashboard/dashboard_services.dart';
import 'package:dailydesk/features/dashboard/data/layout_repository.dart';
import 'package:dailydesk/features/dashboard/presentation/dashboard_view.dart';
import 'package:dailydesk/features/floating_dock/presentation/floating_dock_view.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';
import 'package:dailydesk/features/habits/presentation/habits_view.dart';
import 'package:dailydesk/features/memos/data/memo_repository.dart';
import 'package:dailydesk/features/memos/presentation/memos_view.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:dailydesk/features/pomodoro/presentation/pomodoro_view.dart';
import 'package:dailydesk/features/quick_capture/presentation/quick_capture_view.dart';
import 'package:dailydesk/features/quick_capture/quick_capture_service.dart';
import 'package:dailydesk/features/review/presentation/daily_review_view.dart';
import 'package:dailydesk/features/sop/services/sop_engine.dart';
import 'package:dailydesk/features/sync/presentation/sync_view.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/todos/presentation/todo_list_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (error) {
      debugPrint('Unable to enable the high refresh rate: $error');
    }
  }
  await WindowLifecycle.instance.ensureInitialized();

  final supportDirectory = await getApplicationSupportDirectory();
  final database = AppDatabase(
    NativeDatabase(
      File(path.join(supportDirectory.path, 'dailydesk.sqlite')),
    ),
  );
  final todoRepository = TodoRepository(database);
  final pomodoroRepository = PomodoroRepository(database);
  final habitRepository = HabitRepository(database);
  final memoRepository = MemoRepository(database);
  final scheduleRepository = ScheduleRepository(database);
  final layoutRepository = LayoutRepository(database);
  final dashboardController = await _createDashboardController(
    layoutRepository: layoutRepository,
  );
  final dashboardServices = DashboardServices(
    todoRepository: todoRepository,
    pomodoroRepository: pomodoroRepository,
    habitRepository: habitRepository,
    memoRepository: memoRepository,
    scheduleRepository: scheduleRepository,
  );

  runApp(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(todoRepository),
        pomodoroRepoProvider.overrideWithValue(pomodoroRepository),
        scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
      ],
      child: DailyDeskApp(
        home: DesktopShell(
          database: database,
          dashboardController: dashboardController,
          dashboardServices: dashboardServices,
          layoutRepository: layoutRepository,
        ),
      ),
    ),
  );
}

Future<DashboardController> _createDashboardController({
  required LayoutRepository layoutRepository,
}) async {
  final controller = DashboardController();
  registerBuiltInDashboardWidgets(controller.registry);
  final stored = await layoutRepository.loadLayout();
  if (stored != null && stored.pages.any((page) => page.widgets.isNotEmpty)) {
    controller.loadLayout(stored);
  } else {
    for (final definition in builtInDashboardDefinitions) {
      controller.add(definition.kind);
    }
    await layoutRepository.saveController(controller);
  }
  return controller;
}

class DailyDeskApp extends StatelessWidget {
  const DailyDeskApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: home ??
          const Scaffold(
            body: Center(
              child: Text('DailyDesk'),
            ),
          ),
    );
  }
}

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({
    super.key,
    required this.database,
    required this.dashboardController,
    required this.dashboardServices,
    this.layoutRepository,
  });

  final AppDatabase database;
  final DashboardController dashboardController;
  final DashboardServices dashboardServices;
  final LayoutRepository? layoutRepository;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  late final SystemTrayManager _trayManager;
  late final QuickCaptureService _quickCaptureService;
  Timer? _persistDebounce;

  bool _showQuickCapture = false;
  int _selectedNavIndex = 0;

  bool get _desktopSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    WindowLifecycle.instance.onCloseRequested = _handleCloseRequested;
    _trayManager = SystemTrayManager(onCommand: _handleTrayCommand);
    _quickCaptureService = QuickCaptureService(
      onTriggered: _openQuickCapture,
    );
    widget.dashboardController.addListener(_onDashboardChanged);
    unawaited(_initializeDesktopServices());
  }

  @override
  void dispose() {
    WindowLifecycle.instance.onCloseRequested = null;
    _persistDebounce?.cancel();
    widget.dashboardController.removeListener(_onDashboardChanged);
    unawaited(_quickCaptureService.dispose());
    unawaited(_trayManager.dispose());
    unawaited(widget.database.close());
    widget.dashboardController.dispose();
    super.dispose();
  }

  void _onDashboardChanged() {
    final repository = widget.layoutRepository;
    if (repository == null ||
        widget.dashboardController.lastChangeKind ==
            DashboardChangeKind.layout) {
      return;
    }
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(repository.saveController(widget.dashboardController));
    });
  }

  Future<void> _initializeDesktopServices() async {
    if (!_desktopSupported) {
      return;
    }

    try {
      await _trayManager.init();
    } catch (error) {
      debugPrint('System tray initialization failed: $error');
    }
    await _quickCaptureService.init();
  }

  void _handleTrayCommand(String key) {
    switch (key) {
      case 'open':
        unawaited(_restoreWorkbench());
      case 'pomodoro':
        setState(() => _selectedNavIndex = _indexForDestination('pomodoro'));
        unawaited(_restoreWorkbench());
      case 'sync':
        setState(() => _selectedNavIndex = _indexForDestination('sync'));
        unawaited(_restoreWorkbench());
      case 'quit':
        if (_desktopSupported) {
          unawaited(windowManager.destroy());
        }
    }
  }

  int _indexForDestination(String key) {
    final index = kDefaultDestinations.indexWhere((item) => item.key == key);
    return index == -1 ? 0 : index;
  }

  void _handleCloseRequested() {
    final action = decideCloseAction(
      closeToTrayEnabled: ref.read(closeToTrayProvider),
    );
    if (action == CloseAction.hideToTray) {
      unawaited(WindowLifecycle.instance.hideToTray());
    } else {
      unawaited(windowManager.destroy());
    }
  }

  void _openQuickCapture() {
    if (!mounted) {
      return;
    }
    setState(() => _showQuickCapture = true);
    unawaited(_prepareQuickCaptureWindow());
  }

  Future<void> _prepareQuickCaptureWindow() async {
    if (!_desktopSupported) {
      return;
    }

    try {
      // Keep the workbench window geometry intact and present Quick Capture
      // as an in-window modal overlay so the workspace never collapses.
      await windowManager.setAlwaysOnTop(true);
      await WindowLifecycle.instance.restoreAndFocus();
    } catch (error) {
      debugPrint('Unable to prepare quick capture window: $error');
    }
  }

  Future<void> _hideQuickCapture() async {
    if (mounted) {
      setState(() => _showQuickCapture = false);
    }
    if (!_desktopSupported) {
      return;
    }

    try {
      await windowManager.setAlwaysOnTop(false);
    } catch (error) {
      debugPrint('Unable to hide quick capture window: $error');
    }
  }

  Future<void> _restoreWorkbench() async {
    if (mounted) {
      setState(() => _showQuickCapture = false);
    }
    if (!_desktopSupported) {
      return;
    }

    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setResizable(true);
      await windowManager.setMinimumSize(const Size(960, 640));
      await WindowLifecycle.instance.restoreAndFocus();
    } catch (error) {
      debugPrint('Unable to restore workbench window: $error');
    }
  }

  Future<void> _applyAiDeconstruction(Deconstruction deconstruction) async {
    final todos = widget.dashboardServices.todoRepository;
    final memos = widget.dashboardServices.memoRepository;
    if (todos != null) {
      for (final item in deconstruction.todos) {
        await todos.insertTodo(
          title: item.title,
          priority: item.priority,
          dueTime: item.dueTime,
          estimatedPomodoros: item.estimatedPomodoros,
        );
      }
    }
    if (memos != null) {
      for (final memo in deconstruction.memos) {
        await memos.insertMemo(content: memo.content, tag: memo.tag);
      }
    }
    if (deconstruction.sops.isNotEmpty) {
      for (final instance in widget.dashboardController.pageWidgets) {
        if (instance.kind == 'sop_daily') {
          final rawSlots = instance.config['slots'];
          var current = rawSlots is List
              ? rawSlots
                  .whereType<Map>()
                  .map((e) => SopSlot.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : <SopSlot>[];
          for (final sop in deconstruction.sops) {
            current = SopEngine.insertAdHoc(
              current,
              SopSlot(title: sop.title, time: sop.time, checkpoints: const []),
            );
          }
          widget.dashboardController.updateConfig(instance.id, {
            'slots': current.map((s) => s.toJson()).toList(),
          });
        }
      }
    }
  }

  Widget _buildActiveDestination() {
    final destination = kDefaultDestinations[
        _selectedNavIndex.clamp(0, kDefaultDestinations.length - 1)];
    final services = widget.dashboardServices;
    return switch (destination.key) {
      'dashboard' => DashboardView(
          controller: widget.dashboardController,
          services: services,
        ),
      'todos' => TodoListView(
          onFocusRequested: (todo) {
            final pomodoro = services.pomodoroRepository;
            if (pomodoro != null) {
              unawaited(pomodoro.startSession(todoId: todo.id));
            }
            setState(
              () => _selectedNavIndex = _indexForDestination('pomodoro'),
            );
          },
        ),
      'calendar' => StreamBuilder(
          stream: services.todoRepository?.watchTodos(),
          builder: (context, snapshot) => CalendarView(
            repository: services.scheduleRepository,
            todos: snapshot.data ?? const [],
          ),
        ),
      'memos' => services.memoRepository == null
          ? const SizedBox.shrink()
          : MemosView(repository: services.memoRepository!),
      'habits' => services.habitRepository == null
          ? const SizedBox.shrink()
          : HabitsView(repository: services.habitRepository!),
      'pomodoro' => services.pomodoroRepository == null
          ? const SizedBox.shrink()
          : PomodoroView(
              repository: services.pomodoroRepository!,
              todoRepository: services.todoRepository,
            ),
      'review' => DailyReviewView(database: widget.database),
      'copilot' => AiChatView(onApply: _applyAiDeconstruction),
      'sync' => SyncView(database: widget.database, embedded: true),
      _ => DashboardView(
          controller: widget.dashboardController,
          services: services,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeBody = _buildActiveDestination();
    return Stack(
      children: [
        _WorkbenchShell(
          key: const ValueKey('workbench'),
          onOpenWorkbench: () => unawaited(_restoreWorkbench()),
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedNavIndex = index),
          body: activeBody,
        ),
        if (_showQuickCapture)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black38,
              child: Padding(
                padding: const EdgeInsets.only(top: 96),
                child: QuickCaptureView(
                  key: const ValueKey('quick-capture'),
                  onDismiss: () => unawaited(_hideQuickCapture()),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkbenchShell extends StatelessWidget {
  const _WorkbenchShell({
    super.key,
    required this.onOpenWorkbench,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  final VoidCallback onOpenWorkbench;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _DesktopTitleBar(),
          Expanded(
            child: Stack(
              children: [
                ResponsiveScaffold(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  desktopBody: body,
                  mobileBody: body,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FloatingDockView(
                    onOpenWorkbench: onOpenWorkbench,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTitleBar extends StatelessWidget {
  const _DesktopTitleBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => unawaited(windowManager.startDragging()),
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'DailyDesk',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: '最小化',
                visualDensity: VisualDensity.compact,
                onPressed: windowManager.minimize,
                icon: const Icon(Icons.remove_rounded, size: 18),
              ),
              IconButton(
                tooltip: '关闭',
                visualDensity: VisualDensity.compact,
                onPressed: windowManager.close,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
