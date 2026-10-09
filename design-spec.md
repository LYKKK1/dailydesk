# 日常工作台 (DailyDesk) 规格设计说明书

> **文档版本**：v1.0.0  
> **更新日期**：2025-05-10  
> **适用平台**：Windows 10/11 & Android 8.0+  
> **核心架构**：Flutter (Dart) 跨端 + 本地离线优先 (Local-First SQLite) + 局域网 P2P 增量同步  

---

## 1. 项目概述与愿景

### 1.1 产品定位
**DailyDesk** 是一款面向个人高效率工作与日常生活的“全能生产力工作台”。它集成了待办任务 (GTD)、时间块日程、灵感便签、专注番茄钟、习惯打卡与每日复盘六大核心能力，并深度适配 **Windows 桌面端**（大窗口看板、全局快捷键极速捕获、边缘贴边悬浮条）与 **Android 移动端**（轻量便携、触控手势、基础通知）。

### 1.2 核心哲学
1. **纯本地与绝对隐私**：零云端服务器依赖，数据 100% 存储在用户本地设备，杜绝隐私泄露与服务器宕机风险。
2. **极速与轻量**：基于 Flutter 原生渲染，避免传统 Electron 的高内存开销；冷启动低于 0.8 秒，桌面常驻内存控制在 50~70MB 以内。
3. **无感局域网互通**：在不依赖外网的前提下，借鉴 LocalSend 成熟机制，实现 Windows 电脑与 Android 手机在同一局域网下的一键毫秒级双向增量同步。
4. **低打扰与深浅兼顾**：Windows 端深度支持悬浮贴边和全局快捷键，需要深度规划时打开大看板，日常工作时秒开秒关、最低限度打扰用户思考。

---

## 2. 系统技术架构与选型

### 2.1 技术栈总览

| 模块类别 | 选型技术 / 开源库 | 说明与选型理由 |
| :--- | :--- | :--- |
| **开发语言与跨端框架** | **Flutter 3.x (Dart 3.x)** | Windows 原生渲染 (Skia/Impeller) + Android 原生渲染，双端代码复用率 > 90% |
| **状态管理** | **flutter_riverpod (v2.x)** | 编译期安全、无上下文依赖、易于测试、响应式数据绑定 |
| **本地数据库** | **drift (SQLite ORM)** + `sqlite3_flutter_libs` | 响应式流式查询（Stream）、强类型实体映射、高性能 SQL 引擎 |
| **Windows 窗口与挂件** | **window_manager** + **screen_retriever** | 实现无边框窗口、置顶、动态改变尺寸、屏幕边缘贴靠检测 |
| **系统托盘与自启** | **system_tray** + **launch_at_startup** | Windows 托盘常驻图标、托盘右键菜单、开机自启选项 |
| **全局快捷键** | **hotkey_manager** | 注册系统级快捷键（默认 `Alt + Space`）唤起闪念胶囊 |
| **局域网设备自发现** | **nsd (mDNS)** + UDP 广播备用 | 无需输入 IP，双端同一 Wi-Fi 下自动广播并互相发现 |
| **局域网 P2P 数据传输** | **shelf (嵌入式 HTTP 服务)** + `http` 客户端 | 在设备本地启动轻量 HTTP 端口，点对点完成数据增量拉取与校验 |
| **白噪音与音频** | **audioplayers** | 本地内置雨声、咖啡馆等轻量音频无损循环播放 |
| **图表展示** | **fl_chart** | 专注时长折线图、习惯热力图、任务完成率圆环 |

---

## 3. 双端交互形态与界面规范

### 3.1 Windows 桌面端三大形态联动

```
+---------------------------------------------------------------------------------+
|                                 DailyDesk (Windows)                             |
|                                                                                 |
|  [形态 1: 主工作台大窗口 (Dashboard)]                                           |
|  +--------------+----------------------------------+-------------------------+  |
|  | 左侧导航     | 中间工作区                       | 右侧侧边栏              |  |
|  | - 仪表盘     |  [待办看板 / 日程日历 /          |  - 今日 Top 3 任务      |  |
|  | - 待办 GTD   |   灵感便签 / 专注番茄 /          |  - 迷你计时器           |  |
|  | - 日程时间块 |   习惯复盘]                      |  - 快速记事便签         |  |
|  | - 设置/同步  |                                  |                         |  |
|  +--------------+----------------------------------+-------------------------+  |
|                                                                                 |
|  [形态 2: 闪念胶囊 (快捷键呼出)]                                                |
|            +------------------------------------------------------+             |
|            | ⚡ 输入任务或灵感... (Enter 记录, Esc 关闭)           |             |
|            +------------------------------------------------------+             |
|                                                                                 |
|  [形态 3: 桌面贴边悬浮条 (Dock)]                                                |
|                                                     +-----------------------+  |
|  平时贴在右侧边缘为 4px 细条，鼠标悬浮自动弹出 ----> | ⏱️ 24:18 正在专注...   |  |
|                                                     | [✓] 完成项目方案初稿  |  |
|                                                     +-----------------------+  |
+---------------------------------------------------------------------------------+
```

1. **主工作台大窗口 (Dashboard Window)**
   * **尺寸与模式**：默认 `1200x800`，支持全屏、自由拉伸与窗口居中。
   * **行为**：点击关闭（X）按钮默认最小化至系统托盘；托盘支持左键单击唤起、右键弹出“打开主窗口 / 开启番茄钟 / 局域网同步 / 退出”。
2. **闪念胶囊 / 极速捕获栏 (Quick Capture)**
   * **尺寸**：`640x60` 无边框悬浮条，垂直居中靠上（Top 25% 屏幕位置）。
   * **唤醒机制**：全局快捷键 `Alt + Space`（支持在设置中自定义）。
   * **交互**：输入框自动获取焦点；直接敲字按 Enter 即刻作为【待办-收集箱】或【便签】保存，Esc 或鼠标点击窗口外部自动隐藏。
3. **桌面贴边悬浮条 (Floating Edge Dock)**
   * **位置**：默认吸附在屏幕右侧边缘，用户可上下拖动调整高度。
   * **交互模式**：
     * **待机状态**：收缩为右侧边缘 4px 宽度的微透明色块（或仅显示极小胶囊图标），几乎不阻挡工作软件。
     * **展开状态**：鼠标悬停（Hover）200ms 内平滑滑出，展示今日最紧急的 3 项待办（支持直接勾选）以及当前番茄钟的倒计时。鼠标移开后延迟 300ms 自动缩进。

### 3.2 Android 移动端界面形态
* **单栏触控优先**：Material 3 响应式设计，底部标准导航栏（【今日】、【待办】、【日历】、【便签】、【我的/同步】）。
* **手势驱动**：
  * 待办卡片向右滑动：播放清脆震动触感，立即勾选完成并触发轻量动效。
  * 待办卡片向左滑动：弹出快捷菜单（推迟至明天 / 修改优先级 / 删除）。
* **轻量常驻提示**：专注番茄钟运行中时，推送一条低开销的常驻前台通知显示剩余时间，点击直达应用。

---

## 4. 六大功能模块详细规格

### 4.1 待办任务 (Todo / GTD)
* **核心属性**：
  * `id`: UUIDv4
  * `title`: 任务标题（必填）
  * `description`: 详细说明（支持富文本/Markdown）
  * `priority`: P0（紧急重要，红）、P1（重要不紧急，橙）、P2（紧急不重要，蓝）、P3（低优先级，灰）
  * `due_date` & `due_time`: 截止时间
  * `status`: 未完成 (pending)、已完成 (completed)、已归档 (archived)
  * `category_id`: 归属分类/清单
  * `subtasks`: 子任务列表（支持多级清单单独勾选）
* **内置核心视图**：
  * **今日聚焦 (Today)**：动态过滤 `due_date <= 今天的日期 且 status == pending`。
  * **收集箱 (Inbox)**：所有未明确分配截止日期的草稿任务。
  * **四象限看板 (Eisenhower Matrix)**：在 Windows 宽屏下展示 2x2 网格，支持拖拽任务改变优先级。
  * **自定义清单**：支持按项目分组（如【工作】、【个人】、【学习】），支持自定义清单图标与主题色。

### 4.2 日程与日历 (Calendar & Time Blocking)
* **视图支持**：
  * **月视图**：标注每日事件小圆点与法定休假/调休标签。
  * **周视图**：7 列横向展开，直观查看本周时间分布。
  * **日时间轴视图 (Time Blocking)**：00:00 ~ 24:00 时间刻度（默认展示 08:00 ~ 22:00）。
* **拖拽时间块**：待办列表中的未排期任务可直接拖入日时间轴特定时间段（如 14:00~15:30），自动生成带时间段的日程条目。

### 4.3 灵感便签 (Memos / Quick Notes)
* **展示形式**：双端自适应卡片瀑布流（类似 Google Keep / Flomo）。
* **功能特性**：
  * 支持彩色便签背景（米白、浅黄、浅绿、浅紫等护眼莫兰迪色系）。
  * 支持轻量级 Markdown 语法（加粗、列表、代码块、链接）。
  * **一键转化**：每张便签右上角提供【转为待办】按钮，一键把灵感无缝变成执行任务。

### 4.4 专注番茄钟 (Pomodoro Focus)
* **计时机制**：
  * 经典模式：25 分钟专注 + 5 分钟短休息，4 个番茄后 15 分钟长休息。
  * 正计时模式：针对深度心流工作，自由计时并记录时长。
  * 倒计时自定义：可手动指定 10/15/45/60 分钟。
* **任务关联**：开始计时前可选择当前专注对应的【待办任务】；完成后自动累加该任务的番茄数。
* **白噪音**：内置 4 组本地轻量音频循环库（雨声 Rain、白噪音 White Noise、咖啡馆 Cafe、夏夜虫鸣 Forest），支持音量独立调节。
* **沉浸体验**：Windows 端支持一键全屏沉浸大时钟翻页动画。

### 4.5 习惯打卡与每日复盘 (Habits & Review)
* **习惯打卡**：
  * 配置项：习惯名称、目标频次（每天 / 工作日 / 每周 N 次）、图标。
  * 视图：每日打卡列表，附带近 30 天 / 近一年贡献热力图（GitHub 风格绿色方块）。
* **每日复盘**：
  * 每天 21:00 自动生成今日摘要模版：
    * “今日已完成 X 项任务，逾期 Y 项”
    * “今日累计专注 Z 小时”
    * “已连续打卡 N 天”
  * 提供今日心得记录框（自由文本输入），形成每日工作日志归档。

### 4.6 仪表盘总览 (Dashboard Overview)
* 主工作台的默认首屏，聚合当天最关键信息：
  * 顶部：根据时间动态切换问候语（早安/午安/晚安）+ 农历/公历日期 + 任务完成度环形进度条。
  * 左半部：今日 Top 3 核心任务 + 紧接着即将到来的日程。
  * 右半部：快捷便签输入框 + 习惯打卡一键勾选 + 快捷番茄钟一键开始。

---

## 5. 本地数据库 Schema 设计 (Drift / SQLite)

所有实体遵循**离线优先 (Local-First)** 设计规范，每个表均包含全局唯一 UUID 与同步标记字段：

### 5.1 数据表定义

```sql
-- 1. 待办任务表
CREATE TABLE todos (
    id TEXT PRIMARY KEY NOT NULL,            -- UUIDv4
    title TEXT NOT NULL,
    description TEXT,
    priority INTEGER NOT NULL DEFAULT 1,     -- 0: P0, 1: P1, 2: P2, 3: P3
    status TEXT NOT NULL DEFAULT 'pending',  -- pending, completed, archived
    due_date TEXT,                           -- YYYY-MM-DD
    due_time TEXT,                           -- HH:mm
    category_id TEXT,
    is_top INTEGER NOT NULL DEFAULT 0,       -- 是否置顶 (0: 否, 1: 是)
    created_at INTEGER NOT NULL,             -- UTC 毫秒时间戳
    updated_at INTEGER NOT NULL,             -- 最后修改时间戳 (用于增量同步)
    deleted_at INTEGER                       -- 软删除标记 (墓碑机制)
);

-- 2. 子任务表
CREATE TABLE subtasks (
    id TEXT PRIMARY KEY NOT NULL,
    todo_id TEXT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);

-- 3. 日程时间轴表
CREATE TABLE schedules (
    id TEXT PRIMARY KEY NOT NULL,
    todo_id TEXT REFERENCES todos(id),
    title TEXT NOT NULL,
    start_time INTEGER NOT NULL,             -- 开始时间戳
    end_time INTEGER NOT NULL,               -- 结束时间戳
    all_day INTEGER NOT NULL DEFAULT 0,
    color_tag TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);

-- 4. 灵感便签表
CREATE TABLE memos (
    id TEXT PRIMARY KEY NOT NULL,
    content TEXT NOT NULL,
    color_code TEXT DEFAULT '#FFFFFF',
    is_pinned INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);

-- 5. 番茄专注流水记录表
CREATE TABLE pomodoro_logs (
    id TEXT PRIMARY KEY NOT NULL,
    todo_id TEXT REFERENCES todos(id),
    duration_minutes INTEGER NOT NULL,
    mode TEXT NOT NULL DEFAULT 'pomodoro',   -- pomodoro, countup, countdown
    started_at INTEGER NOT NULL,
    ended_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);

-- 6. 习惯配置表
CREATE TABLE habits (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    frequency_type TEXT NOT NULL,            -- daily, weekdays, times_per_week
    target_count INTEGER NOT NULL DEFAULT 1,
    icon_name TEXT,
    color_code TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);

-- 7. 习惯每日打卡记录表
CREATE TABLE habit_records (
    id TEXT PRIMARY KEY NOT NULL,
    habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    record_date TEXT NOT NULL,               -- YYYY-MM-DD
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
);

-- 8. 同步状态元数据表
CREATE TABLE sync_devices (
    device_id TEXT PRIMARY KEY NOT NULL,
    device_name TEXT NOT NULL,
    device_platform TEXT NOT NULL,           -- windows, android
    last_synced_at INTEGER NOT NULL,
    pairing_key TEXT NOT NULL
);
```

---

## 6. 局域网 P2P 增量同步协议机制

借鉴 LocalSend 的去中心化设计，无需任何第三方云服务器，Windows 与 Android 直接在局域网内握手并对传：

```
+-------------------+                                       +-------------------+
|   Windows 桌面端   |                                       |   Android 手机端  |
+-------------------+                                       +-------------------+
          |                                                           |
          | ----- 1. UDP 组播/mDNS 广播 ("DailyDesk_Device") --------> | (互相感知在线)
          | <---- 2. UDP 组播/mDNS 广播 ("DailyDesk_Device") ---------| 
          |                                                           |
          |  [两端 UI 右上角亮起绿灯: "已发现我的设备"]                  |
          |                                                           |
   (点击同步/自动触发)                                                 |
          |                                                           |
          | ----- 3. HTTP POST /api/sync/pull (带上 last_synced_at) -> |
          |                                                           | (手机查询增量修改)
          | <---- 4. 返回手机端增量变更数据 (Changeset A) ------------- |
          |                                                           |
  (电脑端执行差异合并)                                                 |
          |                                                           |
          | ----- 5. HTTP POST /api/sync/push (带上电脑端增量数据) --> |
          |                                                           | (手机端执行合并)
          | <---- 6. 返回 200 OK 确认完成 -----------------------------|
          |                                                           |
  [两端更新各自的 last_synced_at，提示"同步完成"]                        |
```

### 6.1 阶段详解

#### 1. 发现阶段 (Discovery)
* **协议**：mDNS (Multicast DNS) 服务类型 `_dailydesk._tcp`，监听端口默认 `53317`。
* **广播载荷**：
  ```json
  {
    "device_id": "win-desk-uuid",
    "device_name": "Work-PC",
    "platform": "windows",
    "port": 53317,
    "version": "1.0.0"
  }
  ```
* **容错备用**：若路由器开启了无线客户端隔离 (AP Isolation) 导致组播受限，软件提供“局域网配对码”与“手动输入局域网 IP / 扫码连接”功能。

#### 2. 安全配对与握手 (Handshake)
* 首次连接时，一方展示 4 位动态配对验证码（如 `8826`），另一方输入后保存公钥/密钥哈希。
* 后续通信通过 Header 中的 `X-Sync-Token` 认证，杜绝公共网络下的未授权嗅探。

#### 3. 差异合并与冲突裁决 (Diff & Conflict Resolution)
* **查询范围**：
  ```sql
  SELECT * FROM [table] WHERE updated_at > :last_synced_at;
  ```
  查询结果包含所有在这期间新建、编辑或被标记为软删除（`deleted_at IS NOT NULL`）的行。
* **合并准则 (LWW: Last-Write-Wins)**：
  * 对比记录的 `updated_at` 时间戳。
  * 若目标端不存在该记录：直接插入（INSERT）。
  * 若目标端存在且本地版本更新：覆盖更新（UPDATE）。
  * 若目标端存在但目标端较新：保留目标端，忽略当前行。
  * 若接收到 `deleted_at IS NOT NULL`：执行软删除操作。
* **墓碑清理机制 (Tombstone GC)**：已软删除且超过 30 天的数据在两端同步完成后物理清除，防止数据库体积膨胀。

---

## 7. 异常处理与鲁棒性保障

1. **网络中断与超时**：
   * 同步网络请求设置 5 秒超时保护；若因走动离开 Wi-Fi 导致中断，事务自动回滚（Rollback），不会造成脏数据。
2. **多实例防护 (Windows)**：
   * Windows 端限制单实例运行（Single Instance），重复打开软件时自动激活并置顶已有窗口。
3. **断电/闪退数据安全**：
   * SQLite 采用 WAL (Write-Ahead Logging) 模式，保证写操作的高性能与突发崩溃恢复。
4. **离线备份与迁移**：
   * 设置页提供【导出为本地加密备份 (.bak)】与【一键恢复】功能，方便彻底更换设备时整体迁移。

---

## 8. 项目工程目录规划 (Flutter)

```
dailydesk/
├── android/                        # Android 原生平台配置
├── windows/                        # Windows 原生平台配置 (托盘、窗口集成)
├── assets/
│   ├── icons/                      # 应用图标、托盘图标
│   ├── audio/                      # 本地白噪音音频文件
│   └── holidays/                   # 中国法定节假日预置离线数据
└── lib/
    ├── app.dart                    # 应用全局入口与主题配置
    ├── core/
    │   ├── constants/              # 颜色、尺寸、常量
    │   ├── database/               # Drift 数据库定义与表结构
    │   ├── network/                # 局域网 mDNS 发现与 Shelf P2P 服务
    │   ├── theme/                  # 日间/夜间与莫兰迪色彩主题
    │   └── utils/                  # 快捷键、窗口贴边工具
    ├── features/
    │   ├── dashboard/              # 首页总览
    │   ├── todos/                  # 待办 GTD (四象限、清单、子任务)
    │   ├── calendar/               # 日历与时间块
    │   ├── memos/                  # 灵感便签
    │   ├── pomodoro/               # 专注番茄钟与白噪音
    │   ├── habits/                 # 习惯打卡与热力图
    │   ├── quick_capture/          # Windows 闪念胶囊悬浮窗
    │   ├── floating_dock/          # Windows 桌面贴边悬浮条
    │   └── sync/                   # 局域网配对与一键同步页面
    └── main.dart                   # main 初始化与平台差异调度
```

---

## 9. 验收标准与交付清单

1. **Windows 端交付表现**：
   * 启动快速，窗口流畅无黑屏；
   * `Alt + Space` 秒级呼出胶囊并成功记录待办；
   * 贴边悬浮条在鼠标滑入时平滑展开，滑出时自动收缩；
   * 关闭主窗口后托盘图标正常常驻，右键菜单完备。
2. **Android 端交付表现**：
   * 界面排版符合移动端直觉，滑动流畅；
   * 手势划动标记完成任务，触觉反馈良好。
3. **双端局域网同步交付表现**：
   * 双端连接同一路由器后，5 秒内感知对方在线；
   * 电脑新建的任务与便签，在手机端点击同步后 0.5 秒内即刻呈现；
   * 手机上删除或勾选的任务，同步后电脑端对应更新，无错乱、无丢失。
