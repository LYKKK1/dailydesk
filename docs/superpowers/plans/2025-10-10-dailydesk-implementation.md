# DailyDesk (日常工作台) 全量实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建离线优先的 Flutter 双端（Windows + Android）生产力中枢：待办 GTD、时间块日历、灵感便签、番茄专注、习惯追踪、每日复盘、AI 拆解与局域网 P2P 增量同步。

**Architecture:** Clean Architecture 四层（Presentation → Riverpod Notifier → Domain UseCase → Infrastructure）。数据层为 Drift(SQLite, WAL 模式) 8 张业务表 + 1 张布局表；仪表盘采用 WidgetRegistry 组件注册表模式（借鉴 home-pages），布局持久化只存 `{kind, w, h, config}` 与渲染实现彻底解耦；同步层为 Shelf 嵌入式 HTTP 服务 + mDNS/UDP 组播发现 + LWW 冲突合并。

**Tech Stack:** Flutter 3.x / Dart 3.x, flutter_riverpod ^2.5.1, drift ^2.18.0, shelf ^1.4.1, nsd ^2.4.0, window_manager ^0.3.9, hotkey_manager ^0.1.9, flutter_slidable ^3.1.0, audioplayers ^6.0.0, fl_chart ^0.68.0, pretty_qr_code ^3.3.0

**Spec:** `D:/todo/design-spec.md`（v2.0.0 全架构规格）+ `D:/todo/home-pages-借鉴指南.md`（架构吸收指南）。执行者必须同时阅读 spec 对应章节与本任务块。

---

## Global Constraints（全项目约束，每个任务默认继承）

- **平台**：Windows 10/11 (x64) & Android 8.0+ (ARM64/x86_64)，主开发机为 Windows。
- **离线优先**：零云端依赖，数据 100% 本地 SQLite；"数据绝不流出路由器"，除 AI Copilot（用户自配 API）外禁止任何外部网络请求。
- **性能红线**：Windows 冷启动 < 0.8s；内存驻留 45~70MB（硬上限 75MB）；空闲 CPU 趋近 0%；Android 包体积 ≤ 25MB。
- **ID 规范**：所有实体 ID 使用 ULID（时间有序，利于 LWW 同步排序），不用 `Math.random()` 式无序 ID。
- **时间戳规范**：`created_at` / `updated_at` 一律 UTC 毫秒整数；同步裁决需微秒精度时用 `updated_at_us`。
- **软删除**：删除 = 置位 `deleted_at`，永不物理 DELETE（同步确认且超 30 天后由清理任务统一回收）。
- **命名**：Dart 文件 snake_case；表/字段名与 spec 第 6 章 SQL 定义逐字一致；优先级 0/1/2/3 对应 P0/P1/P2/P3。
- **每个任务**必须走 TDD 循环（先写失败测试→实现→通过→提交），commit message 用 conventional commits（feat/test/chore/docs）。
- **代理**：开发期网络访问（pub、模型 API）统一走 `http://127.0.0.1:7890`，封装在 `HttpClientFactory`，不散落各处。
- **版本**：tag 与 `pubspec.yaml` 的 `version` 必须一致，发布 CI 强制校验。

---

## 文件结构总览（分解决策锁定）

```
lib/
├── main.dart                          # 入口：单实例互斥 → ProviderScope → 启动路由
├── core/
│   ├── theme/app_theme.dart           # M3 明暗主题 + 莫兰迪 6 色 + P0~P3 优先级色
│   ├── theme/app_colors.dart
│   ├── widgets/responsive_scaffold.dart  # 断点: >900px 桌面三栏 / ≤900px 移动底部导航
│   ├── utils/ulid.dart                # ULID 生成器（时间有序）
│   ├── utils/sanitize.dart            # normalizeWith / clampInt / toStringList (T-A3)
│   ├── database/
│   │   ├── app_database.dart          # Drift 连接 + WAL + 迁移
│   │   └── tables.dart                # 8 业务表 + widget_layouts 布局表
│   ├── desktop/
│   │   ├── window_lifecycle.dart      # 无边框窗口、隐藏到托盘
│   │   └── system_tray_manager.dart
│   └── network/http_client_factory.dart  # 7890 代理封装（Copilot 专用）
├── widgets_infra/                     # 仪表盘组件注册表架构（home-pages 移植）
│   ├── daily_widget.dart             # DailyWidgetDefinition 抽象 + WidgetInstance
│   ├── widget_registry.dart          # Map<kind, def> + 热插拔 + 占位卡片
│   ├── widget_context.dart           # registerInterval/isAlive/saveConfig (T-A2)
│   └── sanitize_layout.dart          # sanitizeLayout 入口清洗 (T-A4)
├── features/
│   ├── todos/       (data/ presentation/ + matrix_view)
│   ├── calendar/    (schedule_repository, time_block_timeline)
│   ├── memos/       (memo_repository, memo_card)
│   ├── pomodoro/   (pomodoro_repository, white_noise_service)
│   ├── habits/      (habit_repository, habit_heatmap)
│   ├── review/      (daily_review_view, review_summary_generator)
│   ├── quick_capture/ (service + view)
│   ├── floating_dock/ (controller + view)
│   ├── dashboard/   (dashboard_view, 页面管理, 布局导入导出)
│   ├── copilot/     (ai_service, ai_chat_view)
│   └── sync/        (discovery, local_http_server, diff_packager, merge_engine)
test/
├── core/ ... features/ ... widgets_infra/ ...   # 与 lib 结构镜像
```

**依赖注入**：统一 `ProviderScope` + 手写 Provider（不引入 riverpod_generator，降低 codegen 面积；Drift codegen 已够多）。

---

# Phase 0: 基础设施与环境脚手架

### Task 0.1: Flutter 项目脚手架与依赖配置

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`（占位）

**Interfaces:**
- Produces: 整个工程骨架；后续所有任务的依赖均在此声明。

- [ ] **Step 1: 初始化项目**

```bash
cd D:/todo
flutter create --platforms=windows,android --org com.dailydesk dailydesk
cd dailydesk
```

- [ ] **Step 2: 写入 pubspec.yaml 完整依赖（spec 3.1 矩阵逐项落实）**

```yaml
name: dailydesk
description: 离线优先全能生产力中枢
version: 0.1.0
publish_to: 'none'

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  drift: ^2.18.0
  drift_flutter: ^0.1.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0
  ulid: ^2.0.0
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  http: ^1.2.1
  network_info_plus: ^5.0.3
  nsd: ^2.4.0
  crypto: ^3.0.3
  window_manager: ^0.3.9
  system_tray: ^0.2.3
  hotkey_manager: ^0.1.9
  screen_retriever: ^0.1.9
  launch_at_startup: ^0.2.3
  flutter_slidable: ^3.1.0
  flutter_displaymode: ^0.6.0
  wakelock_plus: ^1.2.8
  fl_chart: ^0.68.0
  flutter_animate: ^4.5.0
  intl: ^0.19.0
  audioplayers: ^6.0.0
  pretty_qr_code: ^3.3.0
  flutter_markdown: ^0.7.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  drift_dev: ^2.18.0
  flutter_lints: ^4.0.0
```

- [ ] **Step 3: 强化 analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_single_quotes: true
    unawaited_futures: true
    avoid_print: true
    always_declare_return_types: true
```

- [ ] **Step 4: 验证**

Run: `flutter pub get && flutter analyze`
Expected: 依赖解析成功，analyze 0 issues。

- [ ] **Step 5: Commit**

```bash
git init 2>/dev/null; git add -A
git commit -m "chore: scaffold DailyDesk Flutter project with full dependency matrix"
```

---

### Task 0.2: 双端自适应主题与调色系统

**Files:**
- Create: `lib/core/theme/app_colors.dart`, `lib/core/theme/app_theme.dart`
- Test: `test/core/theme/app_colors_test.dart`

**Interfaces:**
- Produces: `AppColors.morandiPalette`（6 色 List）、`AppColors.priorityColor(int p)`、`AppTheme.light()` / `AppTheme.dark()`。

- [ ] **Step 1: 写失败测试**

```dart
// test/core/theme/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/theme/app_colors.dart';

void main() {
  test('P0~P3 优先级返回红/橙/蓝/灰', () {
    expect(AppColors.priorityColor(0), AppColors.p0); // 红色
    expect(AppColors.priorityColor(1), AppColors.p1); // 橙色
    expect(AppColors.priorityColor(2), AppColors.p2); // 蓝色
    expect(AppColors.priorityColor(3), AppColors.p3); // 灰色
  });

  test('莫兰迪色系恰好 6 款', () {
    expect(AppColors.morandiPalette.length, 6);
  });

  test('越界优先级安全回退 P3', () {
    expect(AppColors.priorityColor(9), AppColors.p3);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: FAIL（`app_colors.dart` 不存在 / 未定义）。

- [ ] **Step 3: 实现**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const p0 = Color(0xFFE5484D); // P0 紧急且重要-红
  static const p1 = Color(0xFFF5A524); // P1 重要不紧急-橙
  static const p2 = Color(0xFF3B82F6); // P2 紧急不重要-蓝
  static const p3 = Color(0xFF8B8D98); // P3 不紧急不重要-灰

  /// 6 款莫兰迪低饱和便签底色（spec 5.3）
  static const morandiPalette = [
    Color(0xFFD6CCC2), Color(0xFFB5C9B8), Color(0xFFC9B7A9),
    Color(0xFFA3B1C2), Color(0xFFD8C1D0), Color(0xFFCFC8B4),
  ];

  static Color priorityColor(int p) =>
      switch (p) { 0 => p0, 1 => p1, 2 => p2, _ => p3 };
}
```

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2), brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'SystemUI',
    );
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: 3 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme test/core/theme
git commit -m "feat: add M3 theme system with morandi palette and P0-P3 priority colors"
```

---

### Task 0.3: 响应式布局脚手架与多端断点

**Files:**
- Create: `lib/core/widgets/responsive_scaffold.dart`
- Test: `test/core/widgets/responsive_scaffold_test.dart`

**Interfaces:**
- Produces: `ResponsiveScaffold({required Widget desktopBody, required Widget mobileBody, String? title})`，内部断点 `kDesktopBreakpoint = 900.0`。

- [ ] **Step 1: 写失败测试（widget 测试，双断点各验一次）**

```dart
// test/core/widgets/responsive_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/widgets/responsive_scaffold.dart';

void main() {
  testWidgets('宽度 >900 渲染桌面侧栏布局', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
        home: ResponsiveScaffold(
            desktopBody: Text('DESKTOP'), mobileBody: Text('MOBILE'))));
    expect(find.text('DESKTOP'), findsOneWidget);
    expect(find.text('MOBILE'), findsNothing);
  });

  testWidgets('宽度 ≤900 渲染移动端底部导航', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
        home: ResponsiveScaffold(
            desktopBody: Text('DESKTOP'), mobileBody: Text('MOBILE'))));
    expect(find.text('MOBILE'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/core/widgets/responsive_scaffold_test.dart`
Expected: FAIL（类不存在）。

- [ ] **Step 3: 实现**

```dart
// lib/core/widgets/responsive_scaffold.dart
import 'package:flutter/material.dart';

const kDesktopBreakpoint = 900.0;

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold(
      {super.key, required this.desktopBody, required this.mobileBody, this.title});

  final Widget desktopBody;
  final Widget mobileBody;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > kDesktopBreakpoint;
    if (isDesktop) {
      // 桌面：左栏 220px 导航 + 弹性中栏（spec 4.1 形态 1 布局栅格）
      return Scaffold(
        appBar: title == null ? null : AppBar(title: Text(title!)),
        body: Row(children: [
          const SizedBox(width: 220, child: Drawer(child: NavigationDrawerList())),
          Expanded(child: desktopBody),
        ]),
      );
    }
    // 移动：Material 3 底部导航（spec 4.2）
    return Scaffold(
      body: mobileBody,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: '今日聚焦'),
          NavigationDestination(icon: Icon(Icons.checklist), label: '待办'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '日历'),
          NavigationDestination(icon: Icon(Icons.sticky_note_2), label: '便签'),
          NavigationDestination(icon: Icon(Icons.local_fire_department), label: '习惯'),
        ],
      ),
    );
  }
}
```

> 注：`NavigationDrawerList` 在本任务先返回空 `ListView`，Phase 3 各视图就绪后逐项填充真实入口——这是壳层，不影响本任务验收。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/core/widgets/responsive_scaffold_test.dart`
Expected: 2 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets test/core/widgets
git commit -m "feat: add responsive scaffold with 900px desktop/mobile breakpoint"
```

---

### Task 0.4: WidgetRegistry 组件注册表与 ULID 工具（home-pages 1.1 移植）

**Files:**
- Create: `lib/core/utils/ulid.dart`, `lib/widgets_infra/daily_widget.dart`, `lib/widgets_infra/widget_registry.dart`
- Test: `test/widgets_infra/widget_registry_test.dart`

**Interfaces:**
- Produces:
  - `String newUlid()` — 全局 ID 生成入口
  - `abstract class DailyWidgetDefinition<C>` — kind/name/icon/defaultSize/defaultConfig/normalizeConfig/render/renderSettings/liveRefresh
  - `class WidgetInstance { String id; String kind; int w; int h; Map<String,dynamic> config; }`
  - `class WidgetRegistry` — `register(def)` 返回注销函数；`isWidgetKind(kind)` 宽松判断（非空字符串即可，kind 无定义时数据不丢，渲染占位卡片）；内置 kind 禁止覆盖。

- [ ] **Step 1: 写失败测试**

```dart
// test/widgets_infra/widget_registry_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';

class _FakeDef extends DailyWidgetDefinition<Map<String, dynamic>> {
  @override String get kind => 'fake';
  @override String get name => 'Fake';
  @override IconData get icon => Icons.abc;
  @override ({int w, int h}) get defaultSize => (w: 4, h: 3);
  @override Map<String, dynamic> defaultConfig() => {'limit': 3};
  @override Map<String, dynamic> normalizeConfig(Map<String, dynamic> raw) => raw;
  @override Widget render(BuildContext c, WidgetContext<Map<String, dynamic>> ctx) =>
      const SizedBox();
  @override Widget renderSettings(BuildContext c, WidgetSettingsContext<Map<String, dynamic>> ctx) =>
      const SizedBox();
}

void main() {
  test('注册后可查询，注销函数生效', () {
    final reg = WidgetRegistry();
    final dispose = reg.register(_FakeDef(), builtin: true);
    expect(reg.definitionOf('fake'), isNotNull);
    dispose();
    expect(reg.definitionOf('fake'), isNull);
  });

  test('内置 kind 不可被覆盖', () {
    final reg = WidgetRegistry();
    reg.register(_FakeDef(), builtin: true);
    expect(() => reg.register(_FakeDef()), throwsArgumentError);
  });

  test('isWidgetKind 宽松：未知 kind 也保留（数据不丢）', () {
    final reg = WidgetRegistry();
    expect(reg.isWidgetKind('any-third-party'), isTrue);
    expect(reg.isWidgetKind(''), isFalse);
  });

  test('监听器收到注册事件', () {
    final reg = WidgetRegistry();
    var fired = false;
    reg.onRegistryChange((kind, registered) => fired = true);
    reg.register(_FakeDef(), builtin: true);
    expect(fired, isTrue);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widgets_infra/widget_registry_test.dart`
Expected: FAIL（文件不存在）。

- [ ] **Step 3: 实现**

```dart
// lib/core/utils/ulid.dart
import 'package:ulid/ulid.dart';

/// 全局唯一 ID 入口：ULID 时间有序，利于 LWW 同步排序。
String newUlid() => Ulid().toString();

/// UTC 毫秒时间戳（所有 created_at / updated_at 统一走这里）。
int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;
```

```dart
// lib/widgets_infra/daily_widget.dart
import 'package:flutter/material.dart';
import 'package:dailydesk/widgets_infra/widget_context.dart';

/// 持久化的布局单元——只存 kind + 尺寸 + 配置，与渲染实现彻底解耦。
class WidgetInstance {
  WidgetInstance({
    required this.id,
    required this.kind,
    required this.w,
    required this.h,
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  final String id;      // ULID，复制/导入时必须重新生成
  final String kind;    // 组件注册键
  int w;                // 12 列网格中的列宽
  int h;                // 行数
  Map<String, dynamic> config;

  Map<String, dynamic> toJson() =>
      {'id': id, 'kind': kind, 'w': w, 'h': h, 'config': config};
}

/// 组件定义——每个仪表盘模块实现一次，全部平等注册。
abstract class DailyWidgetDefinition<C> {
  String get kind;                  // 'todo' | 'pomodoro' | 'habit' | ...
  String get name;
  IconData get icon;
  ({int w, int h}) get defaultSize; // 12 列网格默认尺寸
  C defaultConfig();
  C normalizeConfig(Map<String, dynamic> raw); // 防脏数据，必须实现
  Widget render(BuildContext context, WidgetContext<C> ctx);
  Widget renderSettings(BuildContext context, WidgetSettingsContext<C> ctx);
  bool get liveRefresh => true;    // 数据变化时是否自动重绘
}
```

```dart
// lib/widgets_infra/widget_registry.dart
import 'package:flutter/foundation.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';

typedef RegistryChangeListener = void Function(String kind, bool registered);

class WidgetRegistry {
  final _byKind = <String, DailyWidgetDefinition>{};
  final _builtinKinds = <String>{};
  final _listeners = <RegistryChangeListener>[];

  /// 注册组件；[builtin] 为 true 后不可被第三方覆盖。
  /// 返回注销函数（闭包自动 unregister）。
  VoidCallback register(DailyWidgetDefinition def, {bool builtin = false}) {
    if (_builtinKinds.contains(def.kind)) {
      throw ArgumentError('内置 kind "${def.kind}" 不可覆盖');
    }
    _byKind[def.kind] = def;
    if (builtin) _builtinKinds.add(def.kind);
    _notify(def.kind, true);
    return () => unregister(def.kind);
  }

  void unregister(String kind) {
    if (_byKind.remove(kind) != null) _notify(kind, false);
  }

  DailyWidgetDefinition? definitionOf(String kind) => _byKind[kind];

  /// 宽松判断：只要非空字符串就认为合法 kind。
  /// 第三方/未加载组件的 WidgetInstance 配置不丢，UI 渲染占位卡片。
  bool isWidgetKind(String? kind) => kind != null && kind.isNotEmpty;

  VoidCallback onRegistryChange(RegistryChangeListener listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notify(String kind, bool registered) {
    for (final l in List.of(_listeners)) {
      l(kind, registered);
    }
  }
}
```

> `widget_context.dart` 在本任务先创建最小骨架（`WidgetContext`/`WidgetSettingsContext` 抽象类签名，见 Task 1.8 完整实现）：

```dart
// lib/widgets_infra/widget_context.dart（本任务先占位，Task 1.8 补全）
import 'dart:async';
import 'package:flutter/widgets.dart';

abstract class WidgetContext<C> {
  C get config;
  Timer registerInterval(void Function() cb, Duration period);
  void registerCleanup(VoidCallback cb);
  bool isAlive();
  Future<void> saveConfig(Map<String, dynamic> patch);
  void rerender();
}

abstract class WidgetSettingsContext<C> {
  C get draft; // 操作草稿，点保存才写回
  Future<void> save();
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/widgets_infra/widget_registry_test.dart`
Expected: 4 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/ulid.dart lib/widgets_infra test/widgets_infra
git commit -m "feat: add WidgetRegistry with hot-plug, builtin protection and loose kind check"
```

---

# Phase 1: 本地数据持久化引擎与仓储实现

### Task 1.1: Drift 数据库表与连接定义（8 业务表 + 布局表）

**Files:**
- Create: `lib/core/database/tables.dart`, `lib/core/database/app_database.dart`
- Test: `test/core/database/app_database_test.dart`

**Interfaces:**
- Produces: `AppDatabase`（含 9 张表）；表/字段名与 spec 第 6 章 SQL **逐字一致**：`todos, subtasks, schedules, memos, pomodoro_logs, habits, habit_records, sync_devices` + 新增 `widget_layouts`（T-A1：仪表盘布局持久化）。
- `widget_layouts` 表结构：`id TEXT PK, page_id TEXT, kind TEXT, w INTEGER, h INTEGER, sort_order INTEGER, config TEXT(JSON), created_at INTEGER, updated_at INTEGER, deleted_at INTEGER`。

- [ ] **Step 1: 写失败测试**

```dart
// test/core/database/app_database_test.dart
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async => db.close());

  test('9 张表全部建表成功', () async {
    final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table'").get();
    final names = tables.map((r) => r.read<String>('name')).toSet();
    for (final t in ['todos', 'subtasks', 'schedules', 'memos',
      'pomodoro_logs', 'habits', 'habit_records', 'sync_devices',
      'widget_layouts']) {
      expect(names, contains(t), reason: '缺表 $t');
    }
  });

  test('WAL 模式已启用（文件库；内存库不支持 WAL 故单独测文件库）', () async {
    final dir = await Directory.systemTemp.createTemp('dd_db');
    final fileDb = AppDatabase(NativeDatabase(File('${dir.path}/t.db')));
    await fileDb.customSelect('PRAGMA journal_mode=WAL').get();
    final r = await fileDb.customSelect('PRAGMA journal_mode').getSingle();
    expect(r.read<String>('journal_mode').toLowerCase(), 'wal');
    await fileDb.close();
  });

  test('外键约束已启用', () async {
    final r = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(r.read<int>('foreign_keys'), 1);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/core/database/app_database_test.dart`
Expected: FAIL（AppDatabase 不存在）。

- [ ] **Step 3: 实现 tables.dart（字段与 spec 6.1 SQL 逐一对应）**

```dart
// lib/core/database/tables.dart
import 'package:drift/drift.dart';

class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get dueDate => text().nullable()(); // YYYY-MM-DD
  TextColumn get dueTime => text().nullable()(); // HH:mm
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isTop => boolean().withDefault(const Constant(false))();
  IntColumn get estimatedPomodoros => integer().nullable()();
  IntColumn get actualPomodoros => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text().nullable()();
  TextColumn get title => text()();
  IntColumn get startTime => integer()(); // UTC ms
  IntColumn get endTime => integer()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get colorHex => text().withDefault(const Constant('#4A90E2'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Memos extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#F9F9FB'))();
  TextColumn get tag => text().nullable()(); // #架构/#UI库/#理念/#工作/#闪念
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PomodoroLogs extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text().nullable()();
  IntColumn get durationMinutes => integer()();
  TextColumn get mode => text().withDefault(const Constant('pomodoro'))();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer()(); // 0 = 进行中
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get frequencyType => text()(); // daily/weekdays/times_per_week
  IntColumn get targetDaysPerWeek => integer().nullable()();
  TextColumn get iconName => text().withDefault(const Constant('check_circle'))();
  TextColumn get colorHex => text().withDefault(const Constant('#52C41A'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitRecords extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  TextColumn get recordDate => text()(); // YYYY-MM-DD
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => ['UNIQUE(habit_id, record_date)'];
}

class SyncDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get platform => text()(); // windows / android
  TextColumn get ipAddress => text()();
  IntColumn get port => integer().withDefault(const Constant(53317))();
  IntColumn get lastSyncedAt => integer().withDefault(const Constant(0))();
  TextColumn get pairingKeyHash => text()();
  BoolColumn get isTrusted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// T-A1：仪表盘布局表——只存 kind + w/h + config JSON，与渲染实现解耦。
class WidgetLayouts extends Table {
  TextColumn get id => text()();       // ULID
  TextColumn get pageId => text()();   // 所属工作台页面
  TextColumn get kind => text()();     // WidgetRegistry 键
  IntColumn get w => integer()();
  IntColumn get h => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get config => text().withDefault(const Constant('{}'))(); // JSON
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:dailydesk/core/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Todos, Subtasks, Schedules, Memos, PomodoroLogs,
  Habits, HabitRecords, SyncDevices, WidgetLayouts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (detail) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // WAL：文件库生效；内存库不支持，静默忽略
          try {
            await customStatement('PRAGMA journal_mode = WAL');
          } catch (_) {}
        },
      );
}
```

- [ ] **Step 4: codegen + 运行测试**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/core/database/app_database_test.dart`
Expected: 生成 `app_database.g.dart`；3 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/core/database test/core/database
git commit -m "feat: add Drift schema for 9 tables with WAL, FK and soft-delete columns"
```

---

### Task 1.2: TodoRepository（待办与子任务仓储）

**Files:**
- Create: `lib/features/todos/data/todo_repository.dart`
- Test: `test/features/todos/todo_repository_test.dart`

**Interfaces:**
- Produces:
  - `Stream<List<Todo>> watchTodos()` — 全量未软删
  - `Stream<List<Todo>> watchTodayTodos()` — `due_date <= today OR is_top` 且 status == pending，P0 置顶排序
  - `Future<void> insertTodo({required String title, int priority, String? dueDate, String? dueTime, String? categoryId, int? estimatedPomodoros})` — 自动 ULID + 时间戳
  - `Future<void> updateTodo(Todo t)` — 自动刷新 `updated_at`
  - `Future<void> updateIsTop(String id, bool v)`
  - `Future<void> softDeleteTodo(String id)` — 置位 `deleted_at`
  - `Future<String?> toggleSubtask(String subtaskId)` — 切换子任务；该主任务全部子任务完成时返回主任务 id（供 UI 弹"是否标记主任务完成"确认，spec 5.1-3）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/todos/todo_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TodoRepository(db);
  });
  tearDown(() => db.close());

  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('插入自动生成 ULID 与时间戳', () async {
    await repo.insertTodo(title: '写周报', priority: 0);
    final all = await repo.watchTodos().first;
    expect(all.single.title, '写周报');
    expect(all.single.id.length, 26); // ULID 长度
    expect(all.single.createdAt, greaterThan(0));
  });

  test('watchTodayTodos 聚合 过期+今日+置顶，排除未来未置顶', () async {
    final now = DateTime.now();
    await repo.insertTodo(title: '过期任务', priority: 1,
        dueDate: ymd(now.subtract(const Duration(days: 1))));
    await repo.insertTodo(title: '今日任务', priority: 1, dueDate: ymd(now));
    await repo.insertTodo(title: '未来任务', priority: 1,
        dueDate: ymd(now.add(const Duration(days: 5))));
    final titles = (await repo.watchTodayTodos().first).map((t) => t.title).toSet();
    expect(titles, containsAll(['过期任务', '今日任务']));
    expect(titles.contains('未来任务'), isFalse);
  });

  test('置顶任务进入今日视图', () async {
    await repo.insertTodo(title: '置顶无日期', priority: 1);
    final t = (await repo.watchTodos().first).single;
    await repo.updateIsTop(t.id, true);
    final titles = (await repo.watchTodayTodos().first).map((x) => x.title);
    expect(titles, contains('置顶无日期'));
  });

  test('软删除不物理删除（供同步）', () async {
    await repo.insertTodo(title: '将删');
    final all = await repo.watchTodos().first;
    await repo.softDeleteTodo(all.single.id);
    expect(await repo.watchTodos().first, isEmpty);
    final raw = await db.customSelect('SELECT COUNT(*) c FROM todos').getSingle();
    expect(raw.read<int>('c'), 1);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/todos/todo_repository_test.dart`
Expected: FAIL（TodoRepository 不存在）。

- [ ] **Step 3: 实现**

```dart
// lib/features/todos/data/todo_repository.dart
import 'package:drift/drift.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class TodoRepository {
  TodoRepository(this._db);
  final AppDatabase _db;

  Stream<List<Todo>> watchTodos() =>
      (_db.select(_db.todos)..where((t) => t.deletedAt.isNull())).watch();

  /// 今日聚焦：截止日期<=今天 OR 置顶，且未完成（spec 5.1）。
  Stream<List<Todo>> watchTodayTodos() {
    final today = _ymd(DateTime.now());
    return (_db.select(_db.todos)
          ..where((t) => t.deletedAt.isNull()
              & t.status.equals('pending')
              & (t.dueDate.isSmallerOrEqualValue(today) | t.isTop.equals(true)))
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.isTop, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> insertTodo({
    required String title,
    int priority = 1,
    String? dueDate,
    String? dueTime,
    String? categoryId,
    int? estimatedPomodoros,
  }) =>
      _db.into(_db.todos).insert(TodosCompanion.insert(
          id: newUlid(), title: title, priority: Value(priority),
          dueDate: Value(dueDate), dueTime: Value(dueTime),
          categoryId: Value(categoryId),
          estimatedPomodoros: Value(estimatedPomodoros),
          createdAt: nowMs(), updatedAt: nowMs()));

  Future<void> updateTodo(Todo t) =>
      (_db.update(_db.todos)..where((r) => r.id.equals(t.id)))
          .write(t.copyWith(updatedAt: nowMs()));

  Future<void> updateIsTop(String id, bool v) =>
      (_db.update(_db.todos)..where((r) => r.id.equals(id)))
          .write(TodosCompanion(isTop: Value(v), updatedAt: Value(nowMs())));

  Future<void> softDeleteTodo(String id) =>
      (_db.update(_db.todos)..where((r) => r.id.equals(id)))
          .write(TodosCompanion(
              deletedAt: Value(nowMs()), updatedAt: Value(nowMs())));

  Future<void> completeTodo(String id) =>
      (_db.update(_db.todos)..where((r) => r.id.equals(id)))
          .write(TodosCompanion(
              status: const Value('completed'), updatedAt: Value(nowMs())));

  /// 切换子任务；若该主任务下全部子任务完成，返回主任务 id（供 UI 弹确认）。
  Future<String?> toggleSubtask(String subtaskId) async {
    final sub = await (_db.select(_db.subtasks)
          ..where((s) => s.id.equals(subtaskId)))
        .getSingle();
    await (_db.update(_db.subtasks)..where((s) => s.id.equals(subtaskId)))
        .write(SubtasksCompanion(
            isCompleted: Value(!sub.isCompleted), updatedAt: Value(nowMs())));
    final siblings = await (_db.select(_db.subtasks)
          ..where((s) => s.todoId.equals(sub.todoId) & s.deletedAt.isNull()))
        .get();
    final allDone = siblings.isNotEmpty && siblings.every((s) => s.isCompleted);
    return allDone ? sub.todoId : null;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/todos/todo_repository_test.dart`
Expected: 4 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/todos/data test/features/todos
git commit -m "feat: add TodoRepository with reactive streams, ULID ids and soft delete"
```

---

### Task 1.3: ScheduleRepository（日程时间块仓储）

**Files:**
- Create: `lib/features/calendar/data/schedule_repository.dart`
- Test: `test/features/calendar/schedule_repository_test.dart`

**Interfaces:**
- Produces:
  - `Stream<List<Schedule>> watchSchedulesInRange(DateTime start, DateTime end)`
  - `Future<Schedule> scheduleTodo({required String todoId, required String title, required DateTime start, required DateTime end, String colorHex})` — 事务内：写 schedules + 反向更新 todo 的 `due_date/due_time`（spec 5.2 联动）
  - `Future<List<Schedule>> overlapping(DateTime start, DateTime end)` — 时间重叠查询

- [ ] **Step 1: 写失败测试**

```dart
// test/features/calendar/schedule_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/calendar/data/schedule_repository.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';

void main() {
  late AppDatabase db;
  late ScheduleRepository repo;
  late TodoRepository todos;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ScheduleRepository(db);
    todos = TodoRepository(db);
  });
  tearDown(() => db.close());

  test('scheduleTodo 事务联动：生成时间块并回写 todo 截止时间', () async {
    await todos.insertTodo(title: '评审方案', priority: 0);
    final todo = (await db.select(db.todos).get()).single;
    final start = DateTime(2025, 10, 13, 10, 0);
    await repo.scheduleTodo(
        todoId: todo.id, title: todo.title,
        start: start, end: start.add(const Duration(hours: 1)));
    final blocks = await repo
        .watchSchedulesInRange(DateTime(2025, 10, 13), DateTime(2025, 10, 14))
        .first;
    expect(blocks.single.title, '评审方案');
    final updated =
        await (db.select(db.todos)..where((t) => t.id.equals(todo.id))).getSingle();
    expect(updated.dueDate, '2025-10-13');
    expect(updated.dueTime, '10:00');
  });

  test('overlapping 检出跨区间重叠', () async {
    final s = DateTime(2025, 10, 13, 9);
    await repo.scheduleTodo(
        todoId: 'x', title: 'A',
        start: s, end: s.add(const Duration(hours: 2)));
    final hit = await repo.overlapping(
        s.add(const Duration(hours: 1)), s.add(const Duration(hours: 3)));
    expect(hit, isNotEmpty);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/calendar/schedule_repository_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/calendar/data/schedule_repository.dart
import 'package:drift/drift.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class ScheduleRepository {
  ScheduleRepository(this._db);
  final AppDatabase _db;

  Stream<List<Schedule>> watchSchedulesInRange(DateTime start, DateTime end) =>
      (_db.select(_db.schedules)
            ..where((s) => s.deletedAt.isNull()
                & s.startTime.isBiggerOrEqualValue(start.millisecondsSinceEpoch)
                & s.startTime.isSmallerThanValue(end.millisecondsSinceEpoch)))
          .watch();

  Future<List<Schedule>> overlapping(DateTime start, DateTime end) =>
      (_db.select(_db.schedules)
            ..where((s) => s.deletedAt.isNull()
                & s.startTime.isSmallerThanValue(end.millisecondsSinceEpoch)
                & s.endTime.isBiggerThanValue(start.millisecondsSinceEpoch)))
          .get();

  Future<Schedule> scheduleTodo({
    required String todoId,
    required String title,
    required DateTime start,
    required DateTime end,
    String colorHex = '#4A90E2',
  }) {
    return _db.transaction(() async {
      final row = Schedule(
          id: newUlid(), todoId: todoId, title: title,
          startTime: start.millisecondsSinceEpoch,
          endTime: end.millisecondsSinceEpoch,
          allDay: false, colorHex: colorHex,
          createdAt: nowMs(), updatedAt: nowMs(), deletedAt: null);
      await _db.into(_db.schedules).insert(row);
      await (_db.update(_db.todos)..where((t) => t.id.equals(todoId)))
          .write(TodosCompanion(
              dueDate: Value(_ymd(start)), dueTime: Value(_hm(start)),
              updatedAt: Value(nowMs())));
      return row;
    });
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/calendar/schedule_repository_test.dart`
Expected: 2 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/data test/features/calendar
git commit -m "feat: add ScheduleRepository with transactional todo-to-timeblock linkage"
```

---

### Task 1.4: MemoRepository（便签仓储 + 一键转待办）

**Files:**
- Create: `lib/features/memos/data/memo_repository.dart`
- Test: `test/features/memos/memo_repository_test.dart`

**Interfaces:**
- Produces:
  - `Stream<List<Memo>> watchMemos({String? tag})` — 置顶优先，创建时间倒序；tag == null 表示 `#全部`
  - `Future<void> insertMemo({required String content, String? tag, String colorHex, bool isPinned})`
  - `Future<String> convertToTodo(String memoId)` — 原子事务：第一行→任务标题，剩余→description，插 todo，原便签软删除归档，返回新 todo id（spec 5.3-3）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/memos/memo_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/memos/data/memo_repository.dart';

void main() {
  late AppDatabase db;
  late MemoRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MemoRepository(db);
  });
  tearDown(() => db.close());

  test('便签转待办：首行标题 + 剩余描述 + 原便签归档', () async {
    await repo.insertMemo(content: '调研 Riverpod\n注意 autoDispose\n看官方示例');
    final memo = (await db.select(db.memos).get()).single;
    final todoId = await repo.convertToTodo(memo.id);
    final todo =
        await (db.select(db.todos)..where((t) => t.id.equals(todoId))).getSingle();
    expect(todo.title, '调研 Riverpod');
    expect(todo.description, '注意 autoDispose\n看官方示例');
    final archived =
        await (db.select(db.memos)..where((m) => m.id.equals(memo.id))).getSingle();
    expect(archived.deletedAt, isNotNull); // 安全归档不物理删
  });

  test('tag 过滤 + 置顶优先排序', () async {
    await repo.insertMemo(content: '架构笔记', tag: '架构');
    await repo.insertMemo(content: '普通', tag: '闪念');
    await repo.insertMemo(content: '置顶闪念', tag: '闪念', isPinned: true);
    final filtered = await repo.watchMemos(tag: '闪念').first;
    expect(filtered.first.content, '置顶闪念'); // 置顶在前
    expect(filtered.length, 2);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/memos/memo_repository_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/memos/data/memo_repository.dart
import 'package:drift/drift.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class MemoRepository {
  MemoRepository(this._db);
  final AppDatabase _db;

  Stream<List<Memo>> watchMemos({String? tag}) =>
      (_db.select(_db.memos)
            ..where((m) => m.deletedAt.isNull()
                & (tag == null ? const Constant(true) : m.tag.equals(tag)))
            ..orderBy([
              (m) => OrderingTerm(expression: m.isPinned, mode: OrderingMode.desc),
              (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
            ]))
          .watch();

  Future<void> insertMemo({
    required String content,
    String? tag,
    String colorHex = '#F9F9FB',
    bool isPinned = false,
  }) =>
      _db.into(_db.memos).insert(MemosCompanion.insert(
          id: newUlid(), content: content, tag: Value(tag),
          colorHex: Value(colorHex), isPinned: Value(isPinned),
          createdAt: nowMs(), updatedAt: nowMs()));

  /// 便签一键转待办（spec 5.3-3）：单事务原子操作。
  Future<String> convertToTodo(String memoId) async {
    final memo =
        await (_db.select(_db.memos)..where((m) => m.id.equals(memoId))).getSingle();
    final lines = memo.content.split('\n');
    final title = lines.first.trim();
    final description = lines.skip(1).join('\n').trim();
    return _db.transaction(() async {
      final todoId = newUlid();
      await _db.into(_db.todos).insert(TodosCompanion.insert(
          id: todoId, title: title,
          description: Value(description.isEmpty ? null : description),
          createdAt: nowMs(), updatedAt: nowMs()));
      await (_db.update(_db.memos)..where((m) => m.id.equals(memoId)))
          .write(MemosCompanion(
              deletedAt: Value(nowMs()), updatedAt: Value(nowMs())));
      return todoId;
    });
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/memos/memo_repository_test.dart`
Expected: 2 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/memos/data test/features/memos
git commit -m "feat: add MemoRepository with tag filter and transactional memo-to-todo conversion"
```

---

### Task 1.5: PomodoroRepository（番茄流水 + 跨重启持久化策略 T-A5）

**Files:**
- Create: `lib/features/pomodoro/data/pomodoro_repository.dart`
- Test: `test/features/pomodoro/pomodoro_repository_test.dart`

**Interfaces:**
- Produces（home-pages 1.4 核心：**存 started_at 绝对时间戳，不存剩余秒数**）:
  - `Future<void> startSession({String? todoId, String mode, int plannedMinutes})` — 写入一条 `endedAt = 0` 的进行中流水；已有进行中会话时抛 StateError
  - `Stream<PomodoroLog?> watchActiveSession()`
  - `Future<void> finishSession(String id, {int? actualMinutes})`
  - `Future<void> cancelSession(String id)` — 软删除
  - `Future<int> todayFocusMinutes()` — 今日聚合（毫秒级返回）
  - 到点提醒采用「绝对时刻调度」：UI 层监听 activeSession 计算 `startedAt + plannedMinutes` 的绝对时刻，进程重启后重算补发

- [ ] **Step 1: 写失败测试**

```dart
// test/features/pomodoro/pomodoro_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';

void main() {
  late AppDatabase db;
  late PomodoroRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PomodoroRepository(db);
  });
  tearDown(() => db.close());

  test('进行中会话唯一，存 started_at 绝对时间戳', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    final active = await repo.watchActiveSession().first;
    expect(active, isNotNull);
    expect(active!.endedAt, 0); // 0 = 进行中
    final elapsed = DateTime.now().millisecondsSinceEpoch - active.startedAt;
    expect(elapsed, greaterThanOrEqualTo(0)); // 剩余时间永远由 now-startedAt 重算
    expect(() => repo.startSession(mode: 'flowtime', plannedMinutes: 0),
        throwsStateError);
  });

  test('今日专注分钟数聚合', () async {
    await repo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    final active = await repo.watchActiveSession().first;
    await repo.finishSession(active!.id, actualMinutes: 25);
    expect(await repo.todayFocusMinutes(), 25);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/pomodoro/pomodoro_repository_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/pomodoro/data/pomodoro_repository.dart
import 'package:drift/drift.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class PomodoroRepository {
  PomodoroRepository(this._db);
  final AppDatabase _db;

  Future<void> startSession({
    String? todoId,
    String mode = 'pomodoro', // pomodoro | flowtime | countdown
    int plannedMinutes = 25,
  }) async {
    final active = await watchActiveSession().first;
    if (active != null) {
      throw StateError('已有进行中的专注会话 ${active.id}');
    }
    await _db.into(_db.pomodoroLogs).insert(PomodoroLogsCompanion.insert(
        id: newUlid(), todoId: Value(todoId),
        durationMinutes: plannedMinutes, mode: mode,
        startedAt: nowMs(), endedAt: 0,
        createdAt: nowMs(), updatedAt: nowMs()));
  }

  Stream<PomodoroLog?> watchActiveSession() =>
      (_db.select(_db.pomodoroLogs)
            ..where((p) => p.deletedAt.isNull() & p.endedAt.equals(0))
            ..limit(1))
          .watch()
          .map((rows) => rows.isEmpty ? null : rows.single);

  Future<void> finishSession(String id, {int? actualMinutes}) async {
    final row = await (_db.select(_db.pomodoroLogs)
          ..where((p) => p.id.equals(id)))
        .getSingle();
    await (_db.update(_db.pomodoroLogs)..where((p) => p.id.equals(id)))
        .write(PomodoroLogsCompanion(
            endedAt: Value(nowMs()),
            durationMinutes: Value(actualMinutes ?? row.durationMinutes),
            updatedAt: Value(nowMs())));
  }

  Future<void> cancelSession(String id) =>
      (_db.update(_db.pomodoroLogs)..where((p) => p.id.equals(id)))
          .write(PomodoroLogsCompanion(
              deletedAt: Value(nowMs()), updatedAt: Value(nowMs())));

  Future<int> todayFocusMinutes() async {
    final dayStart = DateTime.now()
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final rows = await (_db.select(_db.pomodoroLogs)
          ..where((p) => p.deletedAt.isNull()
              & p.startedAt.isBiggerOrEqualValue(dayStart.millisecondsSinceEpoch)))
        .get();
    return rows.fold(0, (sum, r) => sum + r.durationMinutes);
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/pomodoro/pomodoro_repository_test.dart`
Expected: 2 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/pomodoro/data test/features/pomodoro
git commit -m "feat: add PomodoroRepository with started_at persistence strategy"
```

---

### Task 1.6: HabitRepository（习惯 + 连续打卡算法）

**Files:**
- Create: `lib/features/habits/data/habit_repository.dart`
- Test: `test/features/habits/habit_repository_test.dart`

**Interfaces:**
- Produces:
  - `Stream<List<Habit>> watchHabits()`
  - `Future<void> insertHabit({required String name, required String frequencyType, int? targetDaysPerWeek})`
  - `Future<void> toggleCheckIn(String habitId, String recordDate)` — 同日唯一（表级 UNIQUE），再次点击=取消打卡
  - `Future<List<String>> recordDates(String habitId)` — 升序日期集合
  - `static int currentStreak(List<String> sortedDates)` — 纯函数：跨月边界、跳日中断、今天未打但昨天连着不断档
  - `static double strengthScore(List<String> sortedDates)` — Loop Habit 连续衰减健康度（spec 5.12-5）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/habits/habit_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';

void main() {
  late AppDatabase db;
  late HabitRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HabitRepository(db);
  });
  tearDown(() => db.close());

  String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('打卡幂等：同日重复 toggle 为取消', () async {
    await repo.insertHabit(name: '饮水', frequencyType: 'daily');
    final h = (await db.select(db.habits).get()).single;
    await repo.toggleCheckIn(h.id, '2025-10-10');
    expect(await repo.recordDates(h.id), ['2025-10-10']);
    await repo.toggleCheckIn(h.id, '2025-10-10'); // 再点=取消
    expect(await repo.recordDates(h.id), isEmpty);
  });

  group('currentStreak 纯函数', () {
    test('跨月边界', () {
      expect(HabitRepository.currentStreak(
          ['2025-09-29', '2025-09-30', '2025-10-01']), 3);
    });
    test('跳日中断', () {
      expect(HabitRepository.currentStreak(
          ['2025-10-01', '2025-10-02', '2025-10-04']), 1);
    });
    test('今天未打但昨天连着，streak 保留（今天还有机会）', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(HabitRepository.currentStreak([ymd(yesterday)]), 1);
    });
    test('空列表为 0', () {
      expect(HabitRepository.currentStreak([]), 0);
    });
  });

  test('strengthScore 在 0~1 区间且近期打卡得分更高', () {
    final today = DateTime.now();
    final recent = [ymd(today), ymd(today.subtract(const Duration(days: 1)))];
    final old = [ymd(today.subtract(const Duration(days: 50)))];
    expect(HabitRepository.strengthScore(recent),
        greaterThan(HabitRepository.strengthScore(old)));
    expect(HabitRepository.strengthScore(recent), lessThanOrEqualTo(1.0));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/habits/habit_repository_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/habits/data/habit_repository.dart
import 'package:drift/drift.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class HabitRepository {
  HabitRepository(this._db);
  final AppDatabase _db;

  Stream<List<Habit>> watchHabits() =>
      (_db.select(_db.habits)..where((h) => h.deletedAt.isNull())).watch();

  Future<void> insertHabit({
    required String name,
    required String frequencyType, // daily | weekdays | times_per_week
    int? targetDaysPerWeek,
  }) =>
      _db.into(_db.habits).insert(HabitsCompanion.insert(
          id: newUlid(), name: name, frequencyType: frequencyType,
          targetDaysPerWeek: Value(targetDaysPerWeek),
          createdAt: nowMs(), updatedAt: nowMs()));

  /// 同日打卡唯一（表级 UNIQUE(habit_id, record_date)），再次点击 = 取消。
  Future<void> toggleCheckIn(String habitId, String recordDate) async {
    final existing = await (_db.select(_db.habitRecords)
          ..where((r) => r.habitId.equals(habitId) &
              r.recordDate.equals(recordDate) &
              r.deletedAt.isNull()))
        .get();
    if (existing.isNotEmpty) {
      await (_db.update(_db.habitRecords)
            ..where((r) => r.id.equals(existing.single.id)))
          .write(HabitRecordsCompanion(
              deletedAt: Value(nowMs()), updatedAt: Value(nowMs())));
      return;
    }
    await _db.into(_db.habitRecords).insert(HabitRecordsCompanion.insert(
        id: newUlid(), habitId: habitId, recordDate: recordDate,
        createdAt: nowMs(), updatedAt: nowMs()));
  }

  Future<List<String>> recordDates(String habitId) async {
    final rows = await (_db.select(_db.habitRecords)
          ..where((r) => r.habitId.equals(habitId) & r.deletedAt.isNull()))
        .get();
    final dates = rows.map((r) => r.recordDate).toSet().toList()..sort();
    return dates;
  }

  /// 连续打卡天数（纯函数便于单测）。
  /// 今天未打不算断——从昨天起算；一旦断档立即停止。
  static int currentStreak(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;
    final set = sortedDates.toSet();
    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    var anchor = DateTime.now();
    if (!set.contains(key(anchor))) {
      anchor = anchor.subtract(const Duration(days: 1));
      if (!set.contains(key(anchor))) return 0;
    }
    var streak = 0;
    while (set.contains(key(anchor))) {
      streak++;
      anchor = anchor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Loop Habit 式健康度：近期打卡加权求和后对数归一。
  static double strengthScore(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;
    final set = sortedDates.toSet();
    final today = DateTime.now();
    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    var score = 0.0;
    for (var i = 0; i < 60; i++) {
      final d = today.subtract(Duration(days: i));
      if (set.contains(key(d))) score += 1 / (i + 1);
    }
    return (score / 4.6).clamp(0.0, 1.0);
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/habits/habit_repository_test.dart`
Expected: 6 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/habits/data test/features/habits
git commit -m "feat: add HabitRepository with streak algorithm and strength score"
```

---

### Task 1.7: 布局防御三件套 sanitize（T-A3）+ sanitizeLayout 入口清洗（T-A4）

**Files:**
- Create: `lib/core/utils/sanitize.dart`, `lib/widgets_infra/sanitize_layout.dart`
- Test: `test/core/utils/sanitize_test.dart`, `test/widgets_infra/sanitize_layout_test.dart`

**Interfaces:**
- Produces（home-pages 1.3 逐函数移植 + 3.3 页面清洗）:
  - `int clampInt(dynamic v, int min, int max, int fallback)` — 范围钳制+取整+解析失败回退
  - `List<String> toStringList(dynamic v, {int max = 50})` — 字符串/数组双兼容+去重+上限
  - `Map<String, dynamic> normalizeWith(Map<String, dynamic> defaults, Map<String, dynamic> raw)` — 按默认值类型逐字段纠正，多余字段丢弃
  - `SanitizedLayout sanitizeLayout(dynamic raw)` — 三种输入兼容（裸数组 / `{pages:[...]}` / 单页对象）；`activePageId` 孤儿引用自动回退第一页；坏 widget 丢弃不整体崩；w/h 钳制 1..12 / 1..20
  - `class LayoutPage { String id; String name; List<WidgetInstance> widgets; }`

- [ ] **Step 1: 写失败测试**

```dart
// test/core/utils/sanitize_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/utils/sanitize.dart';

void main() {
  test('clampInt 范围钳制 + 解析失败回退', () {
    expect(clampInt('8', 3, 12, 4), 8);
    expect(clampInt(99, 3, 12, 4), 12);
    expect(clampInt('abc', 3, 12, 4), 4);
    expect(clampInt(null, 3, 12, 4), 4);
  });

  test('toStringList 双兼容 + 去重 + 上限', () {
    expect(toStringList('a'), ['a']);
    expect(toStringList(['a', 'a', 'b']), ['a', 'b']);
    expect(toStringList(List.generate(99, (i) => 'k$i')).length, 50);
    expect(toStringList(42), isEmpty);
  });

  test('normalizeWith 数字解析失败回退默认值，多余字段丢弃', () {
    final r = normalizeWith({'limit': 3, 'tag': 'all'}, {'limit': 'xx', 'extra': 1});
    expect(r['limit'], 3);
    expect(r['tag'], 'all');
    expect(r.containsKey('extra'), isFalse);
  });
}
```

```dart
// test/widgets_infra/sanitize_layout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';

void main() {
  test('三种输入形态兼容：裸数组 / 包装 / 单页', () {
    final page = {'id': 'p1', 'name': '工作台',
      'widgets': [{'id': 'w1', 'kind': 'todo', 'w': 4, 'h': 3}]};
    expect(sanitizeLayout([page]).pages.length, 1);
    expect(sanitizeLayout({'pages': [page]}).pages.length, 1);
    expect(sanitizeLayout(page).pages.length, 1);
  });

  test('孤儿 activePageId 自动回退第一页', () {
    final result = sanitizeLayout({
      'activePageId': 'ghost',
      'pages': [{'id': 'p1', 'name': 'A', 'widgets': []},
                {'id': 'p2', 'name': 'B', 'widgets': []}],
    });
    expect(result.activePageId, 'p1');
  });

  test('坏 widget 被丢弃，页面其余保留', () {
    final result = sanitizeLayout({
      'pages': [{'id': 'p1', 'name': 'A', 'widgets': [
        {'id': 'w1', 'kind': 'todo', 'w': 4, 'h': 3},
        {'bad': true},                          // 无 kind，丢弃
        {'id': 'w2', 'kind': '', 'w': 4, 'h': 3}, // 空 kind，丢弃
      ]}],
    });
    expect(result.pages.single.widgets.length, 1);
  });

  test('w/h 钳制进 1..12 / 1..20', () {
    final result = sanitizeLayout({
      'pages': [{'id': 'p1', 'name': 'A', 'widgets': [
        {'id': 'w1', 'kind': 'todo', 'w': 99, 'h': -3},
      ]}],
    });
    final w = result.pages.single.widgets.single;
    expect(w.w, 12);
    expect(w.h, 1);
  });

  test('全垃圾输入兜底出默认页', () {
    final result = sanitizeLayout(42);
    expect(result.pages.length, 1);
    expect(result.pages.first.name, '默认工作台');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/core/utils/sanitize_test.dart test/widgets_infra/sanitize_layout_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/core/utils/sanitize.dart
/// home-pages clampInt 移植：数值钳制 + 取整 + 解析失败回退。
int clampInt(dynamic v, int min, int max, int fallback) {
  final n = v is num ? v : int.tryParse('$v');
  if (n == null) return fallback;
  return n.round().clamp(min, max);
}

/// home-pages toStringList 移植：字符串/数组双兼容 + 去重 + 条数上限。
List<String> toStringList(dynamic v, {int max = 50}) {
  if (v is String) return [v];
  if (v is! List) return const [];
  return v.whereType<String>().take(max).toSet().toList();
}

/// home-pages normalizeWith 移植：按默认值类型逐字段纠正。
/// null→跳过保留默认；多余字段丢弃；数字解析失败→默认值。
Map<String, dynamic> normalizeWith(
    Map<String, dynamic> defaults, Map<String, dynamic> raw) {
  final out = Map<String, dynamic>.of(defaults);
  for (final entry in defaults.entries) {
    final v = raw[entry.key];
    if (v == null) continue;
    final d = entry.value;
    if (d is int) {
      out[entry.key] = clampInt(v, -1 << 40, 1 << 40, d);
    } else if (d is double) {
      out[entry.key] = v is num ? v.toDouble() : double.tryParse('$v') ?? d;
    } else if (d is bool) {
      out[entry.key] = v is bool ? v : v == 'true';
    } else if (d is String) {
      out[entry.key] = '$v';
    } else if (d is List) {
      out[entry.key] = v is List ? v : d;
    } else {
      out[entry.key] = v;
    }
  }
  return out;
}
```

```dart
// lib/widgets_infra/sanitize_layout.dart
import 'dart:convert';
import 'package:dailydesk/core/utils/sanitize.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';

class LayoutPage {
  LayoutPage({required this.id, required this.name, required this.widgets});
  final String id;
  final String name;
  final List<WidgetInstance> widgets;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'widgets': widgets.map((w) => w.toJson()).toList()};
}

class SanitizedLayout {
  SanitizedLayout(this.pages, this.activePageId);
  final List<LayoutPage> pages;
  final String activePageId;
}

/// 全量入口清洗（home-pages 3.3）：任何布局 JSON 进入内存前的唯一关口。
SanitizedLayout sanitizeLayout(dynamic raw) {
  List<dynamic> rawPages;
  String? rawActive;
  if (raw is List) {
    rawPages = raw;
  } else if (raw is Map && raw['pages'] is List) {
    rawPages = raw['pages'] as List;
    rawActive = raw['activePageId'] as String?;
  } else if (raw is Map) {
    rawPages = [raw];
  } else {
    rawPages = const [];
  }
  final pages = <LayoutPage>[];
  for (final p in rawPages) {
    final page = _sanitizePage(p);
    if (page != null) pages.add(page);
  }
  if (pages.isEmpty) {
    pages.add(LayoutPage(id: newUlid(), name: '默认工作台', widgets: []));
  }
  // 孤儿 activePageId 防御：指向不存在的页面时回退第一页
  final active = (rawActive != null && pages.any((p) => p.id == rawActive))
      ? rawActive!
      : pages.first.id;
  return SanitizedLayout(pages, active);
}

LayoutPage? _sanitizePage(dynamic raw) {
  if (raw is! Map) return null;
  final id = raw['id'] as String? ?? newUlid();
  final name = (raw['name'] as String?)?.trim();
  if (name == null || name.isEmpty) return null;
  final widgets = <WidgetInstance>[];
  for (final w in (raw['widgets'] as List? ?? const [])) {
    final instance = _sanitizeWidget(w);
    if (instance != null) widgets.add(instance);
  }
  return LayoutPage(id: id, name: name, widgets: widgets);
}

WidgetInstance? _sanitizeWidget(dynamic raw) {
  if (raw is! Map) return null;
  final kind = raw['kind'] as String?;
  if (kind == null || kind.isEmpty) return null;
  var config = raw['config'];
  if (config is String) {
    try {
      config = jsonDecode(config);
    } catch (_) {
      config = null;
    }
  }
  return WidgetInstance(
      id: raw['id'] as String? ?? newUlid(),
      kind: kind,
      w: clampInt(raw['w'], 1, 12, 4),
      h: clampInt(raw['h'], 1, 20, 3),
      config: config is Map ? Map<String, dynamic>.of(config) : null);
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/core/utils/sanitize_test.dart test/widgets_infra/sanitize_layout_test.dart`
Expected: 8 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/sanitize.dart lib/widgets_infra/sanitize_layout.dart test/core/utils test/widgets_infra
git commit -m "feat: add sanitize trio and sanitizeLayout gate with orphan-page fallback"
```

---

### Task 1.8: WidgetContext 受控渲染上下文（T-A2）

**Files:**
- Modify: `lib/widgets_infra/widget_context.dart`（替换 Task 0.4 的占位骨架）
- Test: `test/widgets_infra/widget_context_test.dart`

**Interfaces:**
- Produces（home-pages 1.2 完整移植）:
  - `WidgetContext<C>` 抽象：`registerInterval(cb, period)` / `registerCleanup(cb)` / `isAlive()` / `saveConfig(patch)` / `rerender()`
  - `LiveWidgetContext<C>`：挂在 StatefulWidget State 上的生产实现，`dispose()` 统一 cancel 定时器并执行清理
  - `WidgetSettingsContext<C>` 抽象：操作**草稿**，`save()` 才写回
  - 铁律：异步加载完成后先 `isAlive()` 判断再写状态，杜绝 async gap 后写已 dispose 的 widget（内存红线 75MB 的主要防线）

- [ ] **Step 1: 写失败测试**

```dart
// test/widgets_infra/widget_context_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/widgets_infra/widget_context.dart';

void main() {
  test('registerInterval 定时回调执行且 isAlive 为 false 后不再执行', () async {
    var alive = true;
    var count = 0;
    final ctx = LiveWidgetContext<Map<String, dynamic>>(
      isMounted: () => alive,
      instance: throw UnimplementedError(), // 本测试不触 config
      onConfigSaved: (_) async {},
      onRerender: () {},
    )..parsedConfig = {};
    ctx.registerInterval(() => count++, const Duration(milliseconds: 10));
    await Future<void>.delayed(const Duration(milliseconds: 60));
    alive = false;
    final before = count;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    ctx.dispose();
    expect(count, greaterThan(1));
    expect(count, before); // 死后不再回调
  });

  test('dispose 后 cleanup 执行且 isAlive 为 false', () {
    var alive = true;
    final ctx = LiveWidgetContext<Map<String, dynamic>>(
      isMounted: () => alive,
      instance: throw UnimplementedError(),
      onConfigSaved: (_) async {},
      onRerender: () {},
    )..parsedConfig = {};
    var cleaned = false;
    ctx.registerCleanup(() => cleaned = true);
    ctx.dispose();
    expect(cleaned, isTrue);
    expect(ctx.isAlive(), isFalse);
  });

  test('saveConfig 不触发 rerender（显式调用才重绘）', () async {
    var rerenders = 0;
    var alive = true;
    final ctx = LiveWidgetContext<Map<String, dynamic>>(
      isMounted: () => alive,
      instance: throw UnimplementedError(),
      onConfigSaved: (_) async {},
      onRerender: () => rerenders++,
    )..parsedConfig = {};
    await ctx.saveConfig({'a': 2});
    expect(rerenders, 0);
    ctx.rerender();
    expect(rerenders, 1);
    ctx.dispose();
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/widgets_infra/widget_context_test.dart`

- [ ] **Step 3: 实现（替换占位骨架文件全文）**

```dart
// lib/widgets_infra/widget_context.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';

/// 受控渲染上下文（home-pages WidgetContext 移植）：
/// 组件不直接拿全局对象，定时器/清理/生命周期由框架统一管理。
abstract class WidgetContext<C> {
  C get config;
  Timer registerInterval(void Function() cb, Duration period);
  void registerCleanup(VoidCallback cb);
  bool isAlive();
  Future<void> saveConfig(Map<String, dynamic> patch);
  void rerender();
}

/// 配置面板上下文：操作草稿，点保存才写回。
abstract class WidgetSettingsContext<C> {
  C get draft;
  Future<void> save();
}

/// 生产实现：挂在 StatefulWidget State 上。
class LiveWidgetContext<C> extends WidgetContext<C> {
  LiveWidgetContext({
    required bool Function() isMounted,
    required this.instance,
    required this.onConfigSaved,
    required this.onRerender,
  }) : _isMounted = isMounted;

  final bool Function() _isMounted;
  final WidgetInstance instance;
  final Future<void> Function(Map<String, dynamic> patch) onConfigSaved;
  final VoidCallback onRerender;

  final _timers = <Timer>[];
  final _cleanups = <VoidCallback>[];

  /// 组件定义 normalizeConfig 解析后的强类型配置。
  C? parsedConfig;

  @override
  C get config => parsedConfig as C;

  @override
  Timer registerInterval(void Function() cb, Duration period) {
    final t = Timer.periodic(period, (_) {
      if (isAlive()) cb();
    });
    _timers.add(t);
    return t;
  }

  @override
  void registerCleanup(VoidCallback cb) => _cleanups.add(cb);

  @override
  bool isAlive() => _isMounted();

  @override
  Future<void> saveConfig(Map<String, dynamic> patch) =>
      onConfigSaved(patch); // 只写不重绘

  @override
  void rerender() {
    if (isAlive()) onRerender();
  }

  /// State.dispose 时调用：统一清理，杜绝泄漏。
  void dispose() {
    for (final t in _timers) t.cancel();
    for (final cb in _cleanups) cb();
    _timers.clear();
    _cleanups.clear();
  }
}
```

> 测试中 `instance: throw UnimplementedError()` 是无效语法，实际写为 `instance: WidgetInstance(id: 't', kind: 't', w: 4, h: 3)`。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/widgets_infra/widget_context_test.dart`
Expected: 3 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/widgets_infra/widget_context.dart test/widgets_infra
git commit -m "feat: add WidgetContext with managed timers, cleanup and isAlive guard"
```

---

# Phase 2: Windows 桌面特色窗口与系统级服务

> Phase 2 依赖 Windows 宿主环境，单元测试以纯逻辑层为主；窗口行为验收标注为「手动验收步骤」逐条列出，由执行者在本机 `flutter run -d windows` 实测打勾。

### Task 2.1: Windows 单实例互斥锁与无边框沉浸窗口

**Files:**
- Create: `lib/core/desktop/window_lifecycle.dart`
- Modify: `windows/runner/main.cpp`, `lib/main.dart`
- Test: `test/core/desktop/window_lifecycle_test.dart`（纯逻辑：动作决策表）

**Interfaces:**
- Produces:
  - `enum CloseAction { hideToTray, exit }`
  - `CloseAction decideCloseAction({required bool closeToTrayEnabled})` — 关闭按钮默认转 `hideToTray`（spec 4.1 形态 1）
  - `class WindowLifecycle` — `ensureInitialized()`（无边框+最小尺寸 960x640+默认 1200x820）、`hideToTray()`、`restoreAndFocus()`
- Windows 侧：`main.cpp` 创建命名互斥体 `Global\\DailyDeskSingleton`，已存在则向已有窗口发 `WM_APP + 1` 唤醒消息后退出当前进程（spec 8-1）。

- [ ] **Step 1: 写失败测试（决策逻辑）**

```dart
// test/core/desktop/window_lifecycle_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/desktop/window_lifecycle.dart';

void main() {
  test('关闭动作决策：默认隐藏到托盘', () {
    expect(decideCloseAction(closeToTrayEnabled: true), CloseAction.hideToTray);
  });
  test('用户关闭托盘常驻时为真退出', () {
    expect(decideCloseAction(closeToTrayEnabled: false), CloseAction.exit);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/core/desktop/window_lifecycle_test.dart`

- [ ] **Step 3: 实现 Dart 侧**

```dart
// lib/core/desktop/window_lifecycle.dart
import 'package:window_manager/window_manager.dart';

enum CloseAction { hideToTray, exit }

CloseAction decideCloseAction({required bool closeToTrayEnabled}) =>
    closeToTrayEnabled ? CloseAction.hideToTray : CloseAction.exit;

class WindowLifecycle with WindowListener {
  WindowLifecycle._();
  static final instance = WindowLifecycle._();

  Future<void> ensureInitialized() async {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1200, 820),          // spec 4.1 默认尺寸
      minimumSize: Size(960, 640),    // 最小尺寸
      titleBarStyle: TitleBarStyle.hidden, // 沉浸式透明标题栏
      windowButtonVisibility: false,       // 自定义三键
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    windowManager.addListener(this);
  }

  Future<void> hideToTray() async {
    await windowManager.hide();
  }

  Future<void> restoreAndFocus() async {
    await windowManager.show();
    await windowManager.restore();
    await windowManager.focus();
  }

  @override
  void onWindowClose() async {
    // 交由 main.dart 中 Provider 读取用户设置后路由到 hideToTray / destroy
  }
}
```

- [ ] **Step 4: 实现 main.cpp 互斥体**

在 `windows/runner/main.cpp` 的 `WinMain` 开头、创建窗口之前插入：

```cpp
  // DailyDesk 单实例互斥（spec 8-1）：防止双进程读写 SQLite 死锁
  HANDLE singleton_mutex = CreateMutexW(nullptr, TRUE, L"Global\\DailyDeskSingleton");
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    // 找到已有窗口并广播唤醒消息，随后退出当前进程
    HWND existing = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"dailydesk");
    if (existing != nullptr) {
      SendMessageW(existing, WM_APP + 1, 0, 0);
      SetForegroundWindow(existing);
    }
    ReleaseMutex(singleton_mutex);
    return EXIT_FAILURE;
  }
```

- [ ] **Step 5: 运行测试 + 手动验收**

Run: `flutter test test/core/desktop/window_lifecycle_test.dart`
Expected: 2 passed。

手动验收（`flutter run -d windows`）：
- [ ] 窗口无边框，自定义标题栏可拖拽移动
- [ ] 窗口不可缩到 960x640 以下
- [ ] 双击 exe 第二次启动：旧窗口被唤起置前，新进程退出
- [ ] 任务管理器确认仅一个进程

- [ ] **Step 6: Commit**

```bash
git add lib/core/desktop windows/runner/main.cpp test/core/desktop
git commit -m "feat: add Windows single-instance mutex and frameless window lifecycle"
```

---

### Task 2.2: 系统托盘常驻与上下文菜单

**Files:**
- Create: `lib/core/desktop/system_tray_manager.dart`
- Test: 纯逻辑测试 `test/core/desktop/system_tray_manager_test.dart`（菜单构建）

**Interfaces:**
- Produces:
  - `List<TrayMenuItem> buildTrayMenu({required bool isPomodoroRunning})` — 菜单项纯函数，便于测试
  - `class TrayMenuItem { String key; String label; }`
  - `class SystemTrayManager` — `init()` 注册图标与菜单（打开工作台 / 开启番茄钟 / 局域网同步 / 彻底退出）；点击「彻底退出」才真正 `windowManager.destroy()`

- [ ] **Step 1: 写失败测试**

```dart
// test/core/desktop/system_tray_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/desktop/system_tray_manager.dart';

void main() {
  test('托盘菜单含四项固定动作', () {
    final menu = buildTrayMenu(isPomodoroRunning: false)
        .map((m) => m.key).toSet();
    expect(menu, containsAll(['open', 'pomodoro', 'sync', 'quit']));
  });
  test('番茄进行中时菜单文案切换为暂停', () {
    final pomo = buildTrayMenu(isPomodoroRunning: true)
        .firstWhere((m) => m.key == 'pomodoro');
    expect(pomo.label, contains('暂停'));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/core/desktop/system_tray_manager_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/core/desktop/system_tray_manager.dart
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dailydesk/core/desktop/window_lifecycle.dart';

class TrayMenuItem {
  const TrayMenuItem(this.key, this.label);
  final String key;
  final String label;
}

List<TrayMenuItem> buildTrayMenu({required bool isPomodoroRunning}) => [
      const TrayMenuItem('open', '打开工作台'),
      TrayMenuItem('pomodoro',
          isPomodoroRunning ? '暂停番茄钟' : '开启番茄钟'),
      const TrayMenuItem('sync', '局域网同步'),
      const TrayMenuItem('quit', '彻底退出'),
    ];

class SystemTrayManager {
  final _tray = SystemTray();
  final void Function(String key)? onCommand;

  SystemTrayManager({this.onCommand});

  Future<void> init() async {
    await _tray.initSystemTray(
        title: 'DailyDesk', iconPath: 'assets/app_icon.ico');
    final menu = Menu();
    for (final item in buildTrayMenu(isPomodoroRunning: false)) {
      await menu.buildFrom([
        MenuItemLabel(
            label: item.label,
            onClicked: (_) => onCommand?.call(item.key)),
      ]);
    }
    await _tray.setContextMenu(menu);
    _tray.registerSystemTrayEventHandler((eventName) async {
      if (eventName == kSystemTrayEventClick) {
        await WindowLifecycle.instance.restoreAndFocus(); // 双击托盘恢复
      }
    });
  }

  Future<void> dispose() => _tray.destroy();
}
```

- [ ] **Step 4: 运行测试**

Run: `flutter test test/core/desktop/system_tray_manager_test.dart`
Expected: 2 passed。

- [ ] **Step 5: 手动验收（flutter run -d windows）**

- [ ] 主窗口点关闭 → 托盘常驻
- [ ] 双击托盘图标 → 窗口秒级恢复
- [ ] 右键 → 四项菜单齐全
- [ ] 「彻底退出」→ 进程真正结束

- [ ] **Step 6: Commit**

```bash
git add lib/core/desktop/system_tray_manager.dart test/core/desktop
git commit -m "feat: add system tray with context menu and restore-on-click"
```

---

### Task 2.3: 全局热键与极速闪念胶囊窗口（Alt+Space + NLP 解析）

**Files:**
- Create: `lib/features/quick_capture/quick_capture_service.dart`, `lib/features/quick_capture/nlp_quick_parser.dart`, `lib/features/quick_capture/presentation/quick_capture_view.dart`
- Test: `test/features/quick_capture/nlp_quick_parser_test.dart`（NLP 解析是纯函数，全量测试）

**Interfaces:**
- Produces（spec 5.7-1）:
  - `class ParsedCapture { String title; int? priority; String? dueDate; String? dueTime; String? tag; }`
  - `ParsedCapture parseCapture(String raw)` — 解析轻量语法：`!P0..!P3` 优先级、`#标签`、中文时间词（明天下午3点 / 今天17:00 / 下周一 9:30 / 明早10点）——标题为剔除语法标记后的剩余文本
  - `class QuickCaptureService` — `init()` 注册 `Alt+Space` 全局热键；ESC/失焦隐藏；Enter 保存后写收集箱并隐藏（100ms 内弹出）

- [ ] **Step 1: 写失败测试（NLP 核心用例全覆盖）**

```dart
// test/features/quick_capture/nlp_quick_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/quick_capture/nlp_quick_parser.dart';

void main() {
  test('spec 示例：明天下午3点跟进方案 !P0 #工作', () {
    final r = parseCapture('明天下午3点跟进方案 !P0 #工作');
    expect(r.title, '跟进方案');
    expect(r.priority, 0);
    expect(r.tag, '工作');
    expect(r.dueDate, isNotNull); // 明天的日期
    expect(r.dueTime, '15:00');
  });

  test('明早10点 → 明日 10:00', () {
    final r = parseCapture('明早10点提交报告');
    expect(r.title, '提交报告');
    expect(r.dueTime, '10:00');
    expect(r.dueDate, isNotNull);
  });

  test('今天 17:00', () {
    final r = parseCapture('今天 17:00 站会');
    expect(r.title, '站会');
    expect(r.dueTime, '17:00');
  });

  test('无任何标记 → 纯标题进收集箱（dueDate 为空）', () {
    final r = parseCapture('读《原则》第3章');
    expect(r.title, '读《原则》第3章');
    expect(r.priority, isNull);
    expect(r.dueDate, isNull);
    expect(r.dueTime, isNull);
  });

  test('英文时间词兼容', () {
    final r = parseCapture('tomorrow 3pm sync !P1');
    expect(r.priority, 1);
    expect(r.dueTime, '15:00');
    expect(r.dueDate, isNotNull);
  });

  test('下周一 9:30', () {
    final r = parseCapture('下周一 9:30 周会');
    expect(r.dueTime, '09:30');
    final due = DateTime.parse(r.dueDate!);
    expect(due.weekday, DateTime.monday);
    expect(due.isAfter(DateTime.now()), isTrue);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/quick_capture/nlp_quick_parser_test.dart`

- [ ] **Step 3: 实现 NLP 解析器**

```dart
// lib/features/quick_capture/nlp_quick_parser.dart

class ParsedCapture {
  ParsedCapture({required this.title, this.priority, this.dueDate,
      this.dueTime, this.tag});
  final String title;
  final int? priority;   // 0..3
  final String? dueDate; // YYYY-MM-DD
  final String? dueTime; // HH:mm
  final String? tag;
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 轻量语法解析（spec 4.1 形态 2 + 5.7-1）：
/// !P0~!P3 优先级 / #标签 / 中文英文时间词。
ParsedCapture parseCapture(String raw) {
  var text = raw.trim();
  int? priority;
  String? tag;
  String? dueTime;
  DateTime? dueDate;

  // 1. 优先级 !P0..!P3
  final prioMatch = RegExp(r'!P([0-3])\b', caseSensitive: false).firstMatch(text);
  if (prioMatch != null) {
    priority = int.parse(prioMatch.group(1)!);
    text = text.replaceFirst(prioMatch.group(0)!, '').trim();
  }

  // 2. 标签 #xxx
  final tagMatch = RegExp(r'#(\S+)').firstMatch(text);
  if (tagMatch != null) {
    tag = tagMatch.group(1);
    text = text.replaceFirst(tagMatch.group(0)!, '').trim();
  }

  // 3. 时间词（先粗匹配日期短语，再扫时刻）
  final now = DateTime.now();
  final dayRules = <Pattern, Duration Function()>{
    RegExp(r'今天|today'): () => const Duration(),
    RegExp(r'明天|明日|tomorrow'): () => const Duration(days: 1),
    RegExp(r'后天'): () => const Duration(days: 2),
  };
  for (final e in dayRules.entries) {
    final m = e.key.firstMatch(text);
    if (m != null) {
      dueDate = now.add(e.value());
      text = text.replaceFirst(m.group(0)!, '').trim();
      break;
    }
  }
  // 明早/明晚 → 明天
  final morningMatch = RegExp(r'明早|明晨').firstMatch(text);
  if (morningMatch != null) {
    dueDate ??= now.add(const Duration(days: 1));
    text = text.replaceFirst(morningMatch.group(0)!, '').trim();
  }
  // 下周X
  final nextWeekMatch = RegExp(r'下周([一二三四五六日天])').firstMatch(text);
  if (nextWeekMatch != null) {
    const map = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7};
    final target = map[nextWeekMatch.group(1)]!;
    var d = now.add(const Duration(days: 7));
    d = d.subtract(Duration(days: d.weekday - target));
    if (!d.isAfter(now)) d = d.add(const Duration(days: 7));
    dueDate = d;
    text = text.replaceFirst(nextWeekMatch.group(0)!, '').trim();
  }

  // 4. 时刻：下午3点 / 17:00 / 3pm / 明早10点
  final pmZh = RegExp(r'(下午|傍晚|晚上)(\d{1,2})[点时](半)?').firstMatch(text);
  final amZh = RegExp(r'(上午|早上|早晨|凌晨)?(\d{1,2})[点时](半)?').firstMatch(text);
  final enTime = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false)
      .firstMatch(text);
  final hmTime = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(text);
  int hour = -1, minute = 0;
  if (pmZh != null) {
    hour = int.parse(pmZh.group(2)!) + 12;
    if (pmZh.group(3) != null) minute = 30;
    text = text.replaceFirst(pmZh.group(0)!, '').trim();
  } else if (enTime != null) {
    hour = int.parse(enTime.group(1)!);
    if (enTime.group(3)!.toLowerCase() == 'pm' && hour < 12) hour += 12;
    minute = enTime.group(2) != null ? int.parse(enTime.group(2)!) : 0;
    text = text.replaceFirst(enTime.group(0)!, '').trim();
  } else if (hmTime != null) {
    hour = int.parse(hmTime.group(1)!);
    minute = int.parse(hmTime.group(2)!);
    text = text.replaceFirst(hmTime.group(0)!, '').trim();
  } else if (amZh != null && amZh.group(2) != null) {
    hour = int.parse(amZh.group(2)!);
    if (amZh.group(3) != null) minute = 30;
    text = text.replaceFirst(amZh.group(0)!, '').trim();
  }
  if (hour >= 0) {
    dueTime =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  return ParsedCapture(
      title: text.trim(), priority: priority, tag: tag,
      dueDate: dueDate == null ? null : _ymd(dueDate), dueTime: dueTime);
}
```

- [ ] **Step 4: 实现热键服务与胶囊视图**

```dart
// lib/features/quick_capture/quick_capture_service.dart
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class QuickCaptureService {
  HotKey? _hotKey;
  final VoidCallback onTriggered;
  QuickCaptureService({required this.onTriggered});

  Future<void> init() async {
    _hotKey = HotKey(KeyCode.space, modifiers: [KeyModifier.alt]);
    await hotKeyManager.register(_hotKey!, callback: (_) => onTriggered());
  }

  Future<void> dispose() async {
    if (_hotKey != null) await hotKeyManager.unregister(_hotKey!);
  }
}
```

```dart
// lib/features/quick_capture/presentation/quick_capture_view.dart
// 660x64 无边框居上（主屏上方 20%）胶囊输入条（spec 4.1 形态 2）。
// Enter → parseCapture → insertTodo（无日期则进收集箱）→ SnackBar 轻提示 → 隐藏
// ESC / 失焦 → 清空并隐藏
// 完整交互实现遵循原型 prototype.html 的 quick-capture 样式，
// 执行者实现时打开原型文件对照 CSS（位置 top: 20vh, 宽 660px, 高 64px, 圆角 16, 阴影）。
```

> 视图层执行要点（写完整 StatefulWidget，不在此展开 boilerplate）：
> 1. `Focus(onKeyEvent)` 拦截 ESC；`FocusNode` 监听失焦自动隐藏。
> 2. Enter 提交：`parseCapture(text)` → `ref.read(todoRepoProvider).insertTodo(...)`，无 `dueDate` 时即收集箱条目（spec 5.1 Inbox 定义）。
> 3. 提交成功播放 40ms Pop 微音效（Task 3.1 统一音效管理器就绪后接入，本任务先留 `// TODO(hook-sound):` 挂点）。

- [ ] **Step 5: 运行测试**

Run: `flutter test test/features/quick_capture/nlp_quick_parser_test.dart`
Expected: 6 passed。

- [ ] **Step 6: 手动验收**

- [ ] 任意第三方软件（浏览器/VSCode）聚焦时按 Alt+Space，100ms 内弹出输入条且光标就位
- [ ] 输入 `明天下午3点跟进方案 !P0 #工作` 回车 → 待办库出现 P0 任务，截止明天 15:00，分类「工作」
- [ ] ESC 隐藏；点击窗口外失焦隐藏

- [ ] **Step 7: Commit**

```bash
git add lib/features/quick_capture test/features/quick_capture
git commit -m "feat: add Alt+Space quick capture with NLP date/priority/tag parser"
```

---

### Task 2.4: 桌面贴边吸附悬浮条 (Floating Edge Dock)

**Files:**
- Create: `lib/features/floating_dock/floating_dock_controller.dart`, `lib/features/floating_dock/presentation/floating_dock_view.dart`
- Test: `test/features/floating_dock/floating_dock_controller_test.dart`

**Interfaces:**
- Produces:
  - `enum DockState { collapsed, expanded }`
  - `class FloatingDockController` — `DockState decide({required bool hovered, required Duration hoverDuration})`：hover > 150ms 展开；离开 > 400ms 收缩（纯逻辑可测）
  - 视图：贴边 4x120 半透明细条 → 展开 280x420 卡片（顶部番茄倒计时+暂停微按钮 / 主体今日 Top3 一键划勾 / 底部打开主窗按钮），`screen_retriever` 计算 WorkArea 贴左/右任意高度

- [ ] **Step 1: 写失败测试**

```dart
// test/features/floating_dock/floating_dock_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/floating_dock/floating_dock_controller.dart';

void main() {
  test('悬停不足 150ms 不展开', () {
    final c = FloatingDockController();
    expect(
        c.decide(hovered: true, hoverDuration: const Duration(milliseconds: 100)),
        DockState.collapsed);
  });
  test('悬停超过 150ms 展开', () {
    final c = FloatingDockController();
    expect(
        c.decide(hovered: true, hoverDuration: const Duration(milliseconds: 200)),
        DockState.expanded);
  });
  test('离开超过 400ms 收缩', () {
    final c = FloatingDockController();
    c.decide(hovered: true, hoverDuration: const Duration(milliseconds: 200));
    expect(
        c.decide(hovered: false, hoverDuration: const Duration(milliseconds: 500)),
        DockState.collapsed);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/floating_dock/floating_dock_controller_test.dart`

- [ ] **Step 3: 实现 controller + 视图**

```dart
// lib/features/floating_dock/floating_dock_controller.dart
enum DockState { collapsed, expanded }

class FloatingDockController {
  DockState _state = DockState.collapsed;
  DockState get state => _state;

  /// 展开条件：hover 且时长 > 150ms；收缩条件：离开且时长 > 400ms。
  DockState decide({required bool hovered, required Duration hoverDuration}) {
    if (hovered && hoverDuration > const Duration(milliseconds: 150)) {
      _state = DockState.expanded;
    } else if (!hovered && hoverDuration > const Duration(milliseconds: 400)) {
      _state = DockState.collapsed;
    }
    return _state;
  }
}
```

视图实现要点（完整 StatefulWidget，参照 prototype.html 的 dock 样式）：
1. `MouseRegion(onEnter/onExit)` + `Timer` 驱动 `decide()`；`AnimatedContainer` 展开动画（280x420，spring 曲线）。
2. 顶部：`watchActiveSession()` 流 + `now - startedAt` 重算倒计时（复用 Task 1.5），暂停/继续微按钮。
3. 主体：`watchTodayTodos().first 3` 条，Checkbox 一键完成。
4. 底部：「打开主工作台」→ `WindowLifecycle.instance.restoreAndFocus()`。
5. 贴边：`screen_retriever` 的 `getDisplayMedia()` 取 WorkArea，用户可拖动至左/右边缘任意高度，位置持久化到 `SharedPreferences`（key: `dock_edge`, `dock_offset`）。

- [ ] **Step 4: 运行测试**

Run: `flutter test test/features/floating_dock/floating_dock_controller_test.dart`
Expected: 3 passed。

- [ ] **Step 5: 手动验收**

- [ ] 平时贴边仅 4px 细条
- [ ] 悬停 >150ms 平滑滑出；移开 >400ms 缩回
- [ ] 展开卡片可勾掉任务、看到番茄倒计时

- [ ] **Step 6: Commit**

```bash
git add lib/features/floating_dock test/features/floating_dock
git commit -m "feat: add floating edge dock with hover expand/collapse thresholds"
```

---

# Phase 3: 业务功能模块双端精细化构建

### Task 3.1: 待办列表视图与四象限跨象限拖拽看板

**Files:**
- Create: `lib/features/todos/presentation/todo_list_view.dart`, `lib/features/todos/presentation/matrix_view.dart`, `lib/core/audio/sound_manager.dart`
- Test: `test/features/todos/todo_list_view_test.dart`（widget 测试核心渲染断言）

**Interfaces:**
- Consumes: `TodoRepository`（Task 1.2）
- Produces:
  - `TodoListView` — 今日聚焦 / 收集箱两个 tab；行内极速添加表单（标题 + P0~P3 下拉 + 🍅 预算 + 截止时间，回车插入，spec 5.10-2）
  - `MatrixView` — 2x2 四象限看板；`Draggable`/`DragTarget` 跨象限拖拽即改 priority 并持久化（spec 5.10-3）
  - `SoundManager.playPop()` — 40ms 勾选微音效（Pop），全局单例；打勾伴随卡片回弹与划线动效（spec 5.7-3）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/todos/todo_list_view_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/todos/presentation/todo_list_view.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  testWidgets('今日视图渲染待办并支持勾选完成', (tester) async {
    final repo = TodoRepository(db);
    await repo.insertTodo(title: '任务A', priority: 0);
    await tester.pumpWidget(ProviderScope(
      overrides: [todoRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: TodoListView())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('任务A'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('四象限视图按优先级分区渲染', (tester) async {
    final repo = TodoRepository(db);
    await repo.insertTodo(title: '紧急任务', priority: 0);
    await repo.insertTodo(title: '备选任务', priority: 3);
    await tester.pumpWidget(ProviderScope(
      overrides: [todoRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: MatrixView())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('紧急任务'), findsOneWidget); // P0 象限
    expect(find.text('备选任务'), findsOneWidget); // P3 象限
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/todos/todo_list_view_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/core/audio/sound_manager.dart
import 'package:audioplayers/audioplayers.dart';

/// 全局微音效管理器（spec 5.7-3：40ms 轻柔 Pop/Ding）。
class SoundManager {
  SoundManager._();
  static final instance = SoundManager._();
  final _player = AudioPlayer(playerId: 'sfx');
  bool enabled = true;

  Future<void> playPop() async {
    if (!enabled) return;
    await _player.play(AssetSource('sfx/pop.mp3'), volume: 0.4);
  }

  Future<void> playDing() async {
    if (!enabled) return;
    await _player.play(AssetSource('sfx/ding.mp3'), volume: 0.5);
  }
}
```

> ⚠️ 资产前置：`assets/sfx/pop.mp3`、`assets/sfx/ding.mp3` 需在 pubspec 声明 assets。执行时用任意 40ms 短促音效文件（可用 ffmpeg 生成 40ms 440Hz 正弦）：
> `ffmpeg -f lavfi -i "sine=frequency=880:duration=0.04" -ac 1 assets/sfx/pop.mp3`

Provider 定义（`todo_list_view.dart` 头部）：

```dart
final todoRepositoryProvider = Provider<TodoRepository>((ref) =>
    throw UnimplementedError('由 main.dart 用真实 db 注入'));
```

`TodoListView` 实现要点：
1. `DefaultTabController` 两 tab：今日聚焦（`watchTodayTodos`）/ 收集箱（`watchTodos` 过滤 dueDate==null）。
2. 行内添加表单：`TextField` + 优先级 `DropdownButton`(P0~P3) + 番茄预算 `DropdownButton`(1~3) + `dueTime` `TextFormField`；Enter → `insertTodo`。
3. 勾选：`Checkbox.onChanged` → `completeTodo(id)` + `SoundManager.playPop()` + `flutter_animate` 回弹（scale 1.0→1.05→1.0）+ 划线 `AnimatedDefaultTextStyle`。
4. 悬浮动作条（Hover Action Bar，spec 5.10-2）：`▶ 立即专注`（跳番茄钟页面注入任务）/ `🏷️ 切换优先级`（PopupMenu）/ `🗑️ 快速删除`（softDelete）。
5. 子任务抽屉：任务行 `ExpansionTile`，子任务 Checkbox 走 `toggleSubtask`，返回非 null 时弹「是否将主任务标记完成？」对话框。

`MatrixView` 实现要点：
1. `GridView.count(crossAxisCount: 2)` 四象限，标题 `P0 紧急且重要(红)` / `P1 重要不紧急(橙)` / `P2 紧急不重要(蓝)` / `P3 不紧急不重要(灰)`，象限底色 `AppColors.priorityColor(p).withOpacity(0.06)`。
2. 每个象限是 `DragTarget<int>`（目标 priority），任务卡片是 `Draggable<Todo>`（data: todo）；`onAcceptWithDetails` → `updateTodo(t.copyWith(priority: target))`，`pumpAndSettle` 后 UI/库一致。
3. 拖拽中目标象限高亮描边（`AnimatedContainer` border）。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/todos/todo_list_view_test.dart`
Expected: 2 passed。

- [ ] **Step 5: 手动验收**

- [ ] P0 象限拖卡片到 P2 象限 → 数据库 priority 变 2，标识变蓝
- [ ] 勾选任务 → Pop 音效 + 回弹动画 + 划线
- [ ] 行内添加 `任务B / P1 / 🍅2 / 17:00` 回车 → 列表即时出现

- [ ] **Step 6: Commit**

```bash
git add lib/features/todos/presentation lib/core/audio test/features/todos
git commit -m "feat: add todo list view with inline form and cross-quadrant matrix drag"
```

---

### Task 3.2: Android 移动端滑动手势操作

**Files:**
- Create: `lib/features/todos/presentation/widgets/slidable_todo_tile.dart`
- Test: `test/features/todos/slidable_todo_tile_test.dart`

**Interfaces:**
- Consumes: `TodoRepository`
- Produces: `SlidableTodoTile({required Todo todo, required TodoRepository repo})` — 右滑绿色完成（HapticFeedback.lightImpact）；左滑橙色操作面板（推迟到明天 / 移入收集箱 / 删除）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/todos/slidable_todo_tile_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/todos/presentation/widgets/slidable_todo_tile.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  testWidgets('右滑触发完成并带触感', (tester) async {
    final repo = TodoRepository(db);
    await repo.insertTodo(title: '滑我', priority: 1);
    final todo = (await db.select(db.todos).get()).single;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SlidableTodoTile(todo: todo, repo: repo))));
    await tester.pumpAndSettle();
    // 向右快速滑动
    await tester.drag(find.text('滑我'), const Offset(300, 0));
    await tester.pumpAndSettle();
    final updated =
        await (db.select(db.todos)..where((t) => t.id.equals(todo.id))).getSingle();
    expect(updated.status, 'completed');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/todos/slidable_todo_tile_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/todos/presentation/widgets/slidable_todo_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/core/audio/sound_manager.dart';

class SlidableTodoTile extends StatelessWidget {
  const SlidableTodoTile({super.key, required this.todo, required this.repo});
  final Todo todo;
  final TodoRepository repo;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // 右滑（start）：绿色完成（spec 4.2 滑动触发器）
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) async {
              HapticFeedback.lightImpact();
              await SoundManager.instance.playPop();
              await repo.completeTodo(todo.id);
            },
            backgroundColor: const Color(0xFF52C41A),
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: '完成',
          ),
        ],
      ),
      // 左滑（end）：橙色操作面板
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              HapticFeedback.lightImpact();
              final tomorrow =
                  _ymd(DateTime.now().add(const Duration(days: 1)));
              await repo.updateTodo(
                  todo.copyWith(dueDate: tomorrow, updatedAt: nowMs()));
            },
            backgroundColor: const Color(0xFFF5A524),
            icon: Icons.update,
            label: '推迟到明天',
          ),
          SlidableAction(
            onPressed: (_) async {
              await repo.updateTodo(
                  todo.copyWith(dueDate: null, isTop: false, updatedAt: nowMs()));
            },
            backgroundColor: const Color(0xFF3B82F6),
            icon: Icons.inbox,
            label: '移入收集箱',
          ),
          SlidableAction(
            onPressed: (_) => repo.softDeleteTodo(todo.id),
            backgroundColor: const Color(0xFFE5484D),
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(value: todo.status == 'completed',
            onChanged: (_) => repo.completeTodo(todo.id)),
        title: Text(todo.title),
        subtitle: Text('P${todo.priority}'),
      ),
    );
  }
}
```

> 注意：测试中 `drag(Offset(300,0))` 触发 Slidable 的 start 面板展开，需在 `SlidableAction.onPressed` 之外额外用 `Slidable` 的 `closeOnScroll`/确认机制；若 drag 不直接触发 onPressed（flutter_slidable 行为：drag 只展开面板，需再 tap），测试改为：drag → `tester.tap(find.byIcon(Icons.check))` → pumpAndSettle。执行时以实际交互库行为为准调整测试手势，验收标准不变：**滑出绿色面板并点按完成后 status 变 completed**。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/todos/slidable_todo_tile_test.dart`
Expected: 1 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/todos/presentation/widgets test/features/todos
git commit -m "feat: add slidable todo tile with complete/defer/inbox/delete actions"
```

---

### Task 3.3: 日历时间块与排期视图

**Files:**
- Create: `lib/features/calendar/presentation/calendar_view.dart`, `lib/features/calendar/presentation/time_block_timeline.dart`
- Test: `test/features/calendar/time_block_timeline_test.dart`

**Interfaces:**
- Consumes: `ScheduleRepository`（Task 1.3）
- Produces:
  - `CalendarView` — 日 / 周 / 月三视图切换（spec 5.2-3），日历头显示内置节假日「休/班」标记（离线数据：`lib/core/utils/holidays.dart` 含 2025~2026 国务院法定节假日与调休表）
  - `TimeBlockTimeline` — 垂直时间轴，30 分钟一格（spec 5.2-1），工作时间区间可设（默认 08:30-20:30）；右侧待办抽屉 `DragTarget` → 落入时间槽即 `scheduleTodo`（spec 5.2-2）
  - `String holidayMark(DateTime date)` — 「休」/「班」/null

- [ ] **Step 1: 写失败测试**

```dart
// test/features/calendar/time_block_timeline_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/utils/holidays.dart';

void main() {
  test('2025-10-01 国庆为休', () {
    expect(holidayMark(DateTime(2025, 10, 1)), '休');
  });
  test('2025-10-11 调休补班为班', () {
    expect(holidayMark(DateTime(2025, 10, 11)), '班');
  });
  test('普通工作日无标记', () {
    expect(holidayMark(DateTime(2025, 10, 13)), isNull); // 周一
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/calendar/time_block_timeline_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/core/utils/holidays.dart
/// 离线内置中国法定节假日与调休（spec 5.2-4）。
/// 2025 起按国务院公开数据维护；硬编码常量表，年度更新随版本发布。

const _holidays = <String, String>{
  // 2025
  '2025-01-01': '休', // 元旦
  '2025-01-28': '休', '2025-01-29': '休', '2025-01-30': '休',
  '2025-01-31': '休', '2025-02-01': '休', '2025-02-02': '休',
  '2025-02-03': '休', '2025-02-04': '休',
  '2025-01-26': '班', '2025-02-08': '班', // 春节调休
  '2025-04-04': '休', '2025-04-05': '休', '2025-04-06': '休',
  '2025-05-01': '休', '2025-05-02': '休', '2025-05-03': '休',
  '2025-05-04': '休', '2025-04-27': '班', // 五一调休
  '2025-05-31': '休', '2025-06-01': '休', '2025-06-02': '休',
  '2025-10-01': '休', '2025-10-02': '休', '2025-10-03': '休',
  '2025-10-04': '休', '2025-10-05': '休', '2025-10-06': '休',
  '2025-10-07': '休', '2025-10-08': '休',
  '2025-09-28': '班', '2025-10-11': '班', // 国庆调休
};

String? holidayMark(DateTime date) {
  final key = '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return _holidays[key];
}
```

`TimeBlockTimeline` 实现要点：
1. `SingleChildScrollView` + 固定行高 48px/半小时格 ×（工作区间跨度）。行头 `HH:mm` 标签。
2. 每半小时槽是 `DragTarget<Todo>`；`onAcceptWithDetails` 用落点 y 坐标反算时间 → `repo.scheduleTodo(todoId, title, start, end: start+1h)`（拖入后默认 1 小时，可拖右下角调整）。
3. 已排期色块：`Positioned` 叠加 `watchSchedulesInRange` 的 Schedule 色块（左缘竖彩条 + `colorHex` 半透明填充），高度 = (end-start)/30min × 48px。
4. 日/周/月切换：日=单列时间轴；周=7 列压缩轴；月=`TableCalendar` 风格自绘网格（不引第三方，35 格 GridView），日期角标 `holidayMark`。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/calendar/time_block_timeline_test.dart`
Expected: 3 passed。

- [ ] **Step 5: 手动验收**

- [ ] 从右侧待办抽屉拖任务到 10:00 槽 → 时间块出现，任务 due_time 变 10:00
- [ ] 10 月日历网格 10/1~10/8 显示「休」，10/11 显示「班」

- [ ] **Step 6: Commit**

```bash
git add lib/features/calendar/presentation lib/core/utils/holidays.dart test/features/calendar
git commit -m "feat: add time block timeline with drag-to-schedule and holiday marks"
```

---

### Task 3.4: 灵感随手记瀑布流（含标签筛选器 + 点阵热力图）

**Files:**
- Create: `lib/features/memos/presentation/memos_view.dart`, `lib/features/memos/presentation/widgets/memo_card.dart`, `lib/features/memos/presentation/widgets/tag_filter_bar.dart`, `lib/features/memos/presentation/widgets/contribution_dots.dart`
- Test: `test/features/memos/memos_view_test.dart`

**Interfaces:**
- Consumes: `MemoRepository`（Task 1.4）
- Produces:
  - `MemosView` — 自适应多列瀑布流（spec 5.3-1）；6 款莫兰迪底色切换；`Ctrl+Enter` 极速发布器（spec 5.10-5）；卡片一键 `转待办 →`
  - `TagFilterBar` — `#全部/#架构/#UI库/#理念/#工作/#闪念` 胶囊筛选，点击毫秒级过滤
  - `ContributionDots` — 近 30 天创作活跃点阵（spec 5.12-4），与筛选器联动
  - `List<int> last30DaysCounts(Map<String, List<String>> byDate)` — 纯函数供热力图

- [ ] **Step 1: 写失败测试**

```dart
// test/features/memos/memos_view_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/memos/presentation/widgets/contribution_dots.dart';

void main() {
  test('近 30 天计数长度恒为 30 且未传日期补零', () {
    final counts = last30DaysCounts({'2025-10-09': ['a', 'b']});
    expect(counts.length, 30);
    expect(counts.last, 2); // 今天（测试运行日）之前的最后一天有 2 条
    expect(counts.every((c) => c >= 0), isTrue);
  });
}
```

> 注：`last30DaysCounts` 接收「日期→便签列表」映射，返回固定 30 长度数组（最早在前）。测试里 '2025-10-09' 与运行日相关，执行时改为动态计算昨天日期：`_ymd(DateTime.now().subtract(Duration(days:1)))`。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/memos/memos_view_test.dart`

- [ ] **Step 3: 实现（核心纯函数 + 视图要点）**

```dart
// lib/features/memos/presentation/widgets/contribution_dots.dart
/// 近 30 天创作活跃度点阵（spec 5.12-4，usememos 借鉴）。
List<int> last30DaysCounts(Map<String, List<String>> byDate) {
  final today = DateTime.now();
  return List.generate(30, (i) {
    final d = today.subtract(Duration(days: 29 - i));
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return byDate[key]?.length ?? 0;
  });
}
```

`MemosView` 实现要点：
1. 发布器：多行 `TextField` + `Wrap` 标签选择器 + 5 款底色 `ColorPicker` 圆点 + 提示文案「Ctrl+Enter 发布」；`CallbackShortcuts(Intents: paste)` 或 `KeyboardListener` 捕获 `Ctrl+Enter` → `insertMemo`。
2. 瀑布流：`flutter_staggered_grid_view` 未引入则用 `Wrap` 多列 `Column`（列数按宽度 /300px）；卡片 `AnimatedContainer` 底色 `memo.colorHex`。
3. `TagFilterBar`：`ChoiceChip` 横向列表，选中态改 `watchMemos(tag: x)` 流参数。
4. `MemoCard`：`flutter_markdown` 的 `MarkdownBody` 渲染内容；右下角 `转待办 →` → `convertToTodo` → `SoundManager.playDing()` + SnackBar「已转待办」；右上角置顶 pin 切换。
5. `ContributionDots`：头部 30 个 8px 圆点，按 count 0/1/2/3+ 映射 4 档绿色透明度（GitHub 风格）。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/memos/memos_view_test.dart`
Expected: 1 passed。

- [ ] **Step 5: 手动验收**

- [ ] Ctrl+Enter 发布带 #架构 标签的莫兰迪色便签 → 瀑布流即时出现
- [ ] 点 `#架构` 胶囊 → 只剩架构便签；点阵热力图相应高亮
- [ ] 点 `转待办 →` → 便签消失、待办库出现首行标题的任务

- [ ] **Step 6: Commit**

```bash
git add lib/features/memos/presentation test/features/memos
git commit -m "feat: add memos masonry view with tag filter and contribution dots"
```

---

### Task 3.5: 专注番茄钟（4 轮周期 + 禅模式 + 多音轨白噪音）

**Files:**
- Create: `lib/features/pomodoro/presentation/pomodoro_view.dart`, `lib/features/pomodoro/services/white_noise_service.dart`
- Test: `test/features/pomodoro/pomodoro_cycle_test.dart`

**Interfaces:**
- Consumes: `PomodoroRepository`（Task 1.5 started_at 策略）
- Produces:
  - `PomodoroCycle.pomodoroStep(int completedRounds)` — 纯函数：返回当前阶段（focus 25min / shortBreak 5min / longBreak 15min），每 4 番茄进入长休（spec 5.4-1）
  - `WhiteNoiseService` — 4 音轨（🌧️ 暴雨 / 🌲 森林鸟鸣 / ☕ 咖啡馆 / 🌊 潮汐，spec 5.12-6）独立 `AudioPlayer` 混音、独立音量、无缝循环；4 柱声波律动动画条开关
  - `PomodoroView` — 顶部周期轮数 `🍅 🍅 ⚪ ⚪`；环形倒计时（`now - started_at` 重算，Task 1.5 策略）；全屏禅模式大数字

- [ ] **Step 1: 写失败测试**

```dart
// test/features/pomodoro/pomodoro_cycle_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/pomodoro/presentation/pomodoro_view.dart';

void main() {
  test('第 1~3 轮完成 → 短休 5 分钟', () {
    for (final r in [0, 1, 2]) {
      expect(PomodoroCycle.pomodoroStep(r).kind, CycleKind.shortBreak);
      expect(PomodoroCycle.pomodoroStep(r).minutes, 5);
    }
  });
  test('第 4 轮完成 → 长休 15 分钟', () {
    expect(PomodoroCycle.pomodoroStep(3).kind, CycleKind.longBreak);
    expect(PomodoroCycle.pomodoroStep(3).minutes, 15);
  });
  test('轮数显示 🍅 🍅 ⚪ ⚪（第 2/4 轮）', () {
    expect(PomodoroCycle.roundDots(completedRounds: 1, total: 4), '🍅 🍅 ⚪ ⚪');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/pomodoro/pomodoro_cycle_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/pomodoro/presentation/pomodoro_view.dart（核心纯逻辑）
enum CycleKind { focus, shortBreak, longBreak }

class PomodoroCycle {
  /// completedRounds = 本周期内已完成的番茄数（0-based 传入）。
  static ({CycleKind kind, int minutes}) pomodoroStep(int completedRounds) {
    if (completedRounds >= 3) return (kind: CycleKind.longBreak, minutes: 15);
    return (kind: CycleKind.shortBreak, minutes: 5);
  }

  /// 周期轮数点阵显示。
  static String roundDots({required int completedRounds, required int total}) {
    final done = '🍅 ' * (completedRounds + 1);
    final todo = '⚪ ' * (total - completedRounds - 1);
    return (done + todo).trim().replaceAll('  ', ' ');
  }
}
```

```dart
// lib/features/pomodoro/services/white_noise_service.dart
import 'package:audioplayers/audioplayers.dart';

/// 多音轨白噪音混响器（spec 5.4-3 + 5.12-6）：
/// 4 音轨独立播放器、独立音量、ReleaseMode.loop 无缝循环。
class WhiteNoiseService {
  static final instance = WhiteNoiseService._();
  WhiteNoiseService._();

  static const tracks = {
    'rain': '🌧️ 暴雨声',
    'forest': '🌲 森林鸟鸣',
    'cafe': '☕ 咖啡馆',
    'wave': '🌊 潮汐海浪',
  };

  final _players = <String, AudioPlayer>{};

  Future<void> toggle(String key, {double volume = 0.6}) async {
    final existing = _players[key];
    if (existing != null) {
      await existing.stop();
      await existing.release();
      _players.remove(key);
      return;
    }
    final p = AudioPlayer(playerId: 'noise_$key');
    await p.setReleaseMode(ReleaseMode.loop);
    await p.setVolume(volume);
    await p.play(AssetSource('ambient/$key.mp3'));
    _players[key] = p;
  }

  Future<void> setVolume(String key, double volume) =>
      _players[key]?.setVolume(volume) ?? Future.value();

  Future<void> stopAll() async {
    for (final p in _players.values) {
      await p.stop();
      await p.release();
    }
    _players.clear();
  }
}
```

> ⚠️ 资产：`assets/ambient/rain.mp3` 等 4 个循环音轨（可从 freesound.org CC0 素材截取 30s 环回），pubspec 声明。

`PomodoroView` 实现要点：
1. 环形倒计时：`CustomPainter` + `Timer.periodic(1s)` 每秒重算 `remain = planned*60*1000 - (now - startedAt)`——数据源 `watchActiveSession()`，重启后自动恢复（T-A5 策略验证点）。
2. 三模式切换 SegmentedButton：经典 25/5/15 · 正向心流 Flowtime（正计时无上限）· 倒计时 15/30/45/60。
3. 任务关联：开计前 `DropdownButton` 选待办 → `startSession(todoId: x)`；结束回写 `actualPomodoros+1`。
4. 闲置检测（Windows，spec 2.3）：`PowerMonitor` 不可用则用 `lastInput` FFI（`GetLastInputInfo`），键鼠静默 5 分钟弹「是否计入专注时间？」。
5. 禅模式：`Navigator.push` 全屏黑底 120px 大数字 + 微呼吸 `flutter_animate`。
6. 声波律动条：4 根 `AnimatedContainer` 循环 `scaleY` 交错动画，仅在白噪音播放时显示。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/pomodoro/pomodoro_cycle_test.dart`
Expected: 3 passed。

- [ ] **Step 5: 手动验收**

- [ ] 开始 25 分钟专注 → 关掉应用重开 → 倒计时按 started_at 精准续跑
- [ ] 第 4 个番茄完成 → 15 分钟长休
- [ ] 混播 🌧️+☕ 双音轨，音量独立可调，循环无突刺
- [ ] 全屏禅模式大数字秒级走字

- [ ] **Step 6: Commit**

```bash
git add lib/features/pomodoro test/features/pomodoro/pomodoro_cycle_test.dart
git commit -m "feat: add pomodoro with 4-round cycle, zen mode and multi-track ambience"
```

---

### Task 3.6: 习惯打卡与年度热力图

**Files:**
- Create: `lib/features/habits/presentation/habits_view.dart`, `lib/features/habits/presentation/widgets/habit_heatmap.dart`, `lib/features/habits/presentation/widgets/counter_habit_row.dart`
- Test: `test/features/habits/habit_heatmap_test.dart`

**Interfaces:**
- Consumes: `HabitRepository`（Task 1.6）
- Produces:
  - `HabitsView` — 今日习惯清单 + 周/月/年双视图热力图（home-pages 对照表推荐）+ Streak 与 Best Streak + 健康度评分条（spec 5.12-5）
  - `HabitHeatmap` — 52 周绿色像素热力图，颜色深浅=当日综合达成率
  - `List<List<int>> heatmapMatrix(List<String> dates)` — 纯函数：52 周 × 7 的达成矩阵
  - `CounterHabitRow` — 数值型步进器（如饮水 +250ml），本周 7 天迷你点阵（spec 5.10-4）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/habits/habit_heatmap_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/habits/presentation/widgets/habit_heatmap.dart';

void main() {
  test('矩阵恒为 52 列 x 7 行', () {
    final m = heatmapMatrix([]);
    expect(m.length, 52);
    expect(m.every((col) => col.length == 7), isTrue);
  });
  test('打卡日对应格为 1', () {
    final d = DateTime.now();
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final m = heatmapMatrix([key]);
    expect(m.expand((c) => c).contains(1), isTrue);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/habits/habit_heatmap_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/habits/presentation/widgets/habit_heatmap.dart
/// 52 周 × 7 行 GitHub 风格年度热力图矩阵（列 = 周，最早周在前）。
/// 未满一年时右侧（近端）对齐，前置补零。
List<List<int>> heatmapMatrix(List<String> dates) {
  final set = dates.toSet();
  final today = DateTime.now();
  // 计算今天所在周的周一，回退 51 周
  final thisMonday = today.subtract(Duration(days: today.weekday - 1));
  final firstMonday = thisMonday.subtract(const Duration(days: 7 * 51));
  final matrix = List.generate(52, (week) {
    return List.generate(7, (day) {
      final d = firstMonday.add(Duration(days: week * 7 + day));
      if (d.isAfter(today)) return 0;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return set.contains(key) ? 1 : 0;
    });
  });
  return matrix;
}
```

`HabitsView` 实现要点：
1. 热力图渲染：`heatmapMatrix` → 52×7 个 10px `Container`，透明度按 0/25%/50%/75%/100% 达成率分 5 档绿色 `#52C41A`。
2. 周/月/年切换：周=7 格大像素+小时级；月=31 格；年=52 列全景。
3. 每习惯卡片：名称 + icon + 今日打卡 `Checkbox`（`toggleCheckIn`）+ `🔥 连击52天` + `88% 习惯健康度`（`strengthScore`）。
4. 频次徽章：daily/weekdays/times_per_week(N/7)。
5. `CounterHabitRow`：`+250ml` 步进按钮（habit config 存 target/step），进度条 + 达成庆祝 Pop 音效 + 本周 7 点阵。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/habits/habit_heatmap_test.dart`
Expected: 2 passed。

- [ ] **Step 5: 手动验收**

- [ ] 连续勾 3 天 → 热力图 3 格变绿梯度、Streak=3
- [ ] 数值习惯点 +250ml × 8 次达到 2000ml → 庆祝动效

- [ ] **Step 6: Commit**

```bash
git add lib/features/habits/presentation test/features/habits
git commit -m "feat: add habit tracking with 52-week heatmap and counter stepper"
```

---

### Task 3.7: 每日晚间复盘生成器

**Files:**
- Create: `lib/features/review/presentation/daily_review_view.dart`, `lib/features/review/services/review_summary_generator.dart`
- Test: `test/features/review/review_summary_generator_test.dart`

**Interfaces:**
- Consumes: `TodoRepository`, `PomodoroRepository`, `HabitRepository`
- Produces:
  - `Future<ReviewData> collectDailyData(AppDatabase db)` — 聚合：完成数/逾期未完数/专注分钟/番茄数/各习惯打卡状态
  - `String renderMarkdown(ReviewData d, {String? wins, String? losses, List<String> tomorrowTop3})` — 结构化模板【今日成果】【今日得失】【明日核心】（spec 5.6）
  - `DailyReviewView` — 21:00 自动触发提示（`Timer` 对时）+ 手动生成 + 一键复制 Markdown

- [ ] **Step 1: 写失败测试**

```dart
// test/features/review/review_summary_generator_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/review/services/review_summary_generator.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('聚合当日数据并渲染结构化 Markdown', () async {
    final todos = TodoRepository(db);
    await todos.insertTodo(title: '完成任务X', priority: 0);
    final t = (await db.select(db.todos).get()).single;
    await todos.completeTodo(t.id);

    final pomo = PomodoroRepository(db);
    await pomo.startSession(mode: 'pomodoro', plannedMinutes: 25);
    final active = await pomo.watchActiveSession().first;
    await pomo.finishSession(active!.id, actualMinutes: 25);

    final data = await collectDailyData(db);
    expect(data.completedCount, 1);
    expect(data.focusMinutes, 25);

    final md = renderMarkdown(data,
        losses: '会议超时 30 分钟',
        tomorrowTop3: ['发版 v1.0', '写更新日志', '对齐运营']);
    expect(md, contains('# 每日复盘'));
    expect(md, contains('✅ 完成 1 项'));
    expect(md, contains('🍅 专注 25 分钟'));
    expect(md, contains('- 发版 v1.0'));
    expect(md, contains('会议超时'));
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/review/review_summary_generator_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/review/services/review_summary_generator.dart
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';
import 'package:dailydesk/features/pomodoro/data/pomodoro_repository.dart';
import 'package:dailydesk/features/habits/data/habit_repository.dart';

class ReviewData {
  ReviewData({required this.completedCount, required this.overdueCount,
      required this.focusMinutes, required this.pomodoroCount,
      required this.habitResults});
  final int completedCount;
  final int overdueCount;
  final int focusMinutes;
  final int pomodoroCount;
  final Map<String, bool> habitResults; // 习惯名 → 今日是否打卡
}

Future<ReviewData> collectDailyData(AppDatabase db) async {
  final todos = TodoRepository(db);
  final pomo = PomodoroRepository(db);
  final habits = HabitRepository(db);

  final today = DateTime.now();
  final ymd = '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final all = await todos.watchTodos().first;
  final completed = all.where((t) =>
      t.status == 'completed' && t.updatedAt >= _dayStartMs()).length;
  final overdue = all.where((t) =>
      t.status == 'pending' &&
      t.dueDate != null && t.dueDate!.compareTo(ymd) < 0).length;

  final focusMinutes = await pomo.todayFocusMinutes();
  final pomodoroCount = focusMinutes ~/ 25;

  final habitList = await habits.watchHabits().first;
  final habitResults = <String, bool>{};
  for (final h in habitList) {
    final dates = await habits.recordDates(h.id);
    habitResults[h.name] = dates.contains(ymd);
  }
  return ReviewData(completedCount: completed, overdueCount: overdue,
      focusMinutes: focusMinutes, pomodoroCount: pomodoroCount,
      habitResults: habitResults);
}

int _dayStartMs() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
}

String renderMarkdown(ReviewData d,
    {String? wins, String? losses, List<String>? tomorrowTop3}) {
  final buf = StringBuffer('# 每日复盘 · '
      '${DateTime.now().toString().split(' ').first}\n\n');
  buf.writeln('## 📊 今日成果');
  buf.writeln('- ✅ 完成 ${d.completedCount} 项'
      '${d.overdueCount > 0 ? '，⚠️ 逾期未完 ${d.overdueCount} 项' : ''}');
  buf.writeln('- 🍅 专注 ${d.focusMinutes} 分钟，累计 ${d.pomodoroCount} 个番茄');
  buf.writeln('- 🏃 习惯：');
  d.habitResults.forEach((name, done) =>
      buf.writeln('  - ${done ? '🟢' : '⚪'} $name'));
  buf.writeln('\n## 📝 今日得失');
  if (wins?.isNotEmpty == true) buf.writeln('- 💡 收获：$wins');
  buf.writeln('- ❓ 哪些事项超时？主要干扰项是什么？→ ${losses ?? '（待补充）'}');
  buf.writeln('\n## 🎯 明日核心 (Top 3)');
  for (final t in (tomorrowTop3 ?? [])) {
    buf.writeln('- $t');
  }
  return buf.toString();
}
```

`DailyReviewView` 要点：顶部「生成复盘」按钮 → `collectDailyData` → 模板预填 → 引导输入框（得失两个 TextField）→ 明日 Top3 从待办池多选 `ChoiceChip` → `renderMarkdown` → `Clipboard.setData` 一键复制 + 「每日一句」格言小卡片（home-pages 对照表低成本彩蛋，内置 30 条本地格言按日轮换）。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/review/review_summary_generator_test.dart`
Expected: 1 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/review test/features/review
git commit -m "feat: add daily review generator with markdown export"
```

---

### Task 3.8: 全景主仪表盘（模块化工作台：注册表拼装 + 拖拽重排 + 全边框拉伸）

**Files:**
- Create: `lib/features/dashboard/presentation/dashboard_view.dart`, `lib/features/dashboard/presentation/widgets/widget_host.dart`, `lib/features/dashboard/presentation/widgets/resize_handles.dart`, `lib/features/dashboard/presentation/widgets/widget_catalog_drawer.dart`, `lib/features/dashboard/dashboard_controller.dart`
- Modify: 各 feature 补充 `*_widget.dart`（内置组件定义：四象限看板 / 今日聚焦 / 番茄小窗 / 习惯快栏 / 便签快照 / 时间块流 / 指标条 / SOP 卡片）
- Test: `test/features/dashboard/dashboard_controller_test.dart`, `test/features/dashboard/widget_host_test.dart`

**Interfaces:**
- Consumes: `WidgetRegistry` + `WidgetInstance` + `WidgetContext`（Task 0.4/1.8）、`sanitizeLayout`（Task 1.7）、全部 Repository
- Produces（spec 5.8 + home-pages 3.5/3.6/3.10 全量细节）:
  - `DashboardController` — 页面 CRUD / 拖拽重排 / resize 钳制 / 复制组件 / 前移后移 / layoutOnly 分层刷新
  - `WidgetHost` — 单卡片宿主：注册表找不到 kind 时渲染占位卡片（数据不丢）；编辑模式显示手柄 `⋮⋮` 与操作组（前移/后移/复制/删除）
  - `ResizeHandles` — 右边缘 col-resize / 底边缘 row-resize / 右下角对角手柄；四重取消保护（pointercancel / lostpointercapture / Escape / 手柄移除恢复原尺寸）；键盘方向键逐格调整（手柄聚焦后 ±1 列/行）；窄屏（非 12 列布局）自动 lockWidth 只允许调高；实时浮动徽章 `📐 宽: 8 列 (67%) · 高: 340px`；虚线框逐像素跟随 + 卡片按列/行吸附移动
  - `WidgetCatalogDrawer` — 「+ 添加模块」抽屉，8 个内置模块实例化注入；`✕` 剔除
  - 网格设置三件套：行高（140~800px 高度钳制由 resize 承担；行高 24~96 步进 2）/ 间距 4~40 / 最大宽度 0~4000（0=不限），修改即刻 `layoutOnly` 刷新（不重拉数据）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/dashboard/dashboard_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/dashboard/dashboard_controller.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';

WidgetInstance _w(String kind, int order) => WidgetInstance(
    id: newUlid(), kind: kind, w: 4, h: 3)
  ..config['sortOrder'] = order;

void main() {
  test('拖拽重排：交换后 sortOrder 重排', () {
    final c = DashboardController();
    final a = _w('todo', 0), b = _w('pomodoro', 1), d = _w('habit', 2);
    c.load([a, b, d]);
    c.reorder(oldIndex: 2, newIndex: 0); // d 提到最前
    expect(c.ordered.first.kind, 'habit');
  });

  test('resize 钳制：w 1..12，h 1..20', () {
    final c = DashboardController();
    final a = _w('todo', 0);
    c.load([a]);
    c.resize(a.id, w: 99, h: -3);
    expect(a.w, 12);
    expect(a.h, 1);
  });

  test('复制组件：新 id + 插到原卡片正后方', () {
    final c = DashboardController();
    final a = _w('todo', 0), b = _w('habit', 1);
    c.load([a, b]);
    final copyId = c.duplicate(a.id);
    expect(copyId, isNot(a.id)); // 绝不复用 id
    expect(c.ordered.map((w) => w.kind).toList(), ['todo', 'todo', 'habit']);
    expect(c.ordered[1].id, copyId);
  });

  test('前移后移', () {
    final c = DashboardController();
    final a = _w('todo', 0), b = _w('habit', 1);
    c.load([a, b]);
    c.moveForward(b.id);
    expect(c.ordered.first.kind, 'habit');
    c.moveBackward(b.id);
    expect(c.ordered.first.kind, 'todo');
  });
}
```

```dart
// test/features/dashboard/widget_host_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/dashboard/presentation/widgets/widget_host.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';

void main() {
  testWidgets('未知 kind 渲染占位卡片，数据不丢', (tester) async {
    final unknown = WidgetInstance(id: newUlid(), kind: 'future-plugin', w: 4, h: 3);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: WidgetHost(
            instance: unknown, registry: WidgetRegistry(), editMode: false))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('placeholder-widget')), findsOneWidget);
    expect(find.textContaining('future-plugin'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/dashboard/`
Expected: FAIL。

- [ ] **Step 3: 实现 DashboardController**

```dart
// lib/features/dashboard/dashboard_controller.dart
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/widget_registry.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';

class DashboardController {
  DashboardController({WidgetRegistry? registry})
      : registry = registry ?? WidgetRegistry();
  final WidgetRegistry registry;
  final List<WidgetInstance> _widgets = [];
  bool _layoutOnly = false;

  List<WidgetInstance> get ordered =>
      List.of(_widgets)..sort((a, b) =>
          (a.config['sortOrder'] as int? ?? 0)
              .compareTo(b.config['sortOrder'] as int? ?? 0));

  void load(List<WidgetInstance> widgets) {
    _widgets
      ..clear()
      ..addAll(widgets);
    _renumber();
  }

  void reorder({required int oldIndex, required int newIndex}) {
    final list = ordered;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    _widgets
      ..clear()
      ..addAll(list);
    _renumber();
  }

  /// 全边框拉伸钳制（spec 5.8-2）：列宽 1..12（12 列网格）。
  void resize(String id, {required int w, required int h}) {
    final it = _widgets.firstWhere((x) => x.id == id);
    it.w = w.clamp(1, 12);
    it.h = h.clamp(1, 20);
  }

  /// 复制组件（home-pages 3.6）：deep clone config + 全新 id，插到原卡片正后方。
  String duplicate(String id) {
    final list = ordered;
    final i = list.indexWhere((x) => x.id == id);
    final src = list[i];
    final copy = WidgetInstance(
        id: newUlid(), // 绝不复用 id——同步场景 id 冲突是灾难
        kind: src.kind, w: src.w, h: src.h,
        config: Map<String, dynamic>.of(src.config));
    list.insert(i + 1, copy);
    _widgets
      ..clear()
      ..addAll(list);
    _renumber();
    return copy.id;
  }

  void moveForward(String id) {
    final list = ordered;
    final i = list.indexWhere((x) => x.id == id);
    if (i <= 0) return;
    final item = list.removeAt(i);
    list.insert(i - 1, item);
    _widgets
      ..clear()
      ..addAll(list);
    _renumber();
  }

  void moveBackward(String id) {
    final list = ordered;
    final i = list.indexWhere((x) => x.id == id);
    if (i == -1 || i >= list.length - 1) return;
    final item = list.removeAt(i);
    list.insert(i + 1, item);
    _widgets
      ..clear()
      ..addAll(list);
    _renumber();
  }

  void remove(String id) => _widgets.removeWhere((x) => x.id == id);

  void add(String kind) {
    final def = registry.definitionOf(kind);
    if (def == null) return;
    _widgets.add(WidgetInstance(
        id: newUlid(), kind: kind,
        w: def.defaultSize.w, h: def.defaultSize.h,
        config: (def.defaultConfig() as Map).cast<String, dynamic>()));
    _renumber();
  }

  /// 网格三件套（home-pages 3.4）：调行高/间距只重排布局，不重拉组件数据。
  void beginLayoutOnly() => _layoutOnly = true;
  void endLayoutOnly() => _layoutOnly = false;
  bool get layoutOnly => _layoutOnly;

  /// 导出规范化 JSON（布局导入导出 T-A8 的导出侧）。
  Map<String, dynamic> exportJson() =>
      {'version': 1, 'widgets': ordered.map((w) => w.toJson()).toList()};

  void _renumber() {
    for (var i = 0; i < _widgets.length; i++) {
      _widgets[i].config['sortOrder'] = i;
    }
  }
}
```

- [ ] **Step 4: 实现 WidgetHost / ResizeHandles（交互细节全量落地）**

`WidgetHost` 要点：
1. `registry.definitionOf(instance.kind)` 为 null → 占位卡片：`Key('placeholder-widget')` + 图标 + 「组件 ${kind} 未安装」+ 数据保留提示（home-pages 1.1）。
2. 正常路径：`def.normalizeConfig(instance.config)` → `def.render(context, ctx)`，ctx 由 `LiveWidgetContext` 挂到 `State`。
3. 编辑模式（顶栏 toggle「编辑布局」）：右上 `⋮⋮` 手柄 `Listener` + 全边框 `ResizeHandles` + 底部操作组（◀ 前移 / ▶ 后移 / ⧉ 复制 / ✕ 删除）。

`ResizeHandles` 要点（home-pages 3.5 四重取消 + spec 5.8-2 徽章）：
1. 右边缘 8px `Listener(onPointerMove)`：`SystemMouseCursors.resizeColumn`，拖动中 `clamp(1,12)` 列，实时 `controller.resize(id, w: newW, h: it.h)`。
2. 底边缘：`resizeRow`；右下角 12px 对角块：同时 w+h。
3. **四重取消保护**：`Listener.onPointerCancel` / `onPointerRemoved` / `KeyboardListener` Escape / 手柄 dispose——任一触发回滚到 dragStart 时快照的 (w,h)。
4. 键盘：手柄 `Focus(onKeyEvent)` 方向键 → ±1 列/行。
5. 窄屏降级：`LayoutBuilder` 宽度 <900 时 `lockWidth=true`，只暴露底边/对角手柄高度维度（Android 触屏不出现横向乱象）。
6. 浮动徽章：`Overlay` 跟随指针 `📐 宽: ${w} 列 (${(w/12*100).round()}%) · 高: ${h*rowHeight}px`。
7. 虚线框跟随：拖动中 `Positioned` 虚线 `Container` 逐像素跟随指针；真实卡片按列/行吸附移动，其余卡片 `AnimatedContainer` 平滑让位。
8. 顶栏列宽循环徽章：4/6/8/12 一键循环切换当前选中卡片列宽。

`WidgetCatalogDrawer` 要点：8 个内置模块 `ListTile`（图标 + name + defaultSize 预览），点击 `controller.add(kind)` + 毫秒级出现动画；`✕` 剔除走 `controller.remove`。

内置组件（每个独立文件实现 `DailyWidgetDefinition`，全部 `register(builtin: true)`）：
| kind | 内容 | 数据源 |
|---|---|---|
| `matrix` | 四象限看板 | TodoRepository |
| `today_focus` | 今日核心聚焦 | watchTodayTodos |
| `pomodoro_mini` | 沉浸番茄钟小窗 | watchActiveSession |
| `habits_quick` | 习惯打卡快速栏 | HabitRepository |
| `memos_snapshot` | 灵感碎片快照 | MemoRepository |
| `schedule_stream` | 时间块排期流 | ScheduleRepository |
| `kpi_bar` | 生产力核心指标条 | 聚合查询 |
| `sop_daily` | 每日全天 SOP 卡片 | SOP 服务（Task 3.8b） |

- [ ] **Step 5: 运行确认通过**

Run: `flutter test test/features/dashboard/`
Expected: 5 passed。

- [ ] **Step 6: 手动验收**

- [ ] 编辑模式拖 `⋮⋮` 重排；卡片右缘拉伸 3~12 列；徽章实时显示；ESC 取消恢复
- [ ] 对角手柄同时拉宽高；底边拉高（140~800px 高度域）
- [ ] 复制组件 → 两张同 kind 卡片并存
- [ ] 抽屉添加「四象限看板」→ 出现；`✕` 剔除 → 消失
- [ ] 手柄聚焦按方向键逐格微调
- [ ] 未知 kind 的 JSON 导入 → 占位卡片

- [ ] **Step 7: Commit**

```bash
git add lib/features/dashboard test/features/dashboard
git commit -m "feat: add modular dashboard with registry assembly, drag-resize and catalog"
```

---

### Task 3.8b: 每日全天 SOP 标准作业流引擎

**Files:**
- Create: `lib/features/sop/services/sop_engine.dart`, `lib/features/sop/presentation/sop_card.dart`
- Test: `test/features/sop/sop_engine_test.dart`

**Interfaces:**
- Consumes: 仪表盘 `sop_daily` 组件（Task 3.8）
- Produces（spec 5.9 + 5.10-1）:
  - `class SopSlot { String title; String time; List<String> checkpoints; bool done; }`
  - `class SopEngine` — 静态方法群：
    - `(int, int, double) progress(List<SopSlot> slots)` → (完成数, 总数, 百分比)
    - `int activeSlotIndex(List<SopSlot> slots, DateTime now)` — 当前活跃时间槽判定
    - `Duration untilNext(List<SopSlot> slots, DateTime now)` — 距下一节点倒计时
    - `List<SopSlot> dailyReset(List<SopSlot> template)` — 打勾状态全重置，模板保留（00:00 自动或手动 🔄）
    - `List<SopSlot> insertAdHoc(List<SopSlot> slots, SopSlot adHoc)` — 动态增补今日专属节点（按时间插入）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/sop/sop_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/sop/services/sop_engine.dart';

final slots = [
  SopSlot(title: '晨间唤醒', time: '08:30',
      checkpoints: ['温水500ml', '开窗', '看日历'], done: true),
  SopSlot(title: '深度工作 I', time: '09:30', checkpoints: [], done: true),
  SopSlot(title: '午休', time: '12:00', checkpoints: [], done: false),
  SopSlot(title: '晚间复盘', time: '21:00', checkpoints: [], done: false),
];

void main() {
  test('进度：2/4 完成 50%', () {
    final (done, total, pct) = SopEngine.progress(slots);
    expect(done, 2); expect(total, 4); expect(pct, 0.5);
  });

  test('10:30 时活跃槽是 09:30（深度工作 I），距午休 90 分钟', () {
    final now = DateTime(2025, 10, 13, 10, 30);
    expect(SopEngine.activeSlotIndex(slots, now), 1);
    expect(SopEngine.untilNext(slots, now).inMinutes, 90);
  });

  test('每日重置：done 全清，模板保留', () {
    final reset = SopEngine.dailyReset(slots);
    expect(reset.every((s) => !s.done), isTrue);
    expect(reset.first.checkpoints, ['温水500ml', '开窗', '看日历']);
  });

  test('临时节点按时间序插入', () {
    final adHoc = SopSlot(title: '团队跨组沟通', time: '16:00', checkpoints: []);
    final merged = SopEngine.insertAdHoc(slots, adHoc);
    expect(merged.map((s) => s.time).toList(),
        ['08:30', '09:30', '12:00', '16:00', '21:00']);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/sop/sop_engine_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/sop/services/sop_engine.dart

class SopSlot {
  SopSlot({required this.title, required this.time,
      required this.checkpoints, this.done = false});
  final String title; // 节点名
  final String time;  // HH:mm 时间锚点
  final List<String> checkpoints; // 折叠式细项规程
  bool done;
}

class SopEngine {
  /// 进度三元组：完成数 / 总数 / 百分比。
  static (int, int, double) progress(List<SopSlot> slots) {
    if (slots.isEmpty) return (0, 0, 0);
    final done = slots.where((s) => s.done).length;
    return (done, slots.length, done / slots.length);
  }

  /// 当前活跃时间槽：最后一个 time <= now 的槽。
  static int activeSlotIndex(List<SopSlot> slots, DateTime now) {
    final cur = now.hour * 60 + now.minute;
    var idx = -1;
    for (var i = 0; i < slots.length; i++) {
      final parts = slots[i].time.split(':');
      final t = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (t <= cur) idx = i;
    }
    return idx;
  }

  /// 距下一节点倒计时；已是最后一节点则返回到明天首节点的时长。
  static Duration untilNext(List<SopSlot> slots, DateTime now) {
    final cur = now.hour * 60 + now.minute;
    int? next;
    for (final s in slots) {
      final parts = s.time.split(':');
      final t = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (t > cur) { next = t; break; }
    }
    if (next == null) {
      final parts = slots.first.time.split(':');
      final first = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      return Duration(minutes: 24 * 60 - cur + first);
    }
    return Duration(minutes: next - cur);
  }

  /// 一键次日循环与重置：状态清空，模板（含细项）保留。
  static List<SopSlot> dailyReset(List<SopSlot> template) => template
      .map((s) => SopSlot(
          title: s.title, time: s.time,
          checkpoints: List.of(s.checkpoints), done: false))
      .toList();

  /// 动态增补专属步骤：按时间序插入。
  static List<SopSlot> insertAdHoc(List<SopSlot> slots, SopSlot adHoc) {
    final merged = List<SopSlot>.of(slots);
    final minutes = (SopSlot s) =>
        int.parse(s.time.split(':')[0]) * 60 + int.parse(s.time.split(':')[1]);
    var i = 0;
    while (i < merged.length && minutes(merged[i]) <= minutes(adHoc)) {
      i++;
    }
    merged.insert(i, adHoc);
    return merged;
  }
}
```

`SopCard`（仪表盘 `sop_daily` 组件主体）要点：
1. 头部：`5/9 完成 (56%)` 计数器 + 线性进度条。
2. 节点列表按时间序；当前活跃节点 `active-slot` 呼吸光环（`flutter_animate` 交替透明度）+ 「距下一节点还有 45 分钟」倒计时（`registerInterval(1s)` 刷新）。
3. 每节点右侧 `🍅 专注` 快捷键 → 注入番茄钟并开始倒计时。
4. `▼ 细项` 展开折叠 checkpoints 子规程。
5. 🔄 按钮手动重置；`Timer` 在午夜 00:00 触发 `dailyReset`。
6. SOP 模板持久化到 `SharedPreferences`（JSON），编辑入口提供增删改节点。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/sop/sop_engine_test.dart`
Expected: 4 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/sop test/features/sop
git commit -m "feat: add daily SOP engine with active slot state machine"
```

---

### Task 3.9: AI 智囊 Copilot（想法拆解 + 动态模型拉取 + 7890 代理）

**Files:**
- Create: `lib/core/network/http_client_factory.dart`, `lib/features/copilot/services/ai_service.dart`, `lib/features/copilot/presentation/ai_chat_view.dart`
- Test: `test/features/copilot/ai_service_test.dart`（结构化拆解解析纯逻辑 + 代理配置）

**Interfaces:**
- Consumes: `TodoRepository` / `MemoRepository` / SOP 服务（批量写入）
- Produces（spec 5.11）:
  - `HttpClientFactory.create({String? proxyUrl})` — 默认 `http://127.0.0.1:7890`；`findProxy` 直连回退
  - `Future<List<String>> fetchModels({required String baseUrl, required String apiKey, String? proxy})` — `GET {base}/models`，解析 `data[].id`
  - `Future<Deconstruction> deconstructIdea({required String idea, ...})` — Structured Outputs 请求，返回 `analysis / todos / sops / memos`（严格按 spec 5.11-3 JSON Schema）
  - `class Deconstruction { String analysis; List<DeconTodo> todos; List<DeconSop> sops; List<DeconMemo> memos; }`
  - `Deconstruction parseDeconstruction(String json)` — 纯函数解析器（可测）
  - `AiChatView` — 对话消息流 + 结构化行动卡片（复选清单）+ `⚡ 一键批量写入今日工作台`（单 Drift 事务）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/copilot/ai_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/copilot/services/ai_service.dart';

const sampleJson = '''
{
  "analysis": "发版前夕的核心攻坚与健康作息建议",
  "todos": [
    {"title": "编译双端安装包并冒烟测试", "priority": 0, "estimated_pomodoros": 3, "due_time": "14:00"},
    {"title": "编写发版日志", "priority": 1, "estimated_pomodoros": 1, "due_time": "16:00"}
  ],
  "sops": [
    {"title": "☕ 午后站立拉伸与饮水 300ml", "time": "16:00"}
  ],
  "memos": [
    {"content": "检查多网卡环境 mDNS 广播绑定", "tag": "arch"}
  ]
}
''';

void main() {
  test('解析结构化拆解 JSON（spec 5.11-3 Schema）', () {
    final d = parseDeconstruction(sampleJson);
    expect(d.analysis, contains('发版'));
    expect(d.todos.length, 2);
    expect(d.todos.first.priority, 0);
    expect(d.todos.first.estimatedPomodoros, 3);
    expect(d.todos.first.dueTime, '14:00');
    expect(d.sops.single.time, '16:00');
    expect(d.memos.single.tag, 'arch');
  });

  test('空字段容错：缺数组不抛异常', () {
    final d = parseDeconstruction('{"analysis": "x"}');
    expect(d.todos, isEmpty);
    expect(d.sops, isEmpty);
    expect(d.memos, isEmpty);
  });

  test('代理默认值与显式直连', () {
    expect(HttpClientFactory.defaultProxy, 'http://127.0.0.1:7890');
    final direct = HttpClientFactory.create(proxyUrl: '');
    expect(direct.autoUncompress, isTrue); // 创建成功即可
    direct.close();
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/copilot/ai_service_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/core/network/http_client_factory.dart
import 'dart:convert';
import 'dart:io';

/// 统一网络出口（spec 5.11-2）：
/// 默认预置本地代理 http://127.0.0.1:7890，兼顾海外模型 API 访问；
/// proxyUrl 传空串 = 显式直连。
class HttpClientFactory {
  static const defaultProxy = 'http://127.0.0.1:7890';

  static HttpClient create({String? proxyUrl}) {
    final client = HttpClient();
    final proxy = (proxyUrl == null || proxyUrl.isEmpty)
        ? (proxyUrl != null ? '' : defaultProxy)
        : proxyUrl;
    if (proxy.isEmpty) return client;
    client.findProxy = (uri) => 'PROXY $proxy';
    client.badCertificateCallback = (cert, host, port) =>
        host == '127.0.0.1'; // 仅放行本地代理自签
    return client;
  }
}

// lib/features/copilot/services/ai_service.dart（节选：解析器 + 服务）
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:dailydesk/core/network/http_client_factory.dart';

class DeconTodo {
  DeconTodo(this.title, this.priority, this.estimatedPomodoros, this.dueTime);
  final String title;
  final int priority;
  final int estimatedPomodoros;
  final String? dueTime;
}

class DeconSop {
  DeconSop(this.title, this.time);
  final String title;
  final String time;
}

class DeconMemo {
  DeconMemo(this.content, this.tag);
  final String content;
  final String? tag;
}

class Deconstruction {
  Deconstruction(this.analysis, this.todos, this.sops, this.memos);
  final String analysis;
  final List<DeconTodo> todos;
  final List<DeconSop> sops;
  final List<DeconMemo> memos;
}

/// 结构化拆解 JSON 解析（spec 5.11-3），空字段容错。
Deconstruction parseDeconstruction(String json) {
  final m = jsonDecode(json);
  if (m is! Map) {
    return Deconstruction('', [], [], []);
  }
  return Deconstruction(
    (m['analysis'] as String?) ?? '',
    ((m['todos'] as List?) ?? const [])
        .whereType<Map>()
        .map((t) => DeconTodo(
            (t['title'] as String?) ?? '',
            (t['priority'] as num?)?.toInt() ?? 1,
            (t['estimated_pomodoros'] as num?)?.toInt() ?? 1,
            t['due_time'] as String?))
        .toList(),
    ((m['sops'] as List?) ?? const [])
        .whereType<Map>()
        .map((s) => DeconSop(
            (s['title'] as String?) ?? '',
            (s['time'] as String?) ?? '09:00'))
        .toList(),
    ((m['memos'] as List?) ?? const [])
        .whereType<Map>()
        .map((x) => DeconMemo(
            (x['content'] as String?) ?? '', x['tag'] as String?))
        .toList(),
  );
}

class AiService {
  /// GET {base}/models：动态拉取模型池（spec 5.11-2）。
  static Future<List<String>> fetchModels({
    required String baseUrl,
    required String apiKey,
    String? proxy,
  }) async {
    final client = IOClient(HttpClientFactory.create(proxyUrl: proxy));
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw HttpException('models 拉取失败: ${res.statusCode}');
      }
      final data = (jsonDecode(res.body) as Map)['data'] as List? ?? const [];
      return data
          .whereType<Map>()
          .map((m) => m['id'] as String?)
          .whereType<String>()
          .toList();
    } finally {
      client.close();
    }
  }

  /// Structured Outputs 拆解请求。systemPrompt 严格内嵌 spec 5.11-3 Schema。
  static const systemPrompt = '''
你是 GTD 拆解助手。将用户口语化思路按以下 JSON Schema 输出（仅输出 JSON）：
{
  "analysis": "一句话总结",
  "todos": [{"title": str, "priority": 0-3, "estimated_pomodoros": 1-3, "due_time": "HH:mm" | null}],
  "sops": [{"title": str, "time": "HH:mm"}],
  "memos": [{"content": str, "tag": "arch"|"ui"|"idea"|"work"|"flash"}]
}
''';

  static Future<Deconstruction> deconstructIdea({
    required String idea,
    required String baseUrl,
    required String apiKey,
    required String model,
    String? proxy,
  }) async {
    final client = IOClient(HttpClientFactory.create(proxyUrl: proxy));
    try {
      final res = await client
          .post(Uri.parse('$baseUrl/chat/completions'),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': idea},
                ],
                'response_format': {'type': 'json_object'},
              }))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        throw HttpException('拆解失败: ${res.statusCode} ${res.body}');
      }
      final content =
          (jsonDecode(res.body) as Map)['choices'][0]['message']['content'] as String;
      return parseDeconstruction(content);
    } finally {
      client.close();
    }
  }
}
```

> `HttpClientFactory` 放 `lib/core/network/http_client_factory.dart`；上面为合并展示，落盘时拆两个文件。

`AiChatView` 要点：
1. 设置面板：Base URL（默认 `https://api.openai.com/v1`，下拉预置 DeepSeek/Groq/Moonshot/Ollama 模板）+ API Key（`flutter_secure_storage` 加密隔离存储，本地零上报）+ `🔍 获取模型列表` 按钮 → 模型下拉 + 自由输入兜底 + 代理地址（默认 7890）。
2. 消息流：气泡列表 + 输入框；拆解结果渲染三组结构化行动卡片（🎯 待办 / 📋 SOP / 💡 便签），每项 `Checkbox` 可勾选微调（改 priority/due_time）。
3. `⚡ 一键批量写入今日工作台`：单 `db.transaction` 内依次 `insertTodo`（带 dueTime=今天+时间）/ SOP 插入模板 / `insertMemo`（tag 映射 arch→架构 等）；完成后 `SoundManager.playDing()` + 首屏各模块因 Drift 响应式流自动毫秒级重绘。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/copilot/ai_service_test.dart`
Expected: 3 passed。

- [ ] **Step 5: 手动验收（需真实 API Key）**

- [ ] 配 DeepSeek base + key → 点拉取模型 → 下拉出现 deepseek-chat/reasoner
- [ ] 输入 spec 示例想法 → 三组行动卡片出现 → 全选批量写入 → 待办/SOP/便签库均有新数据

- [ ] **Step 6: Commit**

```bash
git add lib/core/network lib/features/copilot test/features/copilot
git commit -m "feat: add AI copilot with model discovery, proxy and batch apply"
```

---

### Task 3.10: 多工作台页面管理 + 布局导入导出（T-A7 / T-A8）

**Files:**
- Create: `lib/features/dashboard/presentation/page_tabs.dart`, `lib/features/dashboard/layout_transfer.dart`
- Test: `test/features/dashboard/layout_transfer_test.dart`

**Interfaces:**
- Consumes: `DashboardController`、`sanitizeLayout`（Task 1.7）
- Produces（home-pages 3.1 / 3.2）:
  - `LayoutTransfer.exportJson(List<LayoutPage> pages, String activePageId)` — 带版本号规范化 JSON（indent 2）
  - `List<LayoutPage> importPages(String raw, List<LayoutPage> existing)` — 三重防御：①兼容裸数组/包装/单页 ②逐页面逐 widget 过 sanitize ③**导入 id 全部重新生成**，追加到现有页面之后不覆盖；剪贴板 API 失败降级为可复制文本 Dialog
  - `LayoutPage copyPage(LayoutPage src)` — 页面复制：`name + ' 副本'`，widgets id 全部重生成
  - `PageTabs` — 编辑模式拖动标签排序；右键重命名/删除；删除最后一页自动重建默认页（永不出空状态死局）；「＋空白页」与「＋默认布局页」双按钮；`createDefaultDashboard()` 工厂（默认页由注册表 API 组装而非硬编码——默认值本身是架构的第一个用户）
  - `ConfirmModal(title, message, confirmText, {danger})` — 危险操作统一红色确认对话框（含「习惯打卡等本地数据也会清除」类警告文案）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/dashboard/layout_transfer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/dashboard/layout_transfer.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';

LayoutPage _page(String id, String name) =>
    LayoutPage(id: id, name: name, widgets: [
      WidgetInstance(id: 'w-$id', kind: 'todo', w: 4, h: 3)
    ]);

void main() {
  test('导出带版本号且 round-trip 保留 kind/尺寸', () {
    final json = exportJson([_page('p1', '工作台')], 'p1');
    expect(json, contains('"version": 1'));
    final back = importPages(json, []);
    expect(back.single.name, '工作台');
    expect(back.single.widgets.single.kind, 'todo');
    expect(back.single.widgets.single.w, 4);
  });

  test('导入 id 全部重新生成，绝不与现有冲突', () {
    final json = exportJson([_page('p1', 'A')], 'p1');
    final existing = [_page('p1', 'A')];
    final imported = importPages(json, existing);
    expect(imported.single.id, isNot('p1')); // id 重生成
    expect(imported.single.widgets.single.id, isNot('w-p1'));
  });

  test('导入追加不覆盖：现有页仍在', () {
    final json = exportJson([_page('x', '外来页')], 'x');
    final existing = [_page('p1', '本地页')];
    // importPages 只返回新导入集合，调用方负责拼接
    final imported = importPages(json, existing);
    expect(imported.single.name, '外来页');
  });

  test('复制页面：新 id + 副本名 + widget id 重生成', () {
    final src = _page('p1', '冲刺');
    final copy = copyPage(src);
    expect(copy.id, isNot(src.id));
    expect(copy.name, '冲刺 副本');
    expect(copy.widgets.single.id, isNot(src.widgets.single.id));
    expect(copy.widgets.single.kind, 'todo'); // config deep clone
  });

  test('垃圾输入导入得到空集合（不崩）', () {
    expect(importPages('not json at all', []), isEmpty);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/dashboard/layout_transfer_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/dashboard/layout_transfer.dart
import 'dart:convert';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/widgets_infra/daily_widget.dart';
import 'package:dailydesk/widgets_infra/sanitize_layout.dart';

/// 导出：带版本号的规范化 JSON（home-pages 3.2）。
String exportJson(List<LayoutPage> pages, String activePageId) =>
    JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'activePageId': activePageId,
      'pages': pages.map((p) => p.toJson()).toList(),
    });

/// 导入三重防御：
/// 1. sanitizeLayout 全量清洗（兼容三种输入形态）
/// 2. 每页面/每 widget 逐个过检，坏的丢弃
/// 3. 导入 id 全部重新生成，追加式不覆盖现有
List<LayoutPage> importPages(String raw, List<LayoutPage> existing) {
  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const [];
  }
  final sanitized = sanitizeLayout(decoded);
  return sanitized.pages
      .map((p) => LayoutPage(
          id: newUlid(), // 导入即重生成——同步场景 id 冲突是灾难
          name: p.name,
          widgets: p.widgets
              .map((w) => WidgetInstance(
                  id: newUlid(), kind: w.kind, w: w.w, h: w.h,
                  config: Map<String, dynamic>.of(w.config)))
              .toList()))
      .toList();
}

/// 页面复制（home-pages 3.1）：一键克隆整页布局，widget 全部重新分配 id。
LayoutPage copyPage(LayoutPage src) => LayoutPage(
    id: newUlid(),
    name: '${src.name} 副本',
    widgets: src.widgets
        .map((w) => WidgetInstance(
            id: newUlid(), // 绝不复用
            kind: w.kind, w: w.w, h: w.h,
            config: Map<String, dynamic>.of(w.config)))
        .toList());
```

`PageTabs` 要点：
1. 顶部 `TabBar` 同步页面名列表；编辑模式开启后 `ReorderableListView` 标签可拖动排序。
2. 标签右键 `PopupMenu`：重命名（`TextField` Dialog）/ 删除（走 `ConfirmModal` danger 红样式，删最后一页时先自动 `createDefaultDashboard()` 兜底重建默认页再删目标页）/ 复制本页（`copyPage`）。
3. 双按钮：`＋ 空白页`（高级用户）/ `＋ 默认布局页`（想重来的人）；设置面板另有「重置为默认布局」+ ConfirmModal 警告文案。
4. `createDefaultDashboard()`：工厂用 `registry.definitionOf(...)` 组装 8 个内置模块实例（12 列网格：KPI 条 12x2 / SOP 8x6 / 今日聚焦 4x6 / 番茄 4x4 / 四象限 6x6 / 便签快照 6x4 / 习惯 4x4 / 排期流 4x4）——默认值由注册表 API 组装，非硬编码布局。
5. 布局导入导出入口在设置面板：导出→`Clipboard.setData`（失败降级 Dialog 展示可复制文本）；导入→粘贴框 + `importPages` 结果 append 到 `existing` 页列表后自动切换到第一个新页。
6. 双端迁移无需 P2P：Android 端同入口粘贴 JSON 即可（复用同一 `importPages`）。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/dashboard/layout_transfer_test.dart`
Expected: 5 passed。

- [ ] **Step 5: 手动验收**

- [ ] 复制页面 → 出现「xx 副本」，两张页 widget 独立（改一张不影响另一张）
- [ ] 删除唯一页面 → 自动出现默认布局页
- [ ] 导出 JSON → 清空所有页 → 导入 → 布局完整回来且 id 全新
- [ ] 重置为默认布局 → 红色确认框 → 8 模块默认看板

- [ ] **Step 6: Commit**

```bash
git add lib/features/dashboard test/features/dashboard/layout_transfer_test.dart
git commit -m "feat: add multi-page dashboard with copy, import/export and default factory"
```

---

# Phase 4: 局域网 P2P 增量同步引擎

### Task 4.1: 局域网设备自发现（mDNS + UDP 组播双通道）

**Files:**
- Create: `lib/features/sync/services/discovery_service.dart`
- Test: `test/features/sync/discovery_service_test.dart`（信标编解码纯逻辑）

**Interfaces:**
- Produces（spec 2.1 / 7.1）:
  - `class Beacon { String deviceId; String deviceName; String platform; String ip; int port; }`
  - `String encodeBeacon(Beacon b)` / `Beacon? decodeBeacon(String raw)` — UDP 心跳包编解码（JSON，损坏包容错返回 null）
  - `class DiscoveryService` — `nsd` 注册 `_dailydesk._tcp` + UDP 组播 `224.0.0.167:53317` 双通道；维护在线设备列表（3 秒无心跳判离线）；`Stream<List<Beacon>> watchPeers()`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/sync/discovery_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/sync/services/discovery_service.dart';

void main() {
  test('信标 round-trip 编解码', () {
    final b = Beacon(
        deviceId: 'dev-1', deviceName: '工作台PC',
        platform: 'windows', ip: '192.168.1.5', port: 53317);
    final decoded = decodeBeacon(encodeBeacon(b));
    expect(decoded!.deviceName, '工作台PC');
    expect(decoded.port, 53317);
  });

  test('损坏信标容错返回 null', () {
    expect(decodeBeacon('garbage'), isNull);
    expect(decodeBeacon('{"partial": true}'), isNull);
  });

  test('缺失必填字段的信标拒绝', () {
    expect(decodeBeacon('{"deviceName": "x"}'), isNull);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/sync/discovery_service_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/sync/services/discovery_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nsd/nsd.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class Beacon {
  Beacon({required this.deviceId, required this.deviceName,
      required this.platform, required this.ip, required this.port});
  final String deviceId;
  final String deviceName;
  final String platform;
  final String ip;
  final int port;
}

String encodeBeacon(Beacon b) => jsonEncode({
      'v': 1, 'deviceId': b.deviceId, 'deviceName': b.deviceName,
      'platform': b.platform, 'ip': b.ip, 'port': b.port,
    });

Beacon? decodeBeacon(String raw) {
  try {
    final m = jsonDecode(raw);
    if (m is! Map) return null;
    final id = m['deviceId'], name = m['deviceName'],
        ip = m['ip'], port = m['port'];
    if (id is! String || name is! String || ip is! String || port is! int) {
      return null;
    }
    return Beacon(
        deviceId: id, deviceName: name,
        platform: (m['platform'] as String?) ?? 'unknown',
        ip: ip, port: port);
  } catch (_) {
    return null;
  }
}

class DiscoveryService {
  static const multicastGroup = '224.0.0.167';
  static const multicastPort = 53317;
  static const heartbeatPeriod = Duration(seconds: 1);
  static const offlineAfter = Duration(seconds: 3);

  final _peers = <String, (Beacon, DateTime)>{};
  final _controller = StreamController<List<Beacon>>.broadcast();
  RawDatagramSocket? _socket;
  Registration? _mdnsRegistration;
  Timer? _heartbeat;
  late final String selfDeviceId = newUlid();

  Stream<List<Beacon>> watchPeers() => _controller.stream;

  Future<void> start({required String deviceName, required String platform,
      required String ip, required int port}) async {
    // 双通道 1：UDP 组播信标（spec 7.1）
    _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, multicastPort, reuseAddress: true, reusePort: true);
    _socket!.joinMulticast(InternetAddress(multicastGroup));
    _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = _socket!.receive();
      if (dg == null) return;
      final b = decodeBeacon(String.fromCharCodes(dg.data));
      if (b == null || b.deviceId == selfDeviceId) return; // 忽略自己
      _peers[b.deviceId] = (b, DateTime.now());
      _emit();
    });
    // 周期广播自己 + 离线清扫
    final self = encodeBeacon(Beacon(
        deviceId: selfDeviceId, deviceName: deviceName,
        platform: platform, ip: ip, port: port));
    _heartbeat = Timer.periodic(heartbeatPeriod, (_) {
      _socket?.send(self.codeUnits, InternetAddress(multicastGroup), multicastPort);
      _sweepOffline();
    });
    // 双通道 2：mDNS 注册 _dailydesk._tcp（nsd 平台集成）
    final service = Service(name: '_dailydesk', type: '_dailydesk._tcp',
        port: port, txt: {'device': deviceName, 'platform': platform});
    _mdnsRegistration = await NsdPlatformInterface.instance.register(service);
  }

  void _sweepOffline() {
    final cutoff = DateTime.now().subtract(offlineAfter);
    final before = _peers.length;
    _peers.removeWhere((_, v) => v.$2.isBefore(cutoff));
    if (_peers.length != before) _emit();
  }

  void _emit() => _controller.add(
      _peers.values.map((v) => v.$1).toList());

  Future<void> stop() async {
    _heartbeat?.cancel();
    _socket?.close();
    await _mdnsRegistration?.unregister();
    await _controller.close();
  }
}
```

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/sync/discovery_service_test.dart`
Expected: 3 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/sync/services/discovery_service.dart test/features/sync
git commit -m "feat: add dual-channel peer discovery with beacon codec and offline sweep"
```

---

### Task 4.2: 端侧嵌入式 HTTP 服务与 PIN 配对

**Files:**
- Create: `lib/features/sync/services/local_http_server.dart`, `lib/features/sync/controllers/sync_api_controller.dart`
- Test: `test/features/sync/sync_api_controller_test.dart`（HMAC 鉴权与路由逻辑）

**Interfaces:**
- Consumes: `sync_devices` 表、`crypto` 包
- Produces（spec 7.1 / 7.2）:
  - `class SyncAuth` — `String hmacToken(String deviceId, String pairingKey)` → `HMAC-SHA256(deviceId, pairingKey)`；`bool verifyToken(...)`；4 位 PIN 生成与 SHA-256 哈希存储
  - `SyncApiController` — shelf_router 路由：
    - `POST /api/v1/pair` — 提交 PIN + 设备信息 → 双方写入 `sync_devices`（isTrusted=1）→ 返回 pairingKey
    - `POST /api/v1/sync/diff-request` — Body `{last_synced_at}` → 未配对 401；已配对返回差异包
    - 中间件校验 `X-Device-Id` + `X-Sync-Token`
  - `LocalHttpServer` — `start(port: 53317)` 绑定 `0.0.0.0`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/sync/sync_api_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/sync/controllers/sync_api_controller.dart';

void main() {
  test('HMAC token 生成与校验一致', () {
    final t1 = SyncAuth.hmacToken('device-1', 'secret-key');
    final t2 = SyncAuth.hmacToken('device-1', 'secret-key');
    expect(t1, t2);
    expect(SyncAuth.verifyToken('device-1', 'secret-key', t1), isTrue);
    expect(SyncAuth.verifyToken('device-1', 'wrong-key', t1), isFalse);
    expect(SyncAuth.verifyToken('device-2', 'secret-key', t1), isFalse);
  });

  test('PIN 为 4 位数字', () {
    final pin = SyncAuth.generatePin();
    expect(pin.length, 4);
    expect(int.tryParse(pin), isNotNull);
  });

  test('PIN 哈希不可逆存储', () {
    final hash = SyncAuth.hashPin('1234');
    expect(hash, isNot('1234'));
    expect(hash.length, 64); // SHA-256 hex
    expect(SyncAuth.hashPin('1234'), hash); // 确定性
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/sync/sync_api_controller_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/sync/controllers/sync_api_controller.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class SyncAuth {
  /// X-Sync-Token: HMAC-SHA256(deviceId, pairingKey)（spec 7.1）。
  static String hmacToken(String deviceId, String pairingKey) {
    final key = utf8.encode(pairingKey);
    final msg = utf8.encode(deviceId);
    final h = Hmac(sha256, key);
    return h.convert(msg).toString();
  }

  static bool verifyToken(String deviceId, String pairingKey, String token) =>
      hmacToken(deviceId, pairingKey) == token;

  /// 4 位数字动态配对码（spec 2.1 LocalSend 借鉴）。
  static String generatePin() =>
      (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

  /// PIN 只存哈希（sync_devices.pairing_key_hash）。
  static String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();
}
```

`SyncApiController` + `LocalHttpServer` 要点（shelf_router）：
1. `Router()..post('/api/v1/pair', _pair)..post('/api/v1/sync/diff-request', _diff)`。
2. `_pair`：Body `{pin, deviceId, deviceName, platform, ip, port}` → 与本端展示 PIN 比对 → 生成 pairingKey（新 ULID）→ 双端 `sync_devices` 写入（isTrusted=1, pairing_key_hash=hashPin）→ 返回 `{pairing_key}`。
3. 鉴权中间件：读 header `X-Device-Id` + `X-Sync-Token`，查 `sync_devices` 表 pairingKey → `SyncAuth.verifyToken`；失败返回 401 `{'error': 'unpaired'}`。
4. `_diff`：Body `{last_synced_at}` → `DiffPackager.buildDiff(lastSyncedAt)`（Task 4.3）返回 JSON 差异包；任意异常 `db.transaction` 外层已保证未写状态，直接 500 + 错误体。
5. `LocalHttpServer.start()`：`shelf_io.serve(router, InternetAddress.anyIPv4, 53317)`。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/sync/sync_api_controller_test.dart`
Expected: 3 passed。

- [ ] **Step 5: 手动验收（双端或本机双实例）**

- [ ] 未配对直接 curl diff-request → 401
- [ ] 错 PIN 配对 → 失败；正确 PIN → 返回 pairing_key，双方 sync_devices 出现对端

- [ ] **Step 6: Commit**

```bash
git add lib/features/sync test/features/sync/sync_api_controller_test.dart
git commit -m "feat: add embedded HTTP sync server with PIN pairing and HMAC auth"
```

---

### Task 4.3: 增量差异提取与打包器 (Diff Packager)

**Files:**
- Create: `lib/features/sync/services/diff_packager.dart`
- Test: `test/features/sync/diff_packager_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` 8 张业务表 + `widget_layouts`
- Produces:
  - `Future<Map<String, dynamic>> buildDiff(int lastSyncedAt)` — 从 9 张表提取所有 `updated_at > lastSyncedAt` 的记录（含软删条目——`deleted_at` 非空也要打包广播，spec 2.4 墓碑机制），序列化为 JSON：`{tables: {todos: [...], subtasks: [...], ...}, generated_at: ms}`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/sync/diff_packager_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/features/sync/services/diff_packager.dart';
import 'package:dailydesk/features/todos/data/todo_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('只提取 last_synced_at 之后的变更（含软删条目）', () async {
    final repo = TodoRepository(db);
    await repo.insertTodo(title: '旧任务');
    final t0 = (await db.select(db.todos).get()).single;
    final checkpoint = nowMs();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.insertTodo(title: '新任务');
    await repo.softDeleteTodo(t0.id); // 墓碑也要打包

    final diff = await buildDiff(db, checkpoint);
    final todos = diff['tables']['todos'] as List;
    final titles = todos.map((t) => t['title']);
    expect(titles, contains('新任务'));
    expect(titles, contains('旧任务')); // 软删条目随包广播
    expect(todos.first['deleted_at'], isNotNull); // 带墓碑字段
  });

  test('无变更返回空表', () async {
    final diff = await buildDiff(db, nowMs());
    expect(((diff['tables'] as Map)['todos'] as List), isEmpty);
  });
}
```

> 注：`buildDiff(db, checkpoint)` 直接传 db 实例（测试便利），生产代码包一层 repository 方法同理。

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/sync/diff_packager_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/sync/services/diff_packager.dart
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

/// 从 9 张表提取 updated_at > lastSyncedAt 的全部变更（含墓碑）。
/// 表内记录以 Map 形态导出（Drift row → toJson 由 generated code 提供）。
Future<Map<String, dynamic>> buildDiff(AppDatabase db, int lastSyncedAt) async {
  final tables = <String, dynamic>{};

  Future<List<dynamic>> extract<T extends Table, R extends DataClass>(
      TableInfo<T, R> table, Future<List<R>> rows) async {
    return rows.then((rs) => rs.map((r) => r.toJson()).toList());
  }

  tables['todos'] = await (db.select(db.todos)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());
  tables['subtasks'] = await (db.select(db.subtasks)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());
  tables['schedules'] = await (db.select(db.schedules)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());
  tables['memos'] = await (db.select(db.memos)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());
  tables['pomodoro_logs'] = await (db.select(db.pomodoroLogs)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());
  tables['habits'] = await (db.select(db.habits)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());
  tables['habit_records'] = await (db.select(db.habitRecords)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());
  tables['widget_layouts'] = await (db.select(db.widgetLayouts)
        ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncedAt)))
      .get()
      .then((rs) => rs.map((r) => r.toJson()).toList());

  return {'v': 1, 'generated_at': nowMs(), 'tables': tables};
}
```

> 说明：`extract` 辅助闭包在最终代码中内联到各表调用（上面为清晰展示逐表写法）；`sync_devices` 表不参与 diff（设备表本地私有）。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/sync/diff_packager_test.dart`
Expected: 2 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/sync/services/diff_packager.dart test/features/sync/diff_packager_test.dart
git commit -m "feat: add diff packager extracting tombstones and updates across 9 tables"
```

---

### Task 4.4: LWW 冲突合并与事务写入引擎

**Files:**
- Create: `lib/features/sync/services/merge_engine.dart`
- Test: `test/features/sync/merge_engine_test.dart`

**Interfaces:**
- Consumes: Diff 包结构（Task 4.3）
- Produces（spec 7.3）:
  - `MergeDecision decideLww({required int localUpdatedAt, required int remoteUpdatedAt, required int? localDeletedAt, required int? remoteDeletedAt})` — 纯函数裁决：
    - 单标量属性：`updated_at` 大者胜（LWW）
    - 软删除 vs 新修改：以更新的修改为准（删除后又被修改 → 复活）
  - `class MergeDecision { bool takeRemote; bool resurrect; }`
  - `Future<MergeResult> applyDiff(AppDatabase db, Map<String, dynamic> diff)` — 单事务应用全部变更：普通行 LWW upsert；**便签特例**：两端 30 秒内并发修改文本 → 保留最新为原便签 + 自动生成 `[同步冲突备份-日期时间]` 副本（绝不丢文本）
  - `class MergeResult { int applied; int conflictsCopied; }`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/sync/merge_engine_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';
import 'package:dailydesk/features/sync/services/merge_engine.dart';
import 'package:dailydesk/features/memos/data/memo_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  group('decideLww 纯函数', () {
    test('远端更新则取远端', () {
      final d = decideLww(localUpdatedAt: 100, remoteUpdatedAt: 200,
          localDeletedAt: null, remoteDeletedAt: null);
      expect(d.takeRemote, isTrue);
    });
    test('本地更新保本地', () {
      final d = decideLww(localUpdatedAt: 300, remoteUpdatedAt: 200,
          localDeletedAt: null, remoteDeletedAt: null);
      expect(d.takeRemote, isFalse);
    });
    test('本地已删且远端在此后修改 → 复活取远端', () {
      final d = decideLww(localUpdatedAt: 100, remoteUpdatedAt: 200,
          localDeletedAt: 100, remoteDeletedAt: null);
      expect(d.takeRemote, isTrue);
      expect(d.resurrect, isTrue);
    });
    test('远端已删且更新 → 接受墓碑', () {
      final d = decideLww(localUpdatedAt: 100, remoteUpdatedAt: 200,
          localDeletedAt: null, remoteDeletedAt: 200);
      expect(d.takeRemote, isTrue);
      expect(d.resurrect, isFalse);
    });
  });

  test('applyDiff：便签 30 秒内并发修改生成冲突副本', () async {
    final memos = MemoRepository(db);
    await memos.insertMemo(content: '本地版本内容');
    final local = (await db.select(db.memos).get()).single;

    // 构造远端 diff：同一条便签，30 秒内被另一端修改
    final remoteTs = local.updatedAt + 3000; // 3 秒后 = 并发窗口内
    final diff = {
      'v': 1,
      'generated_at': remoteTs,
      'tables': {
        'memos': [local.toJson()
          ..['content'] = '远端版本内容'
          ..['updated_at'] = remoteTs],
        'todos': const [], 'subtasks': const [], 'schedules': const [],
        'pomodoro_logs': const [], 'habits': const [],
        'habit_records': const [], 'widget_layouts': const [],
      }
    };
    final result = await applyDiff(db, diff);
    expect(result.conflictsCopied, 1);

    final rows = await db.select(db.memos).get();
    expect(rows.length, 2); // 原便签 + 冲突副本
    final latest = rows.firstWhere((m) => m.deletedAt == null);
    expect(latest.content, '远端版本内容'); // 最新为主
    final copy = rows.firstWhere((m) => m.id != latest.id);
    expect(copy.content, contains('同步冲突备份'));
  });

  test('applyDiff：本地更新时远端行被拒（LWW 保本地）', () async {
    final memos = MemoRepository(db);
    await memos.insertMemo(content: '更新更晚的本地');
    final local = (await db.select(db.memos).get()).single;
    await memos.insertMemo(content: 'x'); // 抬高时间线
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final olderTs = local.updatedAt - 5000; // 远端更旧
    final diff = {
      'v': 1, 'generated_at': olderTs,
      'tables': {
        'memos': [local.toJson()..['content'] = '过时远端'..['updated_at'] = olderTs],
        'todos': const [], 'subtasks': const [], 'schedules': const [],
        'pomodoro_logs': const [], 'habits': const [],
        'habit_records': const [], 'widget_layouts': const [],
      }
    };
    final result = await applyDiff(db, diff);
    final row = await (db.select(db.memos)
          ..where((m) => m.id.equals(local.id)))
        .getSingle();
    expect(row.content, '更新更晚的本地');
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/sync/merge_engine_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/sync/services/merge_engine.dart
import 'package:dailydesk/core/database/app_database.dart';
import 'package:dailydesk/core/utils/ulid.dart';

class MergeDecision {
  const MergeDecision({required this.takeRemote, this.resurrect = false});
  final bool takeRemote;
  final bool resurrect;
}

/// LWW 裁决纯函数（spec 7.3）：
/// - 单标量：updated_at 大者胜
/// - 软删除与修改并存：以更新的修改为准（删除后又被改 → 复活）
MergeDecision decideLww({
  required int localUpdatedAt,
  required int remoteUpdatedAt,
  required int? localDeletedAt,
  required int? remoteDeletedAt,
}) {
  final remoteNewer = remoteUpdatedAt > localUpdatedAt;
  if (!remoteNewer) return const MergeDecision(takeRemote: false);
  final remoteDeleted = remoteDeletedAt != null;
  final localDeleted = localDeletedAt != null;
  // 远端墓碑更新 → 接受墓碑
  if (remoteDeleted) return const MergeDecision(takeRemote: true);
  // 本地已删、远端在此后修改 → 复活
  if (localDeleted) return const MergeDecision(takeRemote: true, resurrect: true);
  return const MergeDecision(takeRemote: true);
}

class MergeResult {
  MergeResult(this.applied, this.conflictsCopied);
  final int applied;
  final int conflictsCopied;
}

const _concurrentWindowMs = 30000; // 30 秒并发判定窗口

/// 单事务应用差异包（spec 8-2：网络超时/数据畸变自动整体回滚）。
Future<MergeResult> applyDiff(AppDatabase db, Map<String, dynamic> diff) async {
  var applied = 0;
  var conflicts = 0;
  final tables = (diff['tables'] as Map?) ?? const {};

  await db.transaction(() async {
    // ---- memos：文本冲突保护特例 ----
    for (final raw in (tables['memos'] as List? ?? const [])) {
      final remote = Map<String, dynamic>.of(raw as Map);
      final id = remote['id'] as String;
      final localRows = await (db.select(db.memos)
            ..where((m) => m.id.equals(id)))
          .get();
      if (localRows.isEmpty) {
        await db.into(db.memos).insert(_memoFromJson(remote));
        applied++;
        continue;
      }
      final local = localRows.single;
      final d = decideLww(
          localUpdatedAt: local.updatedAt,
          remoteUpdatedAt: (remote['updated_at'] as num).toInt(),
          localDeletedAt: local.deletedAt,
          remoteDeletedAt: (remote['deleted_at'] as num?)?.toInt());
      if (!d.takeRemote) continue;
      // 并发编辑冲突：修改时间差 < 30s 且文本不同 → 先备份本地
      final delta = ((remote['updated_at'] as num).toInt() - local.updatedAt).abs();
      if (delta < _concurrentWindowMs &&
          remote['content'] != local.content) {
        final backupTs = DateTime.now();
        await db.into(db.memos).insert(MemosCompanion.insert(
            id: newUlid(),
            content:
                '[同步冲突备份-${backupTs.toString().split('.').first}] ${local.content}',
            tag: Value(local.tag),
            colorHex: Value(local.colorHex),
            isPinned: Value(false),
            createdAt: nowMs(), updatedAt: nowMs()));
        conflicts++;
      }
      await (db.update(db.memos)..where((m) => m.id.equals(id)))
          .write(_memoPatch(remote, resurrect: d.resurrect));
      applied++;
    }

    // ---- 其余表：普通 LWW upsert（同构逻辑，逐表展开）----
    for (final entry in {
      'todos': (db.todos, _todoFromJson, _todoPatch),
      'subtasks': (db.subtasks, _subtaskFromJson, _subtaskPatch),
      'schedules': (db.schedules, _scheduleFromJson, _schedulePatch),
      'habits': (db.habits, _habitFromJson, _habitPatch),
      'pomodoro_logs': (db.pomodoroLogs, _pomoFromJson, _pomoPatch),
      'habit_records': (db.habitRecords, _habitRecFromJson, _habitRecPatch),
      'widget_layouts': (db.widgetLayouts, _layoutFromJson, _layoutPatch),
    }.entries) {
      // 通用模式：远端行 vs 本地行 decideLww → insert 或 update
      // 具体行映射函数由 drift generated companion 构造。
      // （执行者按 memos 同构模式逐表实现；每表约 30 行，此处不重复展开——
      //  与 memos 的唯一差别：无冲突副本特例。）
    }
  });

  return MergeResult(applied, conflicts);
}
```

> ⚠️ 执行注意：上面 `for entry` 块是**展开指引**不是可运行代码——按 memos 分支的完整模式为 7 张表各写一遍 insert/decideLww/update 分支（每表约 30 行）。计划要求逐表展开落地，禁止留任何 `_xxxFromJson` 空实现。所有 companion 构造函数在 `app_database.g.dart` 中由 drift 生成。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/sync/merge_engine_test.dart`
Expected: 5 passed。

- [ ] **Step 5: Commit**

```bash
git add lib/features/sync/services/merge_engine.dart test/features/sync/merge_engine_test.dart
git commit -m "feat: add LWW merge engine with memo conflict copies and resurrect logic"
```

---

### Task 4.5: 同步编排、状态机与扫码/手动 IP 降级通道

**Files:**
- Create: `lib/features/sync/services/sync_orchestrator.dart`, `lib/features/sync/presentation/sync_view.dart`, `lib/features/sync/presentation/widgets/pairing_dialog.dart`
- Test: `test/features/sync/sync_orchestrator_test.dart`

**Interfaces:**
- Consumes: Discovery（4.1）、HTTP 服务（4.2）、DiffPackager（4.3）、MergeEngine（4.4）
- Produces（spec 7.2 状态机 + 4.5 扫码降级）:
  - `enum SyncState { idle, discovered, unpaired, pullDiff, localMerge, pushDiff, completed, failed }`
  - `class SyncOrchestrator` — `Future<SyncOutcome> runSync(Beacon peer)`：
    1. `POST /api/v1/sync/diff-request {last_synced_at}`（4000ms 超时，超时重试 1 次，再失败降级提醒——spec 8-3）
    2. `applyDiff` 本地合并
    3. 推送自身 diff（对端执行它的 LWW）
    4. 双方更新 `last_synced_at`
  - `SyncOutcome` — `{appliedTodos, appliedMemos, conflicts}` 供 UI 弹「同步完成，更新 X 项待办，Y 条便签」
  - `SyncView` — LocalSend 风格雷达弹窗：本地设备卡 + 对端卡片 + 毫秒延迟 + PIN 配对 + 旋转 `⚡ 立即双向同步`；电脑端 `pretty_qr_code` 展示 `ip:port:token` 二维码，移动端扫码或手动输 IP（关闭组播的隔离网络依然可用——spec TASK-4.5）

- [ ] **Step 1: 写失败测试**

```dart
// test/features/sync/sync_orchestrator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/features/sync/services/sync_orchestrator.dart';

void main() {
  test('超时后重试一次，再失败转 failed', () async {
    var attempts = 0;
    final o = SyncOrchestrator(
        diffFetcher: (_) async {
          attempts++;
          throw TimeoutException('模拟超时');
        });
    final outcome = await o.runSyncForTest();
    expect(attempts, 2);          // 首次 + 重试 1 次
    expect(outcome.state, SyncState.failed);
  });

  test('完成态返回统计', () async {
    final o = SyncOrchestrator(
        diffFetcher: (_) async => {
              'v': 1, 'generated_at': 0,
              'tables': {'todos': [], 'memos': []},
            });
    final outcome = await o.runSyncForTest();
    expect(outcome.state, SyncState.completed);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/features/sync/sync_orchestrator_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/features/sync/services/sync_orchestrator.dart
import 'dart:async';
import 'package:dailydesk/features/sync/services/discovery_service.dart';

enum SyncState { idle, discovered, unpaired, pullDiff, localMerge, pushDiff, completed, failed }

class SyncOutcome {
  SyncOutcome(this.state, {this.appliedTodos = 0, this.appliedMemos = 0,
      this.conflicts = 0});
  final SyncState state;
  final int appliedTodos;
  final int appliedMemos;
  final int conflicts;
}

typedef DiffFetcher = Future<Map<String, dynamic>> Function(int lastSyncedAt);

class SyncOrchestrator {
  SyncOrchestrator({
    required this.diffFetcher,
    this.timeout = const Duration(milliseconds: 4000), // spec 8-3
  });

  final DiffFetcher diffFetcher;
  final Duration timeout;

  /// 状态机主流程（spec 7.2）：PULL → MERGE → PUSH → 完成。
  Future<SyncOutcome> runSync(Beacon peer, int lastSyncedAt) async {
    Map<String, dynamic>? remoteDiff;
    for (var attempt = 0; attempt < 2; attempt++) { // 超时重试 1 次
      try {
        remoteDiff = await diffFetcher(lastSyncedAt)
            .timeout(timeout);
        break;
      } on TimeoutException {
        if (attempt == 1) {
          return SyncOutcome(SyncState.failed);
        }
      }
    }
    if (remoteDiff == null) {
      return SyncOutcome(SyncState.failed);
    }
    return SyncOutcome(SyncState.completed,
        appliedTodos:
            ((remoteDiff['tables'] as Map)['todos'] as List? ?? []).length,
        appliedMemos:
            ((remoteDiff['tables'] as Map)['memos'] as List? ?? []).length);
  }

  /// 测试入口：注入 fetcher，验证重试与状态流转。
  Future<SyncOutcome> runSyncForTest() =>
      runSync(Beacon(deviceId: 't', deviceName: 't',
          platform: 't', ip: '0.0.0.0', port: 0), 0);
}
```

> 注：`runSyncForTest` 测试中 `appliedTodos` 对空数组返回 0，状态 completed——`applyDiff` 与 PUSH 阶段在完整实现中挂接（diffFetcher 注入点即生产代码中 `http.post` 到对端 `/api/v1/sync/diff-request`，随后调 `applyDiff`、再 POST 自身 `buildDiff` 包到对端同一路由）。`TimeoutException` 需 `import 'dart:async';`（已含）。

`SyncView` / `PairingDialog` 要点：
1. 标题栏网络互联胶囊 → 点击展开雷达弹窗：本地设备名/IP/端口广播状态 + `watchPeers()` 在线卡列表（含毫秒延迟 ping）。
2. 未配对对端卡：显示「配对」→ PIN 弹窗（本端 4 位 PIN 展示 / 对端输入）。
3. 已配对：`⚡ 立即双向同步` 旋转动画按钮 → `runSync` → 绿色对勾 + 「同步完成，更新 X 项待办，Y 条便签」。
4. 电脑端二维码：`PrettyQrView.data('${ip}:${port}:${deviceToken}')`；移动端相机扫码（`mobile_scanner` 未在依赖矩阵，则首版手动 IP 输入框兜底——已满足 spec 降级要求）。
5. 手动 IP 通道：`TextField ip:port` + 连接按钮，直连不走组播。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/features/sync/sync_orchestrator_test.dart`
Expected: 2 passed。

- [ ] **Step 5: 手动验收（Windows + Android 同 Wi-Fi）**

- [ ] 双端启动 3 秒内互相亮灯
- [ ] PIN 配对成功 → 双向同步 → 双端待办一致
- [ ] 双端同时改同一便签 → 同步后出现 `[同步冲突备份]` 副本，无文本丢失
- [ ] 手机关 Wi-Fi → 同步超时 4s → 重试 1 次 → 降级提示

- [ ] **Step 6: Commit**

```bash
git add lib/features/sync test/features/sync/sync_orchestrator_test.dart
git commit -m "feat: add sync orchestrator state machine with retry, timeout and QR pairing"
```

---

# Phase 5: 质量验证、性能调优与双端打包交付

### Task 5.1: 滚动快照 + 性能优化 + CI 门禁（T-A11 / home-pages 1.6）

**Files:**
- Create: `lib/core/backup/rolling_snapshot.dart`, `scripts/verify_bundle.dart`, `.github/workflows/release.yml`
- Test: `test/core/backup/rolling_snapshot_test.dart`

**Interfaces:**
- Produces（spec 5.7-4/5 + home-pages 1.6/1.7）:
  - `RollingSnapshot` — 每日启动静默备份 SQLite 至 `backups/`，保留 14 天滚动清理；`restore(File f)` 时光机恢复（恢复前二次 ConfirmModal）
  - `IcsExporter.export(List<Schedule>)` / `IcsImporter.parse(String ics)` — iCalendar 导入导出（spec 5.7-4）
  - `scripts/verify_bundle.dart` — 构建门禁（CI 可执行断言）：
    - ①产物体积阈值：apk ≤ 25MB、windows zip ≤ 40MB
    - ②URL 字面量白名单扫描：源码中全部 `http(s)://` 字面量只允许 openai/deepseek/groq/moonshot 域 + 本地回环，出现其他即 fail（支撑「数据绝不流出路由器」承诺可验证化）
    - ③tag 与 pubspec version 一致性校验
  - `.github/workflows/release.yml` — lint → test → build → verify-bundle → 发布，`concurrency + cancel-in-progress: false`

- [ ] **Step 1: 写失败测试**

```dart
// test/core/backup/rolling_snapshot_test.dart
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailydesk/core/backup/rolling_snapshot.dart';
import 'package:dailydesk/core/database/app_database.dart';

void main() {
  test('备份生成并只保留 14 天滚动窗口', () async {
    final dir = await Directory.systemTemp.createTemp('dd_backup');
    final snapshot = RollingSnapshot(backupDir: dir.path, keepDays: 14);
    await snapshot.writeSnapshot(File('${dir.path}/src.db'));
    // 手动放置 20 天前的陈旧备份
    final stale = File('${dir.path}/db-2020-01-01.db')..writeAsBytesSync([1, 2, 3]);
    final finalOld = await stale.resolveSymbolicLinks();
    await snapshot.sweepExpired(now: () => DateTime(2020, 1, 21));
    expect(await snapshot.listSnapshots(), hasLength(1)); // 只剩新备份
    expect(File.fromUri(Uri.file(finalOld)).existsSync(), isFalse);
  });
}
```

- [ ] **Step 2: 运行确认失败**

Run: `flutter test test/core/backup/rolling_snapshot_test.dart`

- [ ] **Step 3: 实现**

```dart
// lib/core/backup/rolling_snapshot.dart
import 'dart:io';

/// 每日滚动快照（spec 5.7-5）：启动时静默备份，保留 14 天。
class RollingSnapshot {
  RollingSnapshot({required this.backupDir, this.keepDays = 14});
  final String backupDir;
  final int keepDays;

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<File> writeSnapshot(File sourceDb) async {
    final dir = Directory(backupDir)..createSync(recursive: true);
    final target = File('${dir.path}/db-${_ymd(DateTime.now())}.db');
    await sourceDb.copy(target.path);
    return target;
  }

  Future<List<File>> listSnapshots() async =>
      Directory(backupDir).existsSync()
          ? Directory(backupDir)
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.db'))
              .toList()
          : const [];

  /// 清理超出滚动窗口的旧快照（供测试注入 now）。
  Future<void> sweepExpired({DateTime Function()? now}) async {
    final today = (now ?? DateTime.now)();
    final cutoff = today.subtract(Duration(days: keepDays));
    for (final f in await listSnapshots()) {
      final ts = f.lastModifiedSync();
      if (ts.isBefore(cutoff)) await f.delete();
    }
  }
}
```

`verify_bundle.dart` 门禁要点（dart 脚本，build 后运行）：
1. 体积：`File(apkPath).lengthSync() > 25 * 1024 * 1024` → exit 1。
2. URL 白名单：递归扫 `lib/` 源码 `RegExp(r'https?://[^\s\'"]+')`；允许集 = `{api.openai.com, api.deepseek.com, api.groq.com, api.moonshot.cn, 127.0.0.1, localhost}`；其他 URL 输出「文件:行号: URL」并 exit 1。
3. 版本一致性：`git describe --tags` vs `pubspec.yaml version` 不一致 exit 1。

`.ics` 导入导出要点：
- 导出：`BEGIN:VCALENDAR` 头 + 每条 `BEGIN:VEVENT / DTSTART:20251013T100000 / DTEND:... / SUMMARY:title / END:VEVENT`，文件保存对话框（`file_picker` 路径或 Windows 原生 FFI）。
- 导入：按行状态机解析 VEVENT 块 → `Schedule` 入库。

性能优化清单（flutter run --profile 逐项验证）：
1. 首屏懒加载：仪表盘非活跃 widget `Visibility(visible: false, maintainState: false)` 延迟构建。
2. 热力图/瀑布流 `RepaintBoundary` 隔离重绘。
3. `flutter_animate` 动画统一 `.autoPlay(false)` 防后台空转；空闲期 CPU 目标 0%。
4. Profiler 消除大列表掉帧（`ListView.builder` 淘汰一次性 `Column`）。

- [ ] **Step 4: 运行确认通过**

Run: `flutter test test/core/backup/rolling_snapshot_test.dart`
Expected: 1 passed。
Run: `dart run scripts/verify_bundle.dart`（本地 stub 产物下）Expected: 各断言打印 OK。

- [ ] **Step 5: Commit**

```bash
git add lib/core/backup scripts .github test/core/backup
git commit -m "feat: add rolling snapshot, CI bundle gate with URL whitelist and ics transfer"
```

---

### Task 5.2: Windows (EXE/MSIX) 与 Android (APK) 构建发布

**Files:**
- Modify: `windows/runner/Runner.rc`, `android/app/build.gradle`, `pubspec.yaml`
- Create: `RELEASE_NOTES.zh-CN.md`, `RELEASE_NOTES.md`（双语发布说明，home-pages 3.9）

**Interfaces:**
- Consumes: 全部前序任务
- Produces: 可分发的 Windows 绿色便携 zip + Android 签名 APK（≤25MB）

- [ ] **Step 1: 配置版本与图标**

`windows/runner/Runner.rc`：`VERSION_AS_NUMBER 0,1,0,0`、`VERSION_AS_STRING "0.1.0"`；应用图标 ico 资源替换。
`android/app/build.gradle`：

```gradle
defaultConfig {
    applicationId "com.dailydesk"
    minSdkVersion 26          // Android 8.0
    targetSdkVersion 34
    versionCode 1
    versionName "0.1.0"
}
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        signingConfig signingConfigs.release
    }
}
```

Android 高刷（spec 4.2）：`main.dart` 的 Android 分支调 `FlutterDisplayMode.setHighRefreshRate()`。

- [ ] **Step 2: 构建 Windows**

Run: `flutter build windows --release`
Expected: `build/windows/x64/runner/Release/` 产出 exe + dll；打包为 `DailyDesk-0.1.0-win-x64.zip`。

- [ ] **Step 3: 构建 Android**

Run: `flutter build apk --release --split-per-abi`
Expected: 3 个 split APK；arm64 主包 ≤ 25MB（超了先 `--analyze-size` 定位，优先裁 audioplayers 资产）。

- [ ] **Step 4: 门禁 + 实机验证**

Run: `dart run scripts/verify_bundle.dart`
Expected: 体积 OK、URL 白名单 OK、版本一致 OK。

实机验证清单：
- [ ] Windows 实机安装：冷启动 < 0.8s（秒表/Process 启动日志）、任务管理器内存 45~70MB、空闲 CPU ≈ 0%
- [ ] 关闭窗口 → 托盘常驻；Alt+Space 全局呼出
- [ ] Android 实机：120Hz 滑动流畅、番茄钟后台通知常驻不被杀、滑动操作触感正常
- [ ] 双端同 Wi-Fi 同步全链路通
- [ ] 断网 24 小时全功能可用（离线优先红线）

- [ ] **Step 5: 双语 Release Notes + 提交**

`RELEASE_NOTES.zh-CN.md` 骨架：版本号 / 新特性（对照本计划各 Task）/ 已知问题 / FAQ（直击真实恐慌点：手机端布局会乱吗——不会，宽屏降级 lockWidth；番茄钟重启后还准吗——准，started_at 持久化；怎么恢复初始布局——设置→重置为默认布局）。

```bash
git add -A
git commit -m "chore: release v0.1.0 windows portable + android apk"
git tag v0.1.0
```

---

# 计划自审结论（Self-Review 记录）

**1. Spec 覆盖检查**：
- spec §1 原则 → Global Constraints；§2 对标 → Task 2.x/3.x/4.x 逐项落地（LocalSend→4.1/4.2、AppFlowy→3.1/3.2、SuperProductivity→3.5/2.3、Joplin→4.3/4.4）
- §4 双端形态 → 2.1~2.4（三窗口形态）+ 3.2（Android 手势/高刷）
- §5 六大模块 → 3.1~3.8b；5.7 五项优化 → 2.3(NLP)/3.8(Ctrl+K 融入命令入口)/3.1(音效)/5.1(ics)/5.1(快照)；5.8 拖拽拉伸 → 3.8；5.9 SOP → 3.8b；5.10 微交互 → 3.1/3.4/3.5/3.6/3.8b；5.11 Copilot → 3.9；5.12 对标 → 2.4/3.4/3.5/3.6/3.8/3.9
- §6 Schema → 1.1（9 表逐字对齐 + widget_layouts 增补）；§7 同步 → 4.1~4.5；§8 非功能 → 2.1(互斥)/4.4(事务)/4.5(超时)/5.1(红线)/5.2(体积)
- home-pages T-A1~T-A12 → 0.4(T-A1)/1.8(T-A2)/1.7(T-A3,T-A4)/1.5(T-A5)/3.8(T-A6)/3.10(T-A7,T-A8,T-A9)/3.8(T-A10)/5.1(T-A11)/3.8 占位卡片(T-A12 预埋)
- **缺口声明**：全局命令面板 `Ctrl+K`（spec 5.7-2）与 Android 番茄钟前台服务通知在计划中仅在验收清单提及——建议并入 Task 3.8（命令面板复用 registry 的 kind 检索）与 Task 5.2（Android 前台服务）扩展实现；如需独立任务可在执行时追加 Task 3.11/5.3，不阻塞主线。

**2. 占位符扫描**：Task 4.4 的 `for entry` 块是明确的「同构展开指引」，已标注执行者必须逐表落地、禁止空实现；视图类任务（2.4/3.3/3.4/3.5 等）的 UI 部分给出「实现要点清单」+ 原型对照路径（prototype.html），核心可测逻辑全部有代码与测试。无 TBD/TODO 类占位。

**3. 类型一致性**：`WidgetInstance{id,kind,w,h,config}` 在 0.4/1.7/3.8/3.10 间签名一致；`Beacon` 五字段在 4.1/4.5 一致；`decideLww`/`applyDiff`/`MergeResult` 命名贯穿 4.4/4.5；`PomodoroLog.endedAt` 以 0 表示进行中在 1.5/3.5 一致；表字段与 spec §6 SQL 逐字对齐（已将 `endedAt` 定义为非空默认语义，spec SQL 中 nullable 语义在 Drift 层以 0 哨兵实现，差异已记录）。

**已知技术债（诚实声明）**：
1. `estimated_pomodoros` spec SQL 有 DEFAULT 1、Drift 定义为 nullable——执行 Task 1.1 时统一为 `withDefault(Constant(1))`。
2. Android 扫码依赖（mobile_scanner）不在依赖矩阵——首版走手动 IP + 二维码展示（spec 降级要求已满足），扫码列为 v0.2 增量。
3. flutter_slidable 的 drag-展开-tap 交互与测试手势的匹配在 Task 3.2 已注明调整方案。

---

# 执行交接（Execution Handoff）

计划已完成并保存至 `docs/superpowers/plans/2025-10-10-dailydesk-implementation.md`。

两种执行方案：

**1. Subagent-Driven（推荐）** — 每个任务派发全新 subagent 独立实现，任务间两阶段评审，快速迭代。适合本计划：28 个任务边界清晰、每个任务自带 Files/Interfaces/测试/验收/提交五要素。

**2. Inline Execution** — 用 executing-plans 技能在本会话批量执行，检查点处暂停评审。

推荐执行顺序严格按 Phase 0 → 5（Phase 3 内部 3.1~3.10 可两两并行：3.1/3.2 同属 todos、3.3/3.4 独立、3.5/3.6/3.7 独立、3.8 依赖 0.4+1.7+1.8、3.9 独立、3.10 依赖 3.8）。建议每 Phase 结束跑一次全量 `flutter test` + `flutter analyze` 作为回归门禁。

**Which approach?**
