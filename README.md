# DailyDesk 日常工作台

离线优先的个人生产力中枢：待办 GTD、时间块日历、灵感便签、番茄专注、习惯打卡、
每日 SOP 流程、晚间复盘与局域网 P2P 同步，全部数据保存在本机 SQLite。

- 平台：Windows 10/11 (x64) 与 Android 8.0+
- 技术栈：Flutter 3.x + Riverpod 2.x + Drift (Reactive SQLite) + Shelf/mDNS
- 原则：零云端依赖、零配置局域网互通、极轻资源开销、低打扰瞬时捕获

## 功能概览

| 模块 | 说明 |
| --- | --- |
| 待办 (Todo/GTD) | 今日聚焦、收集箱、四象限矩阵、P0-P3 优先级、子任务清单 |
| 时间块日历 | 日/周/月视图、待办拖拽成时间块、节假日标记、iCalendar 导入导出 |
| 灵感便签 | 卡片流、Markdown、标签筛选、一键转为待办 |
| 番茄专注 | 经典/Flowtime/倒计时三模式、白噪音混音、禅模式、Android 前台服务 |
| 习惯打卡 | 频次规则、数值型习惯、52 周热力图、连击与健康度 |
| 每日 SOP | 时间锚定流程卡、实时推进度、临时节点插入、次日自动重置 |
| 晚间复盘 | 自动聚合当日成果、结构化模板、Markdown 一键导出 |
| AI 智囊 | OpenAI 兼容接口拆解想法为待办/SOP/便签，支持代理与批量写入 |
| 局域网同步 | mDNS + UDP 组播发现、配对 PIN、增量 diff、LWW 合并与冲突副本 |

## 架构要点

- `lib/core/database` 是唯一真值层：所有状态（含看板布局、SOP 打卡、专注轮次）都落到 Drift 表，UI 只是状态的投影；`WidgetLayouts` 表通过 `LayoutRepository` 驱动看板持久化。
- `lib/widgets_infra` 提供与 UI 框架解耦的组件注册表与受控渲染上下文（`WidgetRegistry` / `WidgetContext` / `sanitizeLayout`），新增模块零侵入。
- 看板为真正的 12 列二维网格（`DashboardGrid`），半宽卡片并排渲染，支持拖拽重排、全边框拉伸、复制/前移/后移与多工作台页面。
- 同步冲突以业务唯一键（如 `habitId + recordDate`）优先匹配，避免多端离线产生的主键分裂；墓碑保留以便增量合并。

详细设计规格见 `design-spec.md`，可借鉴的外部实现分析见 `home-pages-借鉴指南.md`。

## 开发

```bash
flutter pub get
flutter analyze
flutter test

# Windows 桌面
flutter run -d windows

# Android
flutter run -d android
```

发布前检查（体积阈值、URL 白名单、tag 与版本一致性）：

```bash
dart run scripts/verify_bundle.dart --tag v0.1.0
```

## 数据与隐私

- 数据仅写入本机 `getApplicationSupportDirectory()` 下的 `dailydesk.sqlite`。
- 无遥测、无第三方中继；局域网同步只在家中/办公室路由器内部进行。
- AI 智囊为可选项，需要你自行填写 API Key，且仅在当前会话内存中使用。
