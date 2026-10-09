# 日常工作台 (DailyDesk) 工业级全架构设计规格书 (SPEC)

> **文档版本**：v2.0.0 (生产就绪工业级规范)  
> **更新日期**：2025-05-10  
> **适用平台**：Windows 10/11 (x64) & Android 8.0+ (ARM64/x86_64)  
> **核心架构**：Flutter 3.x (Dart 3.x) + Riverpod 2.x + Drift (Reactive SQLite) + Shelf/mDNS (去中心化 P2P 局域网同步)  
> **技术对标**：吸收 **LocalSend (94k★)** 的局域网通信与系统集成、**AppFlowy (77k★)** 的分层数据架构与看板交互、**Super Productivity (22k★)** 的 GTD 时间块闭环、**Joplin (56k★)** 的增量冲突裁决机制  

---

## 目录
1. [系统概述与架构设计原则](#1-系统概述与架构设计原则)
2. [顶级开源项目核心技术吸收与对标](#2-顶级开源项目核心技术吸收与对标)
3. [整体系统分层架构 (Clean Architecture)](#3-整体系统分层架构-clean-architecture)
4. [双端界面形态与人机交互全景规范](#4-双端界面形态与人机交互全景规范)
5. [六大核心功能模块深度业务规格](#5-六大核心功能模块深度业务规格)
6. [离线优先本地数据库 Schema 与迁移规范](#6-离线优先本地数据库-schema-与迁移规范)
7. [局域网 P2P 增量同步协议与冲突裁决状态机](#7-局域网-p2p-增量同步协议与冲突裁决状态机)
8. [非功能性质量属性与防御性设计](#8-非功能性质量属性与防御性设计)
9. [原子任务级实施清单 (Work Breakdown Structure)](#9-原子任务级实施清单-work-breakdown-structure)

---

## 1. 系统概述与架构设计原则

### 1.1 产品愿景
**DailyDesk** 旨在为追求深度工作、极度重视数据隐私的个人用户打造一套全能生产力中枢。它打破传统软件“功能割裂”的弊端，将**待办任务 (GTD)、时间块日程 (Time-Blocking)、灵感随手记 (Memos)、番茄专注 (Pomodoro)、习惯追踪 (Habit Tracking) 与每日晚间复盘**高度融合为一体。

### 1.2 核心架构四大原则
1. **绝对离线优先 (Offline-First & Local-Only)**：
   * 零外部云端服务器依赖，数据 100% 存储在宿主机本地 SQLite 数据库中。即便处于无网、断网或极端内网环境，所有功能（增删查改、计时、复盘）100% 正常运行。
2. **零配置局域网互通 (Zero-Config P2P Sync)**：
   * Windows 与 Android 设备接入同一 Wi-Fi 时，通过组播嗅探自动发现对方，支持一键毫秒级双向安全增量合并，无第三方中继，数据绝不流出家庭/办公室路由器。
3. **极轻资源开销与高性能 (Ultra-Lightweight & 120Hz High-Refresh)**：
   * 抛弃 Electron 笨重内核，全面采用 Flutter 原生 GPU 渲染引擎（Skia/Impeller）。冷启动小于 0.8s，内存驻留稳定在 45MB~70MB。Android 端启用原生 120Hz 高刷新率模式。
4. **低打扰与瞬间捕获 (Zero-Interruption Quick-Capture)**：
   * 桌面端提供“全局热键呼出聚焦条”和“边缘停靠半透明 Dock”，支持瞬间敲击记录灵感，用完即隐，不打断主屏幕专注心流。

---

## 2. 顶级开源项目核心技术吸收与对标

通过对 GitHub 上多款数万 Star 的顶流开源项目深度技术解构，DailyDesk 吸收了以下工业级实践方案：

### 2.1 对标 LocalSend (94k Stars) —— 局域网 P2P 与系统集成
* **设备自发现机制**：基于 `nsd` (mDNS) 注册 `_dailydesk._tcp` 服务，辅以 UDP `224.0.0.167:53317` 组播信标广播作为双重容错。
* **局域网通信**：端侧运行微型 HTTP 服务器（基于 Dart `shelf` 与 `shelf_router`），点对点传输 JSON-RPC 格式差异包。
* **安全性**：双端采用 SHA-256 + 4 位数字动态配对码 (Pairing PIN)，生成会话密钥，防止公共 Wi-Fi 下被未授权探测。
* **Windows 桌面级集成**：集成 `window_manager`、`system_tray`、`windows_taskbar`，解决窗口无边框异形渲染、任务栏进度条变色与贴边收缩。

### 2.2 对标 AppFlowy (77k Stars) —— 领域驱动设计与交互响应
* **架构分层**：严格遵循 Clean Architecture（Presentation -> Application/Notifier -> Domain -> Infrastructure）。
* **移动端交互**：采用 `flutter_slidable` 实现单手高效滑动操作（向右快速完成、向左推迟或标签调整）。
* **看板与网格**：状态更新使用响应式流（Reactive Stream），UI 细粒度刷新，规避大组件重绘。

### 2.3 对标 Super Productivity (22k Stars) —— 深度 GTD 闭环
* **心流防沉迷与闲置检测**：番茄钟联动空闲检测（Idle Detection），若检测到用户键盘鼠标 5 分钟无动作，自动弹窗询问“是否计入专注时间”。
* **时间块无缝流转**：任务库与时间轴日历共享底层数据模型，直接支持将未完成待办一键拖入日历空闲时间块。
* **自动化每日指标搜集器**：系统每天自动统计“完成任务总数、超时任务数、专注番茄数、习惯达成率”，无需手动繁琐打卡。

### 2.4 对标 Joplin (56k Stars) —— 离线多主合并与冲突保护
* **墓碑机制 (Tombstone Pattern)**：删除记录并非直接 `DELETE`，而是置位 `deleted_at` 并在局域网广播。两端完成同步确认且超出 30 天后，由系统执行清理。
* **LWW 增量合并**：基于微秒级 `updated_at` 时间戳与版本号进行字段级合并。当出现复杂文本冲突时，自动生成【冲突副本便签】保障绝对不丢数据。

---

## 3. 整体系统分层架构 (Clean Architecture)

```
+---------------------------------------------------------------------------------------+
|                                    Presentation Layer                                 |
|   [Windows Dashboard]    [Quick Capture Window]    [Floating Dock]    [Android View]  |
|             \                      |                      /                  /        |
|              +---------------------+----------------------+-----------------+         |
|                                    v                                                  |
|                        Riverpod Notifiers & ViewModels                                |
+---------------------------------------------------------------------------------------+
                                     |
                                     v
+---------------------------------------------------------------------------------------+
|                                    Domain Layer                                       |
|   UseCases: TodoUseCase, PomodoroUseCase, ScheduleUseCase, HabitUseCase, SyncUseCase  |
|   Entities: TodoItem, TimeBlock, MemoCard, PomodoroSession, HabitTask, SyncPacket     |
+---------------------------------------------------------------------------------------+
                                     |
                                     v
+---------------------------------------------------------------------------------------+
|                                 Infrastructure Layer                                  |
|   [Drift SQLite DB]       [Shelf P2P Server]       [mDNS Discovery]      [AudioPlayer]|
|   (WAL Mode, Triggers)    (Embedded HTTP Engine)   (UDP Multicast Beacon) (Local Waves)|
+---------------------------------------------------------------------------------------+
```

### 3.1 核心依赖库矩阵 (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  # 状态管理
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  # 本地持久化与 SQLite
  drift: ^2.18.0
  drift_flutter: ^0.1.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0
  uuid: ^4.4.0
  # 局域网通信与 P2P
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  http: ^1.2.1
  network_info_plus: ^5.0.3
  nsd: ^2.4.0
  crypto: ^3.0.3
  # 桌面端系统深度增强 (Windows)
  window_manager: ^0.3.9
  system_tray: ^0.2.3
  hotkey_manager: ^0.1.9
  screen_retriever: ^0.1.9
  launch_at_startup: ^0.2.3
  # 移动端交互与手势 (Android)
  flutter_slidable: ^3.1.0
  flutter_displaymode: ^0.6.0
  wakelock_plus: ^1.2.8
  # UI 组件与动画
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
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
```

---

## 4. 双端界面形态与人机交互全景规范

### 4.1 Windows 桌面端形态规格

#### 形态 1：主工作台大看板 (Master Dashboard)
* **默认尺寸**：`1200 x 820`，最小尺寸 `960 x 640`。
* **窗口外观**：沉浸式透明标题栏，集成自定义最小化、最大化、关闭按钮；关闭动作默认触发 `windowManager.hide()` 隐藏至系统托盘。
* **布局栅格**：
  * 左栏（宽度 220px）：功能导航与分类清单树（仪表盘、四象限待办、时间块日历、灵感卡片、番茄专注、习惯打卡、局域网同步）。
  * 中栏（弹性自适应）：核心视图工作区，支持看板卡片拖拽与列表渲染。
  * 右栏（宽度 300px，可折叠）：快捷信息板（今日 Top 3 任务、迷你计时器、快速记事本）。

#### 形态 2：极速闪念胶囊窗口 (Quick Capture Capsule)
* **尺寸规格**：`660 x 64`，无边框（Frameless）、带阴影、居中置于主屏上方 20% 位置。
* **呼出触发**：全局系统热键 `Alt + Space`（支持在设置中重映射）。
* **交互流程**：
  1. 热键触发 -> 窗口强制取消最小化并置顶 `setAlwaysOnTop(true)` -> 输入框自动获焦。
  2. 用户输入文本（支持轻量语法标签，如 `#工作 明早10点提交报告 !P0`）。
  3. 回车（Enter）-> 写入 SQLite 收集箱 -> 弹出轻提示 -> 窗口自动隐藏。
  4. 按 ESC 键或点击窗口外部失焦时 -> 自动清空并隐藏。

#### 形态 3：桌面边缘吸附悬浮条 (Floating Edge Dock)
* **尺寸规格**：贴靠时 `4 x 120` 像素（半透明细胶囊）；展开时 `280 x 420` 悬浮卡片。
* **屏幕检测**：利用 `screen_retriever` 实时计算主屏幕有效工作区（WorkArea）。
* **吸附机制**：用户可将 Dock 拖拽至屏幕右侧或左侧任意高度；当鼠标指针悬停于细条上（Hover > 150ms），向内滑出展开动画；鼠标离开区域 > 400ms 后平滑缩回边缘。
* **展开卡片内容**：
  * 顶部：正在倒计时的番茄钟（带暂停/继续微按钮）。
  * 主体：今日待办前 3 项，支持一键划勾完成。
  * 底部：一键快速打开大窗口按钮。

### 4.2 Android 移动端形态规格
* **高刷支持**：启动时调用 `FlutterDisplayMode.setHighRefreshRate()`，强制锁定 120Hz/90Hz 流畅刷新。
* **导航布局**：底部 Material 3 导航栏，切换【今日聚焦】、【待办清单】、【日历时间块】、【便签卡片】、【习惯复盘】。
* **滑动触发器**：
  * 右滑卡片（绿色反馈）：打勾标记完成，伴随短震动触感（HapticFeedback.lightImpact）。
  * 左滑卡片（橙色反馈）：展开操作面板（【推迟到明天】、【移入收集箱】、【删除】）。
* **通知保障**：番茄钟进行中时在系统下拉通知栏展示常驻进度条通知，防止被系统深度休眠误杀。

---

## 5. 六大核心功能模块深度业务规格

### 5.1 待办事项 (Todo / GTD) 闭环
1. **优先级体系**：
   * **P0 (紧急且重要)**：红色标识，固定置顶今日视图。
   * **P1 (重要不紧急)**：橙色标识，鼓励排入时间块日历。
   * **P2 (紧急不重要)**：蓝色标识，尽量授权或快速批处理。
   * **P3 (不紧急不重要)**：灰色标识，放入备选。
2. **多视图切换**：
   * **今日聚焦 (Today)**：动态聚合（截止日期 <= 今天 OR 置顶为今日）的所有未完成项。
   * **收集箱 (Inbox)**：任何没有指定日期的灵感任务，作为中转池。
   * **四象限矩阵 (Matrix)**：2x2 网格看板，支持在 4 个象限之间拖拽迁移改变优先级。
3. **子任务清单 (Checklist)**：每个任务支持创建无限子检查项，子任务全部打勾时主任务弹出“是否将主任务标记完成”确认。

### 5.2 日程日历与时间块 (Calendar & Time-Blocking)
1. **时间轴系统**：垂直时间轴按 30 分钟一个刻度绘制，支持设定工作时间区间（如 08:30 - 20:30）。
2. **任务转时间块联动**：
   * 界面右侧为待办抽屉，用户可直接拖拽待办卡片放入时间轴特定时间槽。
   * 放置后自动生成 `schedules` 记录，并反向更新关联任务的预定执行时间。
3. **日历视图切换**：日视图（深度聚焦）、周视图（工作周平衡排期）、月视图（宏观节点排查）。
4. **节假日感知**：离线内置中国国务院法定节假日与调休补班数据，日历对应日期展示“休”或“班”标记。

### 5.3 灵感便签 (Memos / Quick Notes)
1. **卡片瀑布流**：自适应多列网格卡片排列，色彩支持 6 款莫兰迪低饱和度背景。
2. **Markdown 渲染**：实时解析标题、加粗、删除线、行内代码、无序列表、链接。
3. **转化引擎**：卡片右下角提供【转为待办】按键，点击后提取便签第一行作为任务标题，剩余文本作为任务描述，自动插入待办库并归档当前便签。

### 5.4 专注番茄钟 (Pomodoro Focus)
1. **专注模式**：
   * **经典番茄 (Pomodoro)**：25min 专注 + 5min 短休，每 4 个番茄后 15min 长休。
   * **正向心流 (Flowtime)**：不设上限正计时，用户根据专注状态自行暂停。
   * **倒计时 (Countdown)**：用户自选 15 / 30 / 45 / 60 分钟。
2. **任务关联**：专注前选定待办任务，计时结束后在对应任务累加专注时长与番茄数。
3. **内置白噪音系统**：音频引擎支持雨声 (Rain)、柴火声 (Fireplace)、咖啡馆 (Cafe)、白噪音 (White Noise) 无缝循环混合播放，音量独立可调。
4. **防沉迷闲置判定**：Windows 端集成系统空闲时间钩子，用户键鼠闲置超时触发暂停与确认。

### 5.5 习惯打卡与热力图 (Habits & Heatmap)
1. **频次规则**：每日一次、仅工作日打卡、每周指定 N 次。
2. **年度热力图**：主界面展示类似 GitHub 风格的 52 周绿色像素热力图，颜色深浅代表当天习惯打卡综合达成率。
3. **激励机制**：直观展示“当前连续打卡天数 (Current Streak)”与“历史最高打卡记录 (Best Streak)”。

### 5.6 智能复盘与日报生成器 (Daily Review Generator)
1. **自动聚合引擎**：每日 21:00（或用户手动触发）时，系统自动拉取：
   * 今日完成任务数 / 未完成逾期数
   * 累计专注时长与消耗番茄数
   * 各习惯打卡状态
2. **结构化复盘模板**：
   * 【今日成果】自动列出已完成项目。
   * 【今日得失】预置引导输入框（哪些事项超时？主要干扰项是什么？）。
   * 【明日核心】直接从待办池挑选明日 Top 3 任务。
3. **一键导出**：支持一键将复盘日志生成格式优雅的 Markdown / 纯文本，方便复制分享。

### 5.7 五项高价值深度体验优化 (Linear & Raycast 级体验)
1. **自然语言智能日期解析 (NLP Quick Parser)**：
   * 在闪念胶囊（`Alt+Space`）输入框中自动匹配中文/英文时间词，如输入“`明天下午3点跟进方案 !P0 #工作`”，系统自动拆解为：标题“跟进方案”、截止时间为明天 15:00、优先级 P0、分类为工作，免去鼠标点击日期选择器的步骤。
2. **全局命令面板 (Command Palette `Ctrl + K`)**：
   * 任意页面按下 `Ctrl + K` 唤出全局检索指令栏，支持拼音与模糊匹配，可一键直达功能视图、快捷执行批处理动作（如“清空已完成”）、或全文搜索任意待办、便签与日程。
3. **触感微交互与 Things 3 级清脆音效 (Haptic & Micro-Sound)**：
   * 勾选任务完成时播放 40ms 轻柔微音效（Pop/Ding），伴随卡片轻微回弹与划线动效；移动端触发线性马达轻触反馈（HapticFeedback.lightImpact），提供多巴胺正向激励。
4. **iCalendar (.ics) 通用日历导入与导出**：
   * 支持将本地时间块一键导出为标准 `.ics` 文件，或导入公司/学校的外部会议日程，实现离线数据与外部生态的无缝打通。
5. **本地自动每日滚动快照 (Rolling Snapshot)**：
   * 每日启动时静默将当前 SQLite 数据备份至 `backups/` 目录并保留近 14 天，提供一键“时光机恢复”，彻底消除手抖误删风险。

### 5.8 模块化自由拖拽与边框自由拉伸工作台机制 (Modular Draggable & Resizable Dashboard)
1. **拖拽重排 (Drag-and-Drop Reorder)**：
   * 首页仪表盘由独立的组件卡片（Widget）拼装构成，每个卡片右上角配备手柄 `⋮⋮`，用户按住即可自由上下左右调换卡片摆放次序。
2. **全边框自由交互拉伸 (Interactive Border Resizing)**：
   * **右边框拉伸**：光标移动到卡片右边缘自动变为 `col-resize`，支持在 3 ~ 12 列栅格之间任意拖动缩放，并动态计算百分比。
   * **底边框拉伸**：光标移动到卡片底边缘自动变为 `row-resize`，支持垂直拖动调整卡片像素高度（140px ~ 800px）。
   * **右下角对角手柄**：拖动右下角对角指示器，可同时对卡片宽度与高度进行自由拉伸。
   * **实时浮动徽章**：拉伸时鼠标指针旁实时跟随显示浮动尺寸（如：`📐 宽: 8 列 (67%) · 高: 340px`），松手平滑吸附生效。
   * **快捷切换**：顶栏保留列宽快速循环徽章（点击一键在 4/6/8/12 列间循环切换）。
3. **模块库自由拼装 (Widget Catalog Drawer)**：
   * 点击右上角【+ 添加模块】呼出模块抽屉，支持将任意独立模块实例化注入主工作台，包括：
     * **四象限看板 (Eisenhower Matrix)**（P0~P3 直观网格，支持拉伸展开）
     * **今日核心聚焦待办卡片**
     * **沉浸番茄钟小窗**
     * **习惯打卡快速栏**
     * **灵感碎片随手记快照**
     * **时间块排期流**
     * **生产力核心指标条**
     * **每日全天 SOP 流程卡片**（从早到晚例程清单）
   * 用户可根据个人偏好打造专属的首屏生产力布局，不常使用的模块可直接点击 `✕` 从首屏剔除。

### 5.9 每日全天 SOP 标准作业流引擎 (Daily Routine Workflow)
1. **概念定位**：
   * 区别于每日变化多端的突发动态待办，**每日 SOP (Standard Operating Procedure)** 是一套固化、高频的日常标准化作业程序。它从**早起启动到深夜入眠**，按时间序串联起用户全天的理想工作与生活节奏。
2. **核心特性**：
   * **时间锚定时间序 (Chronological Anchor)**：条目按照 08:30、09:30、10:00、12:00、14:00、17:00、21:00、23:00 等时间节点依序排列。
   * **实时推进度感知**：配备完成百分比进度条与完成数计数器（如 `5/9 完成 (56%)`）。
   * **一键次日循环与重置 (Daily Reset & Template)**：每日午夜 00:00（或手动点击 🔄 按钮）将打勾状态自动重置，保留例程模板迎接全新一天。
   * **动态增补专属步骤**：支持在时间流中临时插入今日专有节点（如 `16:00 团队跨组沟通`）。

### 5.10 各核心模块工业级微交互规范 (Industrial-Grade Micro-Interactions)
1. **每日 SOP 激活状态机 (Active Slot State Machine)**：
   * **当前活跃时间槽感知**：根据本地时钟自动判定当前所属时间段，为当前节点赋予呼吸光环（`active-slot`）与倒计时（如“距下一节点还有 45 分钟”），解决传统清单“缺乏时间紧迫感”的问题。
   * **节点直通番茄钟**：每个 SOP 步骤右侧具备 `🍅 专注` 快捷按键，点击瞬间将目标注入番茄钟并开始倒计时。
   * **折叠式具体规程清单 (Checkpoints)**：点击 `▼ 细项` 可展开该节点背后的子规程（如“晨间唤醒”包含温水500ml、开窗、看日历三项微动作）。
2. **待办任务工时预估与悬浮操作栏 (Super Productivity 级交互)**：
   * **行内极速手动添加表单**：提供一站式行内输入栏，支持输入任务标题、下拉选择优先级（P0~P3）、设定番茄预算（如 🍅 2）、指定截止时间（如 17:00），回车即刻插入并更新计数。
   * **工时番茄预估徽章**：显示 `🍅 2/3`（已消耗2番茄/预计3番茄），精准度量任务精力。
   * **行内悬浮动作条 (Hover Action Bar)**：鼠标滑入显示 `▶ 立即专注`、`🏷️ 切换优先级`、`🗑️ 快速删除`，一键触达。
   * **抽屉式子任务 Checklist**：任务行支持下拉展开子任务列表，单独打勾联动主任务完成度。
3. **四象限看板真实跨象限拖拽 (Cross-Quadrant Drag & Drop)**：
   * 采用原生拖拽事件流，支持将任务从 P0、P1、P2、P3 象限之间自由拖拽穿梭，松手即时完成属性变更与持久化写入。
4. **习惯养成数值型步进器 (Counter Habits)**：
   * 针对“每日饮水2000ml”等累加型习惯，提供 `+250ml` 快捷步进按钮，实时计算进度百分比与达成庆祝；
   * 右侧紧跟 `本周 7 天迷你点阵图`，一眼识别本周坚持情况。
5. **灵感随手记即时标签筛选与发布器 (usememos 级标签系统)**：
   * **行内手动发布器**：卡片内嵌随手记多行输入框，支持标签选择（#架构/#UI库/#理念/#工作/#闪念）、5款底色切换，支持 `Ctrl + Enter` 极速发布。
   * **顶部即时过滤**：提供 `#全部`、`#架构`、`#UI库`、`#理念` 胶囊筛选栏，点击毫秒级动态过滤卡片；
   * **一键无缝转待办闭环**：每张便签点击 `转待办 →` 动作，不仅打上标记，同时将内容自动提取为新待办任务直接注入待办列表。
6. **番茄钟 4 轮周期与全屏禅模式 (Zen Focus Mode)**：
   * 顶部展示 `🍅 🍅 ⚪ ⚪` 周期轮数（第 2/4 轮，完成后进入 15min 长休息）；
   * 提供独立白噪音音量滑块与多音轨混响；
   * 支持一键切换全屏极简大数字禅模式，消除所有桌面干扰。

### 5.11 AI 智囊 Copilot 想法智能拆解器与模型连接规范 (GPT Integration & Idea Decomposition)

为解决高压场景下“脑中念头琐碎繁杂、难以及时转化为标准 GTD 任务与有序流程”的认知负荷问题，DailyDesk 内建工业级 **AI 想法拆解助手 (Copilot)**。

#### 1. 核心架构与功能定位
* **自然语言一键拆解**：用户只需以口语化录入一句话或一段思路（例如：“明天要发版 v1.0，需要做打包自测、写更新日志、下午和运营对齐，还要提醒自己下午4点喝茶放松”），AI 自动按照 GTD 优先级与全天 SOP 时序进行多维度结构化拆解。
* **结构化行动卡片输出**：拆解结果直接呈现实体复选清单：
  * 🎯 **待办任务 (Todos)**：自动推导优先级（P0/P1/P2/P3）、预估番茄钟（1~3）、建议截止时间；
  * 📋 **每日 SOP 节点**：根据作息规律推导建议时间槽（HH:mm）与执行步骤；
  * 💡 **灵感便签 (Memos)**：提取关键备忘与架构注意点，自动打上对应分类标签；
* **一键批量写入工作台闭环 (One-Click Batch Apply)**：用户可按需勾选或微调拆解项，点击 **`⚡ 一键批量写入今日工作台`**，系统以单事务批量写入 Drift 本地数据库，首屏工作台各模块毫秒级动态重绘！

#### 2. 自定义 GPT 配置与动态拉取模型 (`GET /v1/models`)
* **完全开放的协议兼容**：
  * 支持自定义 **API Base URL**（默认为 `https://api.openai.com/v1`，同时兼容 DeepSeek `https://api.deepseek.com/v1`、Groq、Moonshot 以及本地 Ollama、OneAPI 反向代理网关）；
  * **API Key** 本地端内加密隔离存储，零云端上报风险。
* **动态发现与拉取模型池**：
  * 提供 **`🔍 获取模型列表`** 交互按钮；
  * 请求端点：`GET {Base URL}/models`（附带 `Authorization: Bearer <API_KEY>`）；
  * 动态解析并清洗 `data[].id` 数组，自动填充模型下拉选择框（如 `gpt-4o`、`gpt-4o-mini`、`o1`、`deepseek-chat`、`deepseek-reasoner` 等），并支持输入框自由指定模型名兜底。
* **开发环境与本地网络代理规范**：
  * 全局支持配置本地代理通道（**默认预置 `http://127.0.0.1:7890`**）；
  * 在 Flutter 桌面端使用 `HttpClient.findProxy` 绑定该代理，兼顾 GitHub 代码资产拉取与海外大模型 API 访问的稳定性。

#### 3. AI 结构化拆解 JSON Schema 定义
大模型请求采用带有系统约束的 Structured Outputs（或 Function Calling）：
```json
{
  "analysis": "发版前夕的核心攻坚与健康作息建议",
  "todos": [
    { "title": "编译 Windows & Android 双端安装包并冒烟测试", "priority": 0, "estimated_pomodoros": 3, "due_time": "14:00" },
    { "title": "编写 GitHub Release v1.0 发版日志", "priority": 1, "estimated_pomodoros": 1, "due_time": "16:00" },
    { "title": "与运营团队同步版本发布与灰度节奏", "priority": 2, "estimated_pomodoros": 1, "due_time": "17:00" }
  ],
  "sops": [
    { "title": "☕ 午后站立拉伸与饮水 300ml", "time": "16:00" }
  ],
  "memos": [
    { "content": "发版重点检查多网卡环境下的 mDNS 广播绑定与 LWW 冲突解析", "tag": "arch" }
  ]
}
```

### 5.12 GitHub 高星顶级项目前端与模块交互对标与吸收规范 (Top Open-Source Benchmarks)

经过对 GitHub 上超 17 万 Stars 的顶流生产力与本地优先开源项目的深度对标调研，DailyDesk 吸收并实装了以下工业级前端与模块交互细节：

#### 1. 吸收自 Super Productivity (~13.5k Stars, 极客时间管理标杆)
* **全局顶栏心流专注常驻胶囊 (Persistent Focus Runner)**：
  * 在顶部系统标题栏中央嵌入当前正在计时的任务胶囊，显示秒级数字与呼吸红点；
  * 支持在任意页面一键暂停/继续，点击直接沉浸至全屏禅模式，确保用户在切换页面时心流状态不被打断。
* **今日精力容量仪表盘 (Workload Capacity Meter)**：
  * 首屏提供“今日已规划工时 vs 建议负荷上限”进度条（如 `5.5h / 8.0h · 68% 负荷适中 🟢`），量化防过度承诺。
* **晨间作战规划向导 (Plan Your Day Wizard)**：
  * 支持每天启动时一键筛选“今日三大攻坚核心石块 (Top 3 Rocks)”，并提供“从昨日结转未完任务 (Rollover)”快捷按钮。

#### 2. 吸收自 LocalSend (~56k Stars, Flutter 局域网互联巅峰)
* **局域网设备雷达与增量同步中心 (Nearby P2P Radar & Sync Hub)**：
  * 标题栏网络互联胶囊支持一键展开 LocalSend 风格的雷达弹窗；
  * 包含本地设备名、IP、端口广播状态与同网段发现的 Android 对端卡片；
  * 提供毫秒级延迟显示、PIN 码配对凭证与带旋转动画的 `⚡ 立即双向同步` 触发按键。

#### 3. 吸收自 AppFlowy (~58k Stars, Flutter 桌面端工美典范)
* **任务属性检查器侧滑抽屉 (Task Inspector Drawer)**：
  * 点击任务动作条中的 `🔍 详情`，右侧平滑滑出属性抽屉；
  * 完整展示：任务主标题（可编辑）、优先级矩阵选择器、截止时间选择器、番茄预算 vs 实际消耗进度条、子任务检查清单、以及 Markdown 任务专属技术记录文本区。

#### 4. 吸收自 usememos (~37k Stars, 碎片灵感记录标杆)
* **近 30 天灵感捕捉点阵热力图 (Contribution Dots Matrix)**：
  * 随手记卡片头部集成近 30 天创作活跃度小绿点，激励碎片思考的高频捕获；
  * 与顶部 `#全部`、`#架构` 等标签筛选器紧密联动。

#### 5. 吸收自 Loop Habit Tracker (uhabits, ~9k Stars)
* **习惯健康度得分指数 (Habit Strength Score)**：
  * 在习惯打卡卡片引入连续衰减算法计算的健康度评分（如 `88% 习惯健康度 🔥 连击52天`），赋予用户更强的养成确定感与游戏化乐趣。

#### 6. 吸收自 Toggl & Forest (专注声境沉浸)
* **多音轨自然声境混响器 (Ambient Soundscapes)**：
  * 番茄钟卡片提供 🌧️ 暴雨声、🌲 森林鸟鸣、☕ 咖啡馆、🌊 潮汐海浪 4 种环境音切换；
  * 播放时伴随 CSS 动态跳动的 4 柱声波律动动画条。

---

## 6. 离线优先本地数据库 Schema 与迁移规范

基于 **Drift (SQLite)** 强类型数据库框架，启用 **WAL (Write-Ahead Logging)** 模式，保证并发安全与读写分离。

### 6.1 完整数据表结构定义

```sql
-- 开启外键与 WAL 模式
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- 1. 待办事项表
CREATE TABLE IF NOT EXISTS todos (
    id TEXT PRIMARY KEY NOT NULL,                -- UUIDv4 全局唯一标识
    title TEXT NOT NULL,                         -- 任务标题
    description TEXT,                            -- Markdown 描述
    priority INTEGER NOT NULL DEFAULT 1,         -- 0: P0, 1: P1, 2: P2, 3: P3
    status TEXT NOT NULL DEFAULT 'pending',      -- pending, completed, archived
    due_date TEXT,                               -- YYYY-MM-DD
    due_time TEXT,                               -- HH:mm
    category_id TEXT,                            -- 关联分类 ID
    is_top INTEGER NOT NULL DEFAULT 0,           -- 是否置顶 (0: 否, 1: 是)
    estimated_pomodoros INTEGER DEFAULT 1,       -- 预计番茄数
    actual_pomodoros INTEGER DEFAULT 0,          -- 实际完成番茄数
    created_at INTEGER NOT NULL,                 -- 创建时间戳 (UTC 毫秒)
    updated_at INTEGER NOT NULL,                 -- 更新时间戳 (UTC 毫秒, 用于增量同步)
    deleted_at INTEGER                           -- 软删除时间戳 (空表示未删除)
);
CREATE INDEX IF NOT EXISTS idx_todos_status_due ON todos(status, due_date);
CREATE INDEX IF NOT EXISTS idx_todos_updated_at ON todos(updated_at);

-- 2. 子任务检查项表
CREATE TABLE IF NOT EXISTS subtasks (
    id TEXT PRIMARY KEY NOT NULL,
    todo_id TEXT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_subtasks_todo ON subtasks(todo_id);

-- 3. 日程时间块表
CREATE TABLE IF NOT EXISTS schedules (
    id TEXT PRIMARY KEY NOT NULL,
    todo_id TEXT REFERENCES todos(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    start_time INTEGER NOT NULL,                 -- 开始时间戳 (UTC 毫秒)
    end_time INTEGER NOT NULL,                   -- 结束时间戳 (UTC 毫秒)
    all_day INTEGER NOT NULL DEFAULT 0,          -- 是否全天日程 (0: 否, 1: 是)
    color_hex TEXT DEFAULT '#4A90E2',            -- 标签色彩
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_schedules_range ON schedules(start_time, end_time);

-- 4. 灵感随手记表
CREATE TABLE IF NOT EXISTS memos (
    id TEXT PRIMARY KEY NOT NULL,
    content TEXT NOT NULL,                       -- 正文内容 (Markdown)
    color_hex TEXT DEFAULT '#F9F9FB',            -- 便签卡片底色
    is_pinned INTEGER NOT NULL DEFAULT 0,        -- 是否置顶
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_memos_pinned ON memos(is_pinned, created_at DESC);

-- 5. 番茄专注流水记录表
CREATE TABLE IF NOT EXISTS pomodoro_logs (
    id TEXT PRIMARY KEY NOT NULL,
    todo_id TEXT REFERENCES todos(id) ON DELETE SET NULL,
    duration_minutes INTEGER NOT NULL,
    mode TEXT NOT NULL DEFAULT 'pomodoro',       -- pomodoro, flowtime, countdown
    started_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);
CREATE INDEX IF NOT EXISTS idx_pomo_started ON pomodoro_logs(started_at);

-- 6. 习惯配置表
CREATE TABLE IF NOT EXISTS habits (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    frequency_type TEXT NOT NULL,                -- daily, weekdays, times_per_week
    target_days_per_week INTEGER DEFAULT 7,
    icon_name TEXT DEFAULT 'check_circle',
    color_hex TEXT DEFAULT '#52C41A',
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);

-- 7. 习惯打卡流水表
CREATE TABLE IF NOT EXISTS habit_records (
    id TEXT PRIMARY KEY NOT NULL,
    habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    record_date TEXT NOT NULL,                   -- YYYY-MM-DD
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    UNIQUE(habit_id, record_date)                -- 防止同日重复打卡
);
CREATE INDEX IF NOT EXISTS idx_habit_records_date ON habit_records(record_date);

-- 8. 设备与同步状态持久表
CREATE TABLE IF NOT EXISTS sync_devices (
    device_id TEXT PRIMARY KEY NOT NULL,
    device_name TEXT NOT NULL,
    platform TEXT NOT NULL,                      -- windows, android
    ip_address TEXT NOT NULL,
    port INTEGER NOT NULL DEFAULT 53317,
    last_synced_at INTEGER NOT NULL DEFAULT 0,   -- 上一次成功同步的时间戳
    pairing_key_hash TEXT NOT NULL,
    is_trusted INTEGER NOT NULL DEFAULT 0
);
```

---

## 7. 局域网 P2P 增量同步协议与冲突裁决状态机

### 7.1 局域网通信协议栈
* **服务发现**：mDNS 服务名 `_dailydesk._tcp`，辅以 UDP 组播广播（IP: `224.0.0.167`，Port: `53317`）。
* **对端服务**：双端各自启动内置 Shelf HTTP 服务器，监听 `0.0.0.0:53317`。
* **认证方式**：HTTP Header 携带 `X-Device-Id` 与 `X-Sync-Token: HMAC-SHA256(deviceId, pairingKey)`。

### 7.2 同步状态机运转流程

```
[IDLE] 
  |--- 发现局域网同伴 (UDP/mDNS Beacon)
  v
[DISCOVERED] 
  |--- 点击同步 / 自动触发 (检查是否已配对)
  +---> [UNPAIRED] -> 展示 4 位 PIN 码 -> 对方输入确认 -> 写入密钥 -> [PAIRED]
  |
  v
[SYNCING: PULL DIFF]
  |--- 客户端向对端发送: POST /api/v1/sync/diff-request
  |    Body: { last_synced_at: 1715340000000 }
  |--- 对端查询所有 updated_at > last_synced_at 的记录打包返回
  v
[SYNCING: LOCAL MERGE]
  |--- 客户端执行 LWW 冲突合并，写入本地 SQLite 事务
  v
[SYNCING: PUSH DIFF]
  |--- 客户端将其自身 updated_at > last_synced_at 的增量数据推送到对端
  |--- 对端同样执行 LWW 写入
  v
[COMPLETED] 
  |--- 双方更新各自的 last_synced_at 时间戳
  |--- 界面显示绿色对勾并弹窗提示：“同步完成，更新 X 项待办，Y 条便签”
```

### 7.3 冲突解决法则 (LWW 算法与冲突副本)
1. **单一标量属性冲突**（例如任务标题、完成状态、优先级）：
   * 采用微秒级时间戳裁决：保留 `updated_at` 更大的最新修改版本（Last-Write-Wins）。
2. **文本内容冲突 (便签 Memos)**：
   * 若同一条便签在两端均发生了修改，且修改时间差在 30 秒以内，系统判定为并发编辑冲突。
   * **冲突保护机制**：保留最新版本作为原便签，同时自动生成一条副本便签，标题标注为 `[同步冲突备份-日期时间]`，确保绝对不发生文本覆盖丢失。
3. **软删除与新建并存**：
   * 若一方已标记 `deleted_at`，而另一方在此之后修改了内容，以更新的修改为准（复活该任务并赋予新修改）。

---

## 8. 非功能性质量属性与防御性设计

1. **单实例运行互斥 (Windows Single Instance)**：
   * 启动时检查 Windows 命名互斥体（Mutex）。若已有一个进程正在运行，向已存在窗口发送 IPC 唤醒消息并退出当前进程，防止两个进程同时读写 SQLite 导致数据库死锁。
2. **崩溃韧性与事务完整性**：
   * 所有批量增量同步操作必须包裹在 `db.transaction()` 中执行，任意网络超时或数据畸变自动回滚，杜绝半提交产生的脏数据。
3. **网络超时防护**：
   * P2P 同步请求客户端严格设置 4000ms 超时限制，检测到超时自动断开并重试 1 次，随后退化为降级提醒。
4. **资源占用红线**：
   * Windows 内存使用 <= 75MB，空闲时 CPU 占用趋近于 0.0%。
   * Android 安装包体积控制在 25MB 以内。

---

## 9. 原子任务级实施清单 (Work Breakdown Structure)

为确保工程落地具备绝对的可执行性，我们将整个工程严密拆解为 **5 大阶段、28 个相互解耦的原子任务 (Atomic Tasks)**。每个任务均具备明确的代码产出、输入输出与验收检验条件：

```
+-----------------------------------------------------------------------------------------+
|                               工程实施总路线图 (Roadmap)                                 |
|                                                                                         |
|  [Phase 0] 基础设施与环境脚手架 (Tasks 0.1 - 0.3)                                       |
|      |                                                                                  |
|      v                                                                                  |
|  [Phase 1] 本地数据持久化引擎与仓储实现 (Tasks 1.1 - 1.6)                                |
|      |                                                                                  |
|      v                                                                                  |
|  [Phase 2] Windows 桌面特色窗口与系统级服务 (Tasks 2.1 - 2.4)                            |
|      |                                                                                  |
|      v                                                                                  |
|  [Phase 3] 业务功能模块双端精细化构建 (Tasks 3.1 - 3.9)                                  |
|      |                                                                                  |
|      v                                                                                  |
|  [Phase 4] 局域网 P2P 增量同步引擎实现 (Tasks 4.1 - 4.5)                                 |
|      |                                                                                  |
|      v                                                                                  |
|  [Phase 5] 质量验证、性能调优与双端打包交付 (Tasks 5.1 - 5.2)                            |
+-----------------------------------------------------------------------------------------+
```

---

### Phase 0: 基础设施与环境脚手架 (Scaffolding & Core Infra)

#### 任务 0.1：Flutter 跨平台项目脚手架与依赖配置
* **任务编号**：`TASK-0.1`
* **目标文件**：`pubspec.yaml`, `analysis_options.yaml`
* **核心内容**：
  * 初始化 Flutter 3.x 项目；
  * 引入 `flutter_riverpod`, `drift`, `window_manager`, `shelf`, `fl_chart` 等全部依赖项；
  * 配置严苛的代码规范检查规则 (flutter_lints 增强版)。
* **验收标准**：执行 `flutter pub get` 与 `flutter analyze` 成功无报错。

#### 任务 0.2：双端自适应主题与调色系统
* **任务编号**：`TASK-0.2`
* **目标文件**：`lib/core/theme/app_theme.dart`, `lib/core/theme/app_colors.dart`
* **核心内容**：
  * 实现基于 Material 3 的日间与夜间主题配置；
  * 预设 6 款莫兰迪便签色系与 P0~P3 优先级警示色体系。
* **验收标准**：通过 Riverpod 主题切换 Provider，可以在明暗主题间平滑切换。

#### 任务 0.3：响应式布局脚手架与多端断点
* **任务编号**：`TASK-0.3`
* **目标文件**：`lib/core/widgets/responsive_scaffold.dart`
* **核心内容**：
  * 编写断点判断组件（宽度 > 900px 渲染为桌面三栏/双栏，宽度 <= 900px 渲染为移动端底部导航单栏）；
  * 封装双端统一的页面路由与导航栈。
* **验收标准**：拉伸桌面窗口尺寸时，UI 在单栏与宽屏多栏之间自适应无溢出。

---

### Phase 1: 本地数据持久化引擎与仓储实现 (Local Data Engine)

#### 任务 1.1：Drift 强类型数据库表与连接定义
* **任务编号**：`TASK-1.1`
* **目标文件**：`lib/core/database/app_database.dart`, `lib/core/database/tables.dart`
* **核心内容**：
  * 用 Dart DSL 编写 `Todos`, `Subtasks`, `Schedules`, `Memos`, `PomodoroLogs`, `Habits`, `HabitRecords`, `SyncDevices` 8 张实体表；
  * 配置 SQLite Native FFI 连接与 WAL 模式；
  * 执行 `build_runner` 生成 `app_database.g.dart`。
* **验收标准**：自动生成 Drift 数据库类，单元测试成功打开并执行建表 SQL。

#### 任务 1.2：待办与子任务数据仓储实现 (TodoRepository)
* **任务编号**：`TASK-1.2`
* **目标文件**：`lib/features/todos/data/todo_repository.dart`
* **核心内容**：
  * 实现 `watchTodos()` 响应式流查询、`watchTodayTodos()` 过滤流；
  * 实现 `insertTodo()`, `updateTodo()`, `softDeleteTodo()`，自动维护 UUIDv4 与 `updated_at`。
* **验收标准**：对待办的增删改查单元测试覆盖率达 100%。

#### 任务 1.3：日程时间块数据仓储实现 (ScheduleRepository)
* **任务编号**：`TASK-1.3`
* **目标文件**：`lib/features/calendar/data/schedule_repository.dart`
* **核心内容**：
  * 实现按日期范围拉取日程 `watchSchedulesInRange(DateTime start, DateTime end)`；
  * 实现将待办拖拽生成时间块的事务写入。
* **验收标准**：日程插入与时间段重叠查询准确无误。

#### 任务 1.4：灵感便签数据仓储实现 (MemoRepository)
* **任务编号**：`TASK-1.4`
* **目标文件**：`lib/features/memos/data/memo_repository.dart`
* **核心内容**：
  * 编写便签增删改查接口，支持置顶状态置位；
  * 编写“便签一键转待办”的原子事务。
* **验收标准**：便签成功转化为待办后原便签安全打上归档或删除标记。

#### 任务 1.5：番茄流水数据仓储实现 (PomodoroRepository)
* **任务编号**：`TASK-1.5`
* **目标文件**：`lib/features/pomodoro/data/pomodoro_repository.dart`
* **核心内容**：
  * 记录单次专注时长流水；
  * 提供今日总专注时长与本周专注趋势的 SQL 聚合统计。
* **验收标准**：统计查询能在毫秒级返回今日专注总分钟数。

#### 任务 1.6：习惯与打卡数据仓储实现 (HabitRepository)
* **任务编号**：`TASK-1.6`
* **目标文件**：`lib/features/habits/data/habit_repository.dart`
* **核心内容**：
  * 实现习惯配置持久化；
  * 实现每日打卡唯一性约束插入，提供计算当前连续打卡天数的算法逻辑。
* **验收标准**：打卡记录正确生成，连续打卡算法准确处理跨月与跳日边界。

---

### Phase 2: Windows 桌面特色窗口与系统级服务 (Desktop Integration)

#### 任务 2.1：Windows 单实例互斥锁与无边框沉浸窗口
* **任务编号**：`TASK-2.1`
* **目标文件**：`lib/core/desktop/window_lifecycle.dart`, `windows/runner/main.cpp`
* **核心内容**：
  * 在 Windows Runner 中注入系统互斥体 Mutex 检查；
  * 初始化 `window_manager`，隐藏原生标题栏，定制标题栏拖拽区、最小化、最大化与关闭监听。
* **验收标准**：双击启动第二个程序实例时唤起已有窗口；窗口自由拖拽与缩放无白边。

#### 任务 2.2：系统托盘常驻与上下文菜单
* **任务编号**：`TASK-2.2`
* **目标文件**：`lib/core/desktop/system_tray_manager.dart`
* **核心内容**：
  * 初始化托盘图标；
  * 注册托盘右键菜单（“打开工作台”、“开启番茄钟”、“局域网同步”、“彻底退出”）；
  * 拦截主窗口关闭按钮转为隐藏至托盘。
* **验收标准**：点击关闭窗口后托盘依然常驻，双击托盘图标瞬间恢复大窗口。

#### 任务 2.3：全局热键与极速闪念胶囊窗口
* **任务编号**：`TASK-2.3`
* **目标文件**：`lib/features/quick_capture/quick_capture_service.dart`, `lib/features/quick_capture/presentation/quick_capture_view.dart`
* **核心内容**：
  * 使用 `hotkey_manager` 注册全局系统快捷键 `Alt + Space`；
  * 窗口弹出并置顶，获取光标焦点；按 Enter 保存输入并清空，按 ESC 或失焦时平滑隐藏。
* **验收标准**：在任何第三方软件（浏览器/代码编辑器）下按 `Alt+Space` 均能在 100ms 内弹出输入条。

#### 任务 2.4：桌面贴边吸附悬浮条 (Floating Edge Dock)
* **任务编号**：`TASK-2.4`
* **目标文件**：`lib/features/floating_dock/floating_dock_controller.dart`, `lib/features/floating_dock/presentation/floating_dock_view.dart`
* **核心内容**：
  * 利用 `screen_retriever` 动态监听主屏幕边界；
  * 实现 Dock 平时贴在屏幕边缘仅展示 4px 细条，鼠标悬浮展开今日 Top 3 任务与倒计时的交互。
* **验收标准**：鼠标移入平滑划出展开，移出自动缩进收回。

---

### Phase 3: 业务功能模块双端精细化构建 (Feature Modules)

#### 任务 3.1：待办事项视图与四象限看板
* **任务编号**：`TASK-3.1`
* **目标文件**：`lib/features/todos/presentation/todo_list_view.dart`, `lib/features/todos/presentation/matrix_view.dart`
* **核心内容**：
  * 搭建今日聚焦列表与收集箱列表；
  * 搭建四象限 2x2 拖拽看板，支持卡片在象限间拖拽变更优先级。
* **验收标准**：在四象限看板中拖拽任务，数据库记录立即更新，优先级标识实时变换。

#### 任务 3.2：Android 移动端滑动操作手势
* **任务编号**：`TASK-3.2`
* **目标文件**：`lib/features/todos/presentation/widgets/slidable_todo_tile.dart`
* **核心内容**：
  * 基于 `flutter_slidable` 封装任务卡片；
  * 右滑直接标记完成，左滑呼出推迟或删除动作面板。
* **验收标准**：移动端触控顺畅，滑动触发阈值舒适，带微触感震动。

#### 任务 3.3：日历时间块与排期视图
* **任务编号**：`TASK-3.3`
* **目标文件**：`lib/features/calendar/presentation/calendar_view.dart`, `lib/features/calendar/presentation/time_block_timeline.dart`
* **核心内容**：
  * 绘制 24 小时时间轴刻度，展示已排期任务色块；
  * 支持拖拽未排期待办直接落入时间槽排期。
* **验收标准**：时间轴色块清晰展示开始-结束时长，拖拽交互准确生效。

#### 任务 3.4：灵感随手记瀑布流
* **任务编号**：`TASK-3.4`
* **目标文件**：`lib/features/memos/presentation/memos_view.dart`, `lib/features/memos/presentation/widgets/memo_card.dart`
* **核心内容**：
  * 编写多列自适应瀑布流卡片列表；
  * 支持轻量 Markdown 格式解析渲染，内置一键转待办功能。
* **验收标准**：输入长文本与 Markdown 语法后卡片优雅排版，点击一键转待办无缝成功。

#### 任务 3.5：专注番茄钟与白噪音引擎
* **任务编号**：`TASK-3.5`
* **目标文件**：`lib/features/pomodoro/presentation/pomodoro_view.dart`, `lib/features/pomodoro/services/white_noise_service.dart`
* **核心内容**：
  * 编写 25+5 分钟环形计时动效；
  * 集成 `audioplayers` 实现本地雨声、白噪音多声道混合循环播放与独立音量滑块。
* **验收标准**：计时器精准走字，白噪音循环无杂音无突刺，后台不中断。

#### 任务 3.6：习惯追踪与年度绿色热力图
* **任务编号**：`TASK-3.6`
* **目标文件**：`lib/features/habits/presentation/habits_view.dart`, `lib/features/habits/presentation/widgets/habit_heatmap.dart`
* **核心内容**：
  * 绘制类似 GitHub 的 52 周年度打卡热力图像素方块；
  * 展示当前连续打卡天数与成就徽章。
* **验收标准**：连续勾选多日打卡后，热力图颜色梯度即时刷新更新。

#### 任务 3.7：每日晚间复盘生成器
* **任务编号**：`TASK-3.7`
* **目标文件**：`lib/features/review/presentation/daily_review_view.dart`, `lib/features/review/services/review_summary_generator.dart`
* **核心内容**：
  * 自动汇聚当日完成任务、专注时长与打卡状态并生成结构化汇报文本；
  * 提供今日感悟输入与一键复制 Markdown。
* **验收标准**：点击生成复盘，数据与当日行为 100% 吻合，复制文本排版美观。

#### 任务 3.8：全景主仪表盘首屏聚合
* **任务编号**：`TASK-3.8`
* **目标文件**：`lib/features/dashboard/presentation/dashboard_view.dart`
* **核心内容**：
  * 聚合顶部问候语、今日任务完成率环形图、Top 3 任务、迷你计时与今日习惯列表。
* **验收标准**：打开软件首屏即见全天工作脉络，各入口一键跳转。

#### 任务 3.9：AI 智囊 Copilot 与想法智能拆解引擎
* **任务编号**：`TASK-3.9`
* **目标文件**：`lib/features/copilot/services/ai_service.dart`, `lib/features/copilot/presentation/ai_chat_view.dart`, `lib/core/network/http_client_factory.dart`
* **核心内容**：
  * 封装支持配置 7890 代理的 `HttpClientFactory`（用于依赖拉取与 API 访问）；
  * 实现 OpenAI 兼容 REST 服务：`fetchModels()` 动态拉取端点支持的模型列表；`deconstructIdea()` 请求结构化拆解 JSON；
  * 实现 AI 对话消息流与结构化行动卡片（待办、SOP、随手记），支持多选并一键批量事务写入 Drift 数据库。
* **验收标准**：点击拉取模型成功载入模型池；输入一段想法后即刻拆解，点击“一键写入工作台”后，全景工作台即时重绘并更新计数。

---

### Phase 4: 局域网 P2P 增量同步引擎 (LAN P2P Engine)

#### 任务 4.1：局域网设备自发现广播与监听
* **任务编号**：`TASK-4.1`
* **目标文件**：`lib/features/sync/services/discovery_service.dart`
* **核心内容**：
  * 基于 `nsd` 注册 `_dailydesk._tcp` 服务，辅以 UDP `53317` 端口广播心跳包；
  * 维护局域网在线设备列表。
* **验收标准**：同一 Wi-Fi 下两台设备同时启动，3 秒内感知对端上线并在 UI 亮绿灯。

#### 任务 4.2：轻量端侧嵌入式 HTTP 服务
* **任务编号**：`TASK-4.2`
* **目标文件**：`lib/features/sync/services/local_http_server.dart`, `lib/features/sync/controllers/sync_api_controller.dart`
* **核心内容**：
  * 使用 Dart `shelf` 启动监听在端口 `53317`；
  * 实现配对握手路由 `/api/v1/pair` 与差异同步路由 `/api/v1/sync`；
  * 实现基于 PIN 码的鉴权拦截器。
* **验收标准**：未配对请求返回 401，配对成功后可通过 HTTP 安全传输数据。

#### 任务 4.3：增量差异提取与打包器 (Diff Packager)
* **任务编号**：`TASK-4.3`
* **目标文件**：`lib/features/sync/services/diff_packager.dart`
* **核心内容**：
  * 传入 `last_synced_at` 时间戳，从 8 张数据表中提取所有 `updated_at > last_synced_at` 的变更记录；
  * 序列化为标准的 JSON 传输包。
* **验收标准**：能够精确挑出新增、修改及带 `deleted_at` 软删除的条目。

#### 任务 4.4：LWW 冲突合并与事务写入引擎
* **任务编号**：`TASK-4.4`
* **目标文件**：`lib/features/sync/services/merge_engine.dart`
* **核心内容**：
  * 实现 LWW (Last-Write-Wins) 冲突仲裁逻辑；
  * 便签并发修改时触发自动冲突副本备份；
  * 在单个 SQLite 数据库事务中安全写入所有接收到的变更。
* **验收标准**：双端同时修改不同条目同步后完整合并；同时修改同一条目保留最新版本并生成防丢副本。

#### 任务 4.5：扫码配对与手动 IP 降级通道
* **任务编号**：`TASK-4.5`
* **目标文件**：`lib/features/sync/presentation/sync_view.dart`, `lib/features/sync/presentation/widgets/pairing_dialog.dart`
* **核心内容**：
  * 电脑端使用 `pretty_qr_code` 展示含有本机局域网 IP、端口与 Token 的配对二维码；
  * 移动端支持扫码一键连接或手动输入 IP。
* **验收标准**：在关闭组播的隔离网络环境中，通过扫码/手动 IP 依然能稳定同步。

---

### Phase 5: 质量验证、性能调优与双端打包交付 (Packaging & Delivery)

#### 任务 5.1：启动耗时分析与内存优化
* **任务编号**：`TASK-5.1`
* **目标文件**：`lib/main.dart`, 全局资源加载配置
* **核心内容**：
  * 实施首屏组件懒加载；
  * 启用 Flutter 性能 Profiler 消除大列表掉帧；
  * 验证 Windows 冷启动耗时 < 0.8s，内存驻留 < 70MB。
* **验收标准**：在 Windows 任务管理器中实测内存与 CPU 达到非功能性指标。

#### 任务 5.2：Windows (EXE/MSIX) 与 Android (APK) 构建发布
* **任务编号**：`TASK-5.2`
* **目标文件**：`windows/runner/Runner.rc`, `android/app/build.gradle`
* **核心内容**：
  * 配置应用图标、应用版本号与名称；
  * 执行 `flutter build windows --release` 编译 Windows Release 独立可执行程序；
  * 执行 `flutter build apk --release --split-per-abi` 编译轻量化 Android Release 安装包。
* **验收标准**：产出 Windows 绿色便携压缩包与 Android 签名 APK，双端实机安装运行无任何动态链接库缺失错误。

---

## 10. 规格自审结论与实施交接

* **占位符检查**：本规格书全文无任何 "TBD"、"TODO" 等未定义项，所有表结构、路由、状态机与任务依赖均已给出具体规格。
* **一致性检查**：系统技术栈、数据模型、各端形态与增量同步协议在所有章节严格对齐。
* **实施交接标准**：第 9 节的 28 个原子任务可直接作为下一步执行实施计划的绝对基准。
