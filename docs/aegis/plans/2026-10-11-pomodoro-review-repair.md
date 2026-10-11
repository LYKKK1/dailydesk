# Goal

修复 Pomodoro 规格审查中的 blocking/major 问题，保持旧 API、schema v2
`cycleRound` 迁移、Flowtime/Countdown 语义、`todayFocusMinutes` 排除休息，
以及现有 151 个测试不回退。

# Architecture

- `PomodoroRepository` 是活动 session 状态机、break 规则、持久化原子性的
  canonical owner。
- `watchActiveSession()` 只负责查询 stream，不负责 reconcile 或任何写入。
- UI 的 init、ticker、start/finish 路径显式调用 `reconcileActiveSession()`，
  并根据返回的新 active session 投影通知。
- `AppDatabase` 负责 schema/migration 与 active-session 数据库约束。
- `MergeEngine` 负责 sync row normalization 后再 decode。
- `PomodoroForegroundService` 负责平台通知 bridge；Android native service
  负责通知标题/正文文案。

# Tech Stack

Flutter/Dart、Drift/SQLite、Android Kotlin、package:test/flutter_test。

# Baseline/Authority Refs

- `docs/aegis/work/2026-10-10-dailydesk-implementation/20-checkpoint.md`
- `docs/aegis/work/2026-10-10-dailydesk-implementation/90-evidence.md`
- `lib/features/pomodoro/data/pomodoro_repository.dart`
- `lib/features/pomodoro/presentation/pomodoro_view.dart`
- `lib/features/sync/services/merge_engine.dart`
- `lib/core/database/app_database.dart`

# Compatibility Boundary

- 保留现有 `startSession`、`finishSession`、`reconcileActiveSession`、
  `watchActiveSession` 等公开 API；`finishSession` 改为可 `await` 的返回
  `Future<PomodoroLog?>`，调用方忽略返回值仍兼容。
- 不删除或清理任何持久数据。
- 保留 schema v2 与旧 snake_case sync row 的兼容。
- Countdown 到期只结束并返回 idle；Flowtime 不自动结束；手动完成
  Countdown/Flowtime 不创建 break。
- 不修改 `SyncApiController` PIN policy。

# Verification

先新增并运行红测试：

```powershell
flutter test --no-pub test/features/pomodoro/pomodoro_repository_test.dart `
  test/features/pomodoro/pomodoro_foreground_service_test.dart `
  test/features/sync/merge_engine_test.dart test/core/database/app_database_test.dart
```

实现后运行：

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
```

# Repair Track

1. 为 watch 的纯读、离线跨 focus+break、手动 classic finish、旧 snake_case
   decode、active 唯一约束、break owner、通知文案补失败测试。
2. 在 repository/database/merge/UI/native notification 的 canonical owner 修复。
3. 用专项测试、全量测试、analyze 验证。

# Retirement Track

- 退休 `watchActiveSession()` 订阅时的隐式 reconcile 写入。
- 退休 UI `PomodoroCycle` 中重复的 break duration 规则，改为委托
  repository public static API。
- 不保留第二套 active-session 约束或 caller-side break 规则。
- 旧 snake_case normalization 保留为外部同步兼容边界；触发删除条件是
  外部协议确认不再发送 snake_case。

# Risks

- worktree 已有大量未提交实现，修改必须保持增量且不 reset/stash。
- Drift 生成文件可能需要 build_runner 更新。
- Android native notification 的真实设备验证仍受既有 Gradle/toolchain
  条件限制；Dart bridge 测试可覆盖参数投影。
