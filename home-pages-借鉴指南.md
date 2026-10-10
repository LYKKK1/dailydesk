# Home Pages (Obsidian) 借鉴指南

> **来源项目**：https://github.com/jepicaju862-lab/home-pages （Obsidian 首页看板插件，TypeScript，GPL-3.0，v0.3.1）
> **目标项目**：DailyDesk（本项目，Flutter + Riverpod + Drift）
> **本文档结构**：① 建议抄的架构与工程实践 → ② 与 DailyDesk 重合的功能对照 → ③ Home Pages 比 DailyDesk 做得更好的细节（同样抄） → ④ 不建议照搬的部分
> **分析依据**：已通读源码 `registry.ts` / `types.ts` / `api.ts` / `settings.ts` / `view.ts` / `verify-bundle.mjs` / `release.yml` / `modals.ts`，非仅看 README。

---

# 第一部分：建议抄的架构与工程实践（7 项）

## 1.1 组件注册表模式 ⭐⭐⭐⭐⭐（最高优先级）

**出处**：`src/widgets/registry.ts`（约 120 行）+ `src/widgets/types.ts`

**它怎么做的**：
- 每个看板组件是一个 `WidgetDefinition` 对象（kind / name / icon / accent / defaultSize / defaultConfig / normalizeConfig / render / renderSettings / liveRefresh），16 个内置组件全部平等地注册进一个 `Map<kind, definition>`
- 布局数据（`WidgetInstance`：id + kind + w/h + config）与渲染实现彻底解耦——持久化的只是「kind + 配置」
- `isWidgetKind()` 只要求非空字符串就保留——第三方组件所属插件没加载时，配置照样不丢，显示占位卡片
- `registerWidget()` 返回注销函数；`onRegistryChange()` 监听器集合支持热插拔
- 内置 kind 被注册表保护，第三方不可覆盖（`BUILTIN_KINDS` 检查）

**DailyDesk 怎么抄**（对应 spec 5.8「模块化自由拖拽工作台」，当前 spec 只有交互描述、缺可扩展架构）：

```dart
// daily_widget.dart
abstract class DailyWidgetDefinition<C> {
  String get kind;                  // 'todo' | 'pomodoro' | 'habit' | 'memo' | 'sop' ...
  String get name;
  IconData get icon;
  ({int w, int h}) get defaultSize; // 12 列网格
  C defaultConfig();
  C normalizeConfig(Map<String, dynamic> raw); // 必须实现，防脏数据
  Widget render(BuildContext context, WidgetContext<C> ctx);
  Widget renderSettings(BuildContext context, WidgetSettingsContext<C> ctx);
  bool get liveRefresh => true;    // 数据变化时是否自动重绘
}

// widget_registry.dart
class WidgetRegistry {
  final _byKind = <String, DailyWidgetDefinition>{};
  final _builtinKinds = <String>{};
  final _listeners = <RegistryChangeListener>{};

  VoidCallback register(DailyWidgetDefinition def, {String? provider}) {
    if (_builtinKinds.contains(def.kind)) {
      throw ArgumentError('内置 kind 不可覆盖');
    }
    _byKind[def.kind] = def;
    _notify(def.kind, registered: true);
    return () => unregister(def.kind);
  }
}
```

**收益**：spec 里的六大模块（Todo/日历/便签/番茄/习惯/复盘）+ SOP + 四象限等每个独立成 Widget 包，新增模块零侵入；持久化层只存 `{kind, w, h, config}` JSON，与 Drift schema 完全解耦，组件增删不丢数据。

## 1.2 WidgetContext 受控渲染上下文 ⭐⭐⭐⭐⭐

**出处**：`src/widgets/types.ts` 的 `WidgetContext` 接口

**它怎么做的**（组件不直接拿全局对象，而是拿一个受控 ctx）：
- `registerInterval(callback, ms)` / `registerCleanup(cb)` → 定时器、清理函数由框架自动管理，重绘/卸载时统一清掉，杜绝内存泄漏
- `isAlive()` → 异步加载完成后判断「我是否已被重绘」，防止过期渲染写入
- `saveConfig(patch)` → 写配置但不自动重绘；`rerender()` 显式触发
- `setSubtitle()` / `addHeaderAction()` → 卡片标题栏扩展统一收口
- 配置面板用独立的 `WidgetSettingsContext`，操作的是**草稿**，点保存才写回

**DailyDesk 怎么抄**（直接支撑 spec 第 8 节「内存 ≤75MB、CPU 空闲趋近 0」的红线——泄漏大头就是组件级 Timer / StreamSubscription / async gap 后 setState 已 dispose 的 widget）：

```dart
class WidgetContext<C> {
  final TickerProvider vsync;
  final WidgetInstance widget;
  C config;

  Timer registerInterval(void Function() cb, Duration period); // dispose 自动 cancel
  void registerCleanup(VoidCallback cb);
  bool isAlive();                          // 等价于 mounted 检查
  Future<void> saveConfig(Map<String, dynamic> patch);
  void rerender();
  void setSubtitle(String text);
  Widget addHeaderAction(IconData icon, VoidCallback onClick);
}
```

## 1.3 配置健壮性防御三件套 ⭐⭐⭐⭐

**出处**：`src/widgets/types.ts` 的 `normalizeWith()` / `clampInt()` / `toStringList()`（合计 <60 行）

**它怎么做的**：
```ts
normalizeWith(defaults, raw)  // 按默认值类型逐字段纠正：
  // 数字字段 Number() 解析失败 → 回退默认值
  // 布尔兼容 "true" 字符串；数组/对象做结构校验
  // null / undefined → 跳过保留默认值
clampInt(value, min, max, fallback)   // 范围钳制 + 取整
toStringList(value, max = 50)        // 字符串/数组双兼容 + 去重 + 条数上限
```

**DailyDesk 怎么抄**：spec 第 6 章有 Drift 迁移规范，但**字段级容错**没覆盖。Dart 直接移植这三个函数，应用在三处：用户导入的 JSON 布局、P2P 同步包里的 config、跨版本字段变更后的旧数据。

## 1.4 「计时状态与 UI 分离」的番茄钟持久化 ⭐⭐⭐⭐

**出处**：README FAQ + `widgets/pomodoro.ts`（22KB）

**它怎么做的**：番茄钟的**计时起点与状态持久化在插件后台**，UI 只是投影。切页、重绘、重启 Obsidian 都能精准恢复并准时到点。

**DailyDesk 怎么抄**（强化 spec 5.4）：
- 把 `PomodoroUseCase` 从 Notifier 中拆出，计时状态写 Drift
- **存 `started_at` 时间戳 + 模式 + 参数，不存剩余秒数**——任何时刻打开 UI 都用 `now - started_at` 重算
- 你的双端 P2P 同步场景下，这个设计让番茄钟天然可跨设备、跨重启恢复（甚至 Android 端能看到 Windows 端正在进行的番茄）
- 到点提醒用「绝对时刻调度」而非「倒计时结束触发」，进程被杀也能在重启后补发通知

## 1.5 宿主 API + 生态位设计 ⭐⭐⭐⭐

**出处**：`src/api.ts`（HomePagesApi 接口）

**它怎么做的**：
- API 带 `version: 1` 版本号，向后兼容有抓手
- `registerWidget(def, provider)` / `pinWidget(kind, config, opts)` / `refresh(kind)` / `openPath` / `ui.renderKpi` 等
- `pinWidget` 内置**重复检测**（同 kind + 同 config 提示「已经有同样的组件」，`allowDuplicate` 可覆盖）
- 处理加载时序：首页可能晚于调用方加载 → 通过事件 `"home-pages:ready"` 广播就绪，调用方也可轮询 `app.plugins.plugins["home-pages"]?.api`
- 提供 `api.ui.renderKpi / renderEmpty` 让第三方组件视觉与内置一致
- 已有真实生态案例：duowei-table-pro 通过该 API 注册 `duowei-view`，在多维表格里右键「固定到首页」

**DailyDesk 怎么抄**：即使第一版不做插件系统——
- `WidgetRegistry` + `WidgetContext` 设计成不依赖具体 UI 框架的纯接口
- 预定义 `DailyDeskApi`（带版本号），暴露 registerWidget / pinWidget / refresh
- 预留「provider 未加载显示占位卡片」逻辑（kind 是任意字符串，找不到 definition 时渲染占位 UI 而非丢弃数据）

## 1.6 构建安全门禁 verify-bundle.mjs ⭐⭐⭐⭐

**出处**：`scripts/verify-bundle.mjs`（30 行），挂在 `npm run build` 末尾

**它怎么做的**：正则扫描最终产物 main.js，禁止 `eval()`、动态 `createElement('script')`、`new Function()`，出现即 build fail。README 的「零遥测、本地优先」承诺由此变成 **CI 里可执行的断言**。

**DailyDesk 怎么抄**（Flutter 等价门禁，写进 CI）：
- 产物体积阈值检查（对应 spec 冷启动 <0.8s、apk ≤25MB 的指标）
- 源码/产物扫描：`dart:io` 的 `Process.run` / `HttpClient` 调用点白名单审查——支撑「数据绝不流出路由器」承诺可验证化
- grep 全部 URL 字面量，凡不在白名单（天气 API 等）即 fail

## 1.7 发布流程工程化 ⭐⭐⭐

**出处**：`.github/workflows/release.yml`

**它怎么做的**：
- **tag 与 manifest.json 版本一致性校验**（不一致直接 fail）
- lint → build（tsc 类型检查 + verify-bundle 门禁）→ 发布
- **构建来源证明（provenance attestations）**——供应链可信
- `concurrency` + `cancel-in-progress: false` 防止重复发布互相覆盖

**DailyDesk 怎么抄**：tag 与 `pubspec.yaml` 版本一致性校验步骤照抄；Flutter 产物附 attest；双语 RELEASE_NOTES 的文档习惯（见第三部分 3.8）。

---

# 第二部分：与 DailyDesk 重合的功能对照

两者是「同一产品理念的两种宿主形态」：Home Pages = Obsidian 内的看板工作台，DailyDesk = 独立跨端应用。重合度很高，逐项对照：

| 功能 | Home Pages | DailyDesk (spec) | 重合度 | 谁更完整 |
|---|---|---|---|---|
| **首页看板 + 自由拖拽布局** | 12 列网格、拖拽重排、边角手柄拉伸、模块抽屉 | spec 5.8：拖拽重排 + 全边框拉伸 + 模块库抽屉 | ★★★★★ 极高 | 交互规格 DailyDesk 更细（全边框拉伸 vs 它只有右下角手柄），但**架构**它远更成熟（见 1.1） |
| **番茄钟** | 25/5/15 循环、进度环、周期点、今日/本周统计、跨重启续时 | spec 5.4：25/5/15 + Flowtime + Countdown 三模式、白噪音、闲置检测、任务关联 | ★★★★ 高 | DailyDesk 功能面更宽（白噪音/防沉迷/任务关联）；它胜在**持久化策略**（见 1.4） |
| **习惯打卡 + 热力图** | 今日清单 + GitHub 热力图（周/月/年）+ 连续天数 | spec 5.5：每日/工作日/每周 N 次 + 52 周热力图 + Streak | ★★★★★ 极高 | DailyDesk 略多（频次规则、spec 5.10 数值步进器）；它的月/年双视图切换值得抄 |
| **任务看板（Kanban）** | 提取笔记 `- [ ]` 待办，按 [/]/[x] 三栏、拖拽换列、回车新增、双击编辑 | spec 5.1：今日/收集箱/四象限三视图 + 跨象限拖拽 | ★★★☆ | 定位不同：它是笔记待办的投影，你是独立 GTD 引擎（子任务、优先级、P0-P3），DailyDesk 完胜 |
| **快速捕获** | 无独立热键（依赖 Obsidian 宿主），但有「快捷入口」磁贴 | spec 4.1 形态 2：Alt+Space 全局热键闪念胶囊 + NLP 解析 | ★★★ | DailyDesk 明显更强（全局热键 + 自然语言解析） |
| **每日一言/格言** | quote 组件：按天轮换或随机、来源笔记 | 无对应 | ★★ | 可选抄：给复盘页加「每日一句」小卡片，成本低 |
| **全库统计** | 笔记数/标签数/字数/附件/库龄/今日新建/本周修改 | spec 5.8 生产力核心指标条（任务完成数/番茄数等） | ★★★ | 方向相同、数据源不同；它「指标项可独立开关」的设置粒度值得抄 |
| **倒计时/纪念日** | countdown 组件 | 无直接对应（hero 横幅有「目标倒计时徽章」但 DailyDesk spec 未含） | ★★★ | 可抄：习惯/项目目标倒计时徽章，放进仪表盘 |
| **那年今日** | onthisday 组件：往年同月同日笔记回忆 | 无 | ★ | DailyDesk 可做「去年的今天完成了什么」——复盘数据的回忆杀，与习惯热力图联动，成本低情感价值高 |
| **本地优先 + 零遥测** | 明确承诺 + CI 门禁验证 | spec 1.2 原则一 | ★★★★ | 两者理念一致；它把承诺做成了**可执行门禁**（见 1.6），DailyDesk 应跟进 |
| **多页面/多工作台** | 多首页（工作/生活/项目），标签栏 + 页面复制 | 无（单一主工作台 + 视图切换） | ★★ | **值得抄**：见第三部分 3.1 |
| **布局 JSON 导入导出** | 一键复制/粘贴 JSON，跨设备迁移 | 无对应（只有数据备份快照） | ★★ | **值得抄**：见第三部分 3.2 |

**重合结论**：功能层 DailyDesk 的 spec 更完整（GTD 深度、AI 拆解、SOP 引擎、P2P 同步都是它没有的）；**架构层与工程层 home-pages 全面领先**——这正是第一部分要抄的全部内容。

---

# 第三部分：Home Pages 比 DailyDesk 做得更好的地方（同样抄）

以下是逐行读 `settings.ts` / `view.ts` / `modals.ts` 后挖出的、你的 design-spec **没有覆盖**的细节，按价值排序。

## 3.1 多页面（多工作台）管理 ⭐⭐⭐⭐

**它比 DailyDesk 好在哪**：DailyDesk spec 只有「一个主工作台 + 左栏视图切换」；它支持任意多个独立首页（「工作工作台」「生活记录」「项目仪表盘」），且：
- 编辑模式下可直接**拖动标签调整页面顺序**；右键标签可重命名/移动/删除
- **页面复制**（一键克隆整页布局，widget 全部重新分配 id）
- 删除最后一个页面时自动重建默认页（保证至少一页，不会出现空状态死局）
- 设置里有「＋ 新建空白页面」和「＋ 新建默认布局页面」**双按钮**——空白页给高级用户，默认页给想重来的人

**抄进 DailyDesk**：仪表盘支持多布局档案（Layout Profile），如「工作日」「周末」「项目冲刺期」各有独立看板。落地要点：
```dart
// 复制页面时 id 全部重新生成，绝不能复用（同步场景 id 冲突是灾难）
final copy = sanitizePage({...page, id: null, name: '${page.name} 副本',
  widgets: page.widgets.map((w) => {...w, id: null}).toList()});
// 删除后兜底：永远保证至少一页
```

## 3.2 布局 JSON 导入导出 ⭐⭐⭐⭐

**它比 DailyDesk 好在哪**：DailyDesk 有「每日滚动快照」（数据备份），但**布局**无法导出迁移。它的导入导出细节非常讲究：

```ts
// 导出：带版本号的规范化 JSON（indent 2）
JSON.stringify({ version: SETTINGS_VERSION, pages: settings.pages }, null, 2);
// 导入时三重防御：
// 1. 兼容三种输入：裸页面数组 / {pages:[]} 包装 / 单个页面对象
// 2. 每个页面、每个 widget 都过 sanitizePage/sanitizeWidget 清洗
// 3. 导入的 id 全部重新生成（createId），追加到现有页面之后，不覆盖
// 4. 剪贴板 API 失败时降级为可复制文本的 Modal（移动端兼容）
```

**抄进 DailyDesk**：布局/看板配置一键导出 JSON、二维码（双端迁移不用连 P2P）、导入走三重防御。**「导入即重新生成 id」这条在你的 P2P 同步架构下尤其关键**——同 id 布局在两台设备同步会冲突。

## 3.3 sanitizeSettings 全量入口清洗 ⭐⭐⭐⭐

**出处**：`settings.ts` 的 `sanitizeSettings()` —— 任何数据进入内存前的唯一关口。

**它比 DailyDesk 好在哪**：你的 spec 有 schema 迁移，但缺「入口清洗」思维。它每次加载都全量过一遍：
- 页面数组逐个 `sanitizePage` → 失败丢弃而不是整个崩
- `activePageId` 指向不存在的页面时**自动回退到第一页**（孤儿引用防御）
- 数字字段全部 `clamp` 进合法区间（rowHeight 24~96、gap 4~40、maxWidth 0~4000）
- `seenCustomWidgetKinds` 数组去重 + 过滤非字符串

**抄进 DailyDesk**：Drift 读出的每份布局 JSON、每个 P2P 同步包，入口统一过一个 `sanitizeLayout()`。孤儿 activePageId 回退逻辑尤其要抄。

## 3.4 设置面板的「布局参数三件套」⭐⭐⭐

**出处**：settings.ts —— `rowHeight`（24~96px，步进 2）/ `gap`（4~40px）/ `maxWidth`（0~4000px，0=不限）

**它比 DailyDesk 好在哪**：DailyDesk spec 5.8 的网格参数是写死的；它把行高、间距、最大宽度做成用户可调，且：
- 修改即刻生效（`refreshViews({layoutOnly: true})` —— **只重排布局、不重渲染组件内容**，滑动行高滑块不触发数据重载）
- 用 Slider + `setDynamicTooltip()` 拖动实时预览

**抄进 DailyDesk**：spec 5.8 补充「网格设置」小节：行高、间距、内容最大宽度三项用户可调 + `layoutOnly` 刷新分层（这个分层刷新本身就是性能优化，避免调个行高就把全部 widget 的数据层重新拉一遍）。

## 3.5 拖拽/拉伸的细节打磨 ⭐⭐⭐⭐

**出处**：`view.ts` 的 `bindResize()`（约 120 行），是全项目交互质量最高的代码。

**它比 DailyDesk 好在哪**（你的 spec 5.8 已有拉伸描述，但它多出这些关键细节）：
1. **虚线框跟随 + 卡片吸附分离**：拉伸时一个虚线框逐像素跟着指针，卡片本体按列/行吸附移动，其它卡片平滑让位——视觉既跟手又不抖
2. **键盘无障碍**：手柄聚焦后方向键逐格调整（±1 列/行）——桌面端精细调整神器
3. **窄屏自适应降级**：检测到网格不是 12 列（窄屏全宽布局）时自动 `lockWidth`，只允许调高度——移动端不会出现横向拉伸乱象
4. **四重取消保护**：`pointercancel` / `lostpointercapture` / `Escape` / 手柄移除，任何中断都恢复原尺寸
5. **尺寸徽章实时显示**「`8 列 × 5 行`」
6. **`animateCards()` 包裹变更**——让位动画统一收口

**抄进 DailyDesk**：四条全抄，尤其 ②③④。spec 5.8 只写了「Esc 取消」，没有 pointercancel 丢失保护和窄屏 lockWidth 降级，这两条在 Android 触屏上是刚需。

## 3.6 组件级操作：复制 / 前移 / 后移 ⭐⭐⭐

**出处**：view.ts —— 编辑模式下卡片底部按钮组：前移、后移、**复制组件**（deep clone config + 新 id，插到原卡片正后方）、删除。

**它比 DailyDesk 好在哪**：spec 5.8 只有「✕ 剔除模块」。实际使用中「复制组件」是高频操作（比如放两个便签 widget 各盯一个标签）。抄：编辑模式卡片操作组 = 前移 / 后移 / 复制 / 删除。

## 3.7 「只自动上桌一次」的防打扰设计 ⭐⭐⭐

**出处**：settings.ts —— `seenCustomWidgetKinds: string[]`

**它比 DailyDesk 好在哪**：新组件脚本首次加载成功自动放到首页（很好），但记录已见过的 kind——**用户删掉卡片后再改脚本，不会被强行加回来**（烦人行为），除非显式重新扫描。另附开关 `autoAddCustomWidgets`。

**抄进 DailyDesk**：任何「自动添加到看板」的机制（如新装的模块包、AI 拆解生成的新卡片类型）都要有 seen 集合 + 用户开关 + 手动「重新扫描」入口。

## 3.8 默认页面工厂 + 一键重置 ⭐⭐⭐

**出处**：`createDefaultPage()` + 设置面板「重置为默认布局」

**它比 DailyDesk 好在哪**：
- 默认首页不是硬编码布局，而是**用注册表 API 组装**的（`createWidgetInstance("hero", {w:12,h:4,...})` × 12 个）——默认值本身就是架构的第一个用户
- 「＋ 新建默认布局页面」让用户随时生成一份初始看板
- 重置有 ConfirmModal 二次确认（红色 danger 样式 + 明确警告「习惯打卡等本地数据也会清除」）

**抄进 DailyDesk**：`createDefaultDashboard()` 工厂函数 + 「恢复默认布局」入口 + 危险操作统一 ConfirmModal 组件（title / message / confirmText / danger 四参数，它已封装好，Dart 照抄接口）。

## 3.9 FAQ 与文档策略 ⭐⭐

**出处**：README.zh-CN.md

**值得抄的点**：FAQ 直击真实恐慌点（「手机端布局会乱吗」「番茄钟重启后还准吗」「怎么恢复初始布局」），且每个答案都是**对架构设计的复述**（本地优先→不会乱；起点持久化→会准；默认页工厂→能恢复）。中英双语文档 + 双语 RELEASE_NOTES。DailyDesk 发布前照这个标准写 FAQ。

---

# 第四部分：不建议照搬的部分

| 内容 | 原因 |
|---|---|
| 12 列 CSS Grid 具体实现 | Flutter 用 `GridView`/`CustomMultiChildLayout`，实现方式完全不同；学**交互规格**（列吸附、Esc 取消、参考线、lockWidth 降级）即可，代码不可移植 |
| 用户自定义 `.js` 脚本组件 + 热重载 | Dart 没有等价的动态脚本生态，强上 Dart VM 动态编译得不偿失；DailyDesk 的扩展位走「静态编译的模块包 + WidgetRegistry」即可 |
| 与 Obsidian Vault 的深度耦合（笔记扫描、批注中心、微信收件箱、RSS/OPML） | 领域不同：它是笔记软件的看板投影，你是独立 GTD 数据库应用 |
| `createId()` 的实现 | `Math.random() + Date.now()` 有碰撞概率且无排序性；DailyDesk 建议 ULID（时间有序，利于 LWW 同步排序） |
| 泛 RSS/媒体聚合方向 | 与「深度工作」定位冲突，DailyDesk 不建议跟进 |

---

# 附录：落地任务清单（可直接插入 design-spec 第 9 章 WBS）

按优先级排序，标注对应本文档章节：

| # | 任务 | 插入阶段 | 对应章节 |
|---|---|---|---|
| T-A1 | `WidgetRegistry` + `DailyWidgetDefinition` + `WidgetInstance` 数据模型（Drift 布局表只存 kind+w+h+config） | Phase 0 / 1 | 1.1 |
| T-A2 | `WidgetContext`：registerInterval / registerCleanup / isAlive / saveConfig / rerender | Phase 1 | 1.2 |
| T-A3 | `normalizeWith` / `clampInt` / `toStringList` 的 Dart 版 + 单元测试 | Phase 1 | 1.3 |
| T-A4 | `sanitizeLayout()` 入口清洗 + activePageId 孤儿回退 | Phase 1 | 3.3 |
| T-A5 | 番茄钟改「存 started_at 时间戳」持久化策略 + 绝对时刻提醒调度 | Phase 3 | 1.4 |
| T-A6 | 拖拽拉伸四重取消保护 + 窄屏 lockWidth + 键盘逐格调整 + 虚线框跟随 | Phase 3 | 3.5 |
| T-A7 | 多工作台（页面）管理：复制/排序/删除兜底 | Phase 3 | 3.1 |
| T-A8 | 布局 JSON 导入导出（导入重新生成 id + 三重防御） | Phase 3 | 3.2 |
| T-A9 | 编辑模式卡片操作组：前移/后移/复制/删除 | Phase 3 | 3.6 |
| T-A10 | 网格设置三件套（行高/间距/最大宽度）+ layoutOnly 分层刷新 | Phase 3 | 3.4 |
| T-A11 | CI 门禁：版本一致性校验 + 体积阈值 + 网络调用白名单扫描 | Phase 5 | 1.6 / 1.7 |
| T-A12 | `DailyDeskApi`（version:1）接口预定义 + 占位卡片渲染 | Phase 5（仅预埋） | 1.5 |

---

*本文档生成于对 home-pages v0.3.1 源码（registry/types/api/settings/view/modals/verify-bundle/release.yml）的完整通读，所有「它怎么做的」均引自源码原文，非推测。*
