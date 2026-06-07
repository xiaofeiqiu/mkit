# 文档优化规划：让人快速上手、学会、理解机制

**范围：** `docs/`（新增 getting-started / concepts / cookbook，扩充 pipeline 与 ref）  
**日期：** 2026-06-06  
**一句话目标：** 让一个没接触过 Mkit 的开发者，能在 30 分钟内跑通一个 demo、在半天内改出自己的内容、在一周内理解整套运行机制。

---

## 进度追踪（Progress Tracker）

> 完成一项就把 `[ ]` 改成 `[x]`。详细说明见对应章节（第七章实施计划）。

**基础设施**
- [ ] 文档站支持 Mermaid 渲染（`docs/index.html` + vendored `docs/vendor/mermaid.min.js`；`docs/readme.md` Runtime Pipeline 已作示范）

**Phase 1 — 先让人能"跑通 + 看懂"**（易学 + 易理解）
- [ ] P1.1 `docs/getting_started.md`（5 分钟跑通 + 学习地图 + 改一行 + cheat sheet）
- [ ] P1.2 `docs/concepts.md`（主管线心智模型 + Resource/Instance/Node 三分 + service flavor + 存档契约 + 扩展点地图 + 反模式对照 + **动画两通道集成**，含 5 张图）
- [ ] P1.3 `docs/glossary.md` + `docs/debugging.md`；`readme.md` 顶部新手入口；接入 `index.html` 的 `navGroups`（新增「新手入门」「Cookbook」两组）；根 `README.MD` 首链接指向 `docs/getting_started.md`
- [ ] P1.4 给 `village_rpg` 关键脚本加文档锚注释
- [ ] ✅ **P1 验收**：找一位没接触过 Mkit 的人 dry-run——30 分钟内跑通 demo + 改一行见效（不提问）；能复述"攻击→扣血"的分层与解耦原因；生词都能在 glossary 自助解决；**能说清"加一个技能，我负责什么、mkit 负责什么"**（详见第六章；卡点回灌文档后才可勾选）

**Phase 2 — 让人能"照着改"**（易用）
- [ ] P2.1 Cookbook 骨架 + recipe `01_run_the_demo` / `02_add_ability` / `03_add_enemy_in_room`
- [ ] P2.2 recipe `04_custom_effect` / `05_add_quest`
- [ ] P2.3 recipe `09_hook_up_animation`（核心动画机制落地：AnimationPlayer + 攻击/读条动画随 Action 时钟播放 + 受击 VFX 随事件触发）
- [ ] ✅ **P2 验收**：同一人只靠 recipe `02` 独立加出新技能并在 demo 释放成功——不看 addon 源码、不提问；所有报错都能在"常见错误"表里找到

**Phase 3 — 让人能"自己写"**（易用 + 易理解）
- [ ] P3.1 pipeline P0/P1 六条 + Animation & Presentation 管线加 `### 代码示例` + concepts/cookbook 互链
- [ ] P3.2 批次 A 的 14 个核心类补 3–4 例，同步修复 docreview D1–D5 / Q1
- [ ] ✅ **P3 验收**：有 Godot 基础但没写过 Mkit 扩展的人，照 pipeline 示例 + 扩展点地图写出自定义 `GameEffect` 并通过 GUT 测试；并能只用 debugging 指南定位一个植入的 bug

**Phase 4 — 补全与防腐（按需）**
- [ ] 剩余 pipeline 示例、批次 B/C ref、cookbook `06`–`10`
- [ ] `tools/check_docs_sync.py` + `make docs-check` + CI demo 冒烟
- [ ] ✅ **P4 验收**：`make docs-check` 通过（无断链 / 无漏 ref / API 一致 / 新文档已接入 nav）；CI demo 冒烟通过；抽查 5 个示例均可粘贴运行

---

## 〇、设计原则：围绕"学习者旅程"，而不是"补充示例"

上一版规划把目标定为"每个 class / pipeline 多加几段代码"。但"代码示例多"不等于"容易学会"。一个新人真正的卡点不是某个方法怎么调，而是：

> "我从哪里开始？这一坨东西整体是怎么转起来的？我想做 X，该动哪几个文件？"

所以本规划以**学习者的四个阶段**为主轴，每个文档产物都明确服务于某个阶段：

| 阶段 | 学习者的问题 | 现状缺口 | 本规划的答案 |
|------|-------------|----------|-------------|
| ① 看懂 | "这框架整体怎么运作？" | 只有分层概览 + 伪代码，缺心智模型与图 | **概念与心智模型文档** + 数据流 / 时序图 |
| ② 跑通 | "怎么让它先跑起来？" | 无新手入口，demo 没被当教学资源 | **Getting Started** + 以 `village_rpg` 为黄金样例 |
| ③ 照着改 | "我想加个技能 / 敌人 / 任务，动哪里？" | ref 页孤立，无端到端任务指引 | **任务导向 Cookbook**（每篇对应 demo 里能跑的改动） |
| ④ 自己写 | "完整调用链长什么样？为什么这么设计？" | pipeline 全是伪代码，无 GDScript | **pipeline 代码示例** + **ref 页分级示例** |

这些产物不是并列的"几批活"，而是一条**由浅入深、互相引用**的学习路径。下面分别展开。

**第五个设计原则：始终清晰标明"用户负责 vs mkit 负责"的边界。**

学习者最常见的困惑不是"某个 API 怎么调"，而是"这块逻辑到底该我写还是框架帮我做？"。所有文档——图、表、步骤——都必须让这条边界一目了然：

- **图**：用颜色区分。蓝色（`#4A90D9`）= mkit 内部实现，学习者不需要动；绿色（`#7ED321`）= 用户扩展点，学习者在这里写自己的内容。Mermaid 用 `classDef` 实现，见"图的标准"节。
- **表**：扩展点地图和 recipe 步骤里，在"由谁负责"列或标注（`[用户]` / `[mkit]`）明确归属。
- **Recipe**：每篇固定模板里加"你负责 / mkit 负责"一节（见产物 4 模板），让读者在动手前先知道自己要改哪几行、框架兜底的是什么。
- **验收**：每个 Phase 的验收条目里加一条"能清楚说出哪些部分是自己负责的"（见第六章）。

---

## 一、现状诊断（按阶段重述）

### ① 看懂——缺"心智模型"层
- `docs/readme.md` 讲清了分层和数据模型，但停在"是什么"，没讲"一个请求进来后各层之间如何交接、为什么要这么拆"。
- `pipeline.md` 的 30+ 条管线是 `text` 箭头伪代码，能看出步骤顺序，但看不出**数据如何在对象间流动**、**哪些是同步调用哪些是信号回调**。
- 反复出现的核心词汇（Definition / Instance / Controller / System；Saveable vs SaveableComponent；三种 service flavor）散落在 CLAUDE.md 和各 ref 页，没有一处统一的**术语表**。
- **动画 / 表现如何接入主管线**——Action 驱动 vs 事件反馈两条通道、`Presentation/AnimationPlayer` 约定、`facing` / `set_direction`——这条**核心机制完全没有文档**。读者只能自己逐个翻 `timed_attack_action.gd` / `cast_action.gd` / `feedback_system.gd` / `vfx_spawner.gd` 才能拼出全貌，是目前最大的机制盲区之一。

### ② 跑通——缺"新手入口"
- 文档入口 `readme.md` 是参考手册式索引，不是"从这里开始"。新人面对 133 个 ref + 30 条 pipeline 不知先读哪篇。
- 仓库已有完整可跑的 `game/demo/village_rpg`（村庄→对话接任务→试炼房战斗→奖励→存档的完整 RPG loop）和 `demo_testing.md`，**这是最好的教学资源，却几乎没被文档当作学习起点**。

### ③ 照着改——缺"任务导向配方"
- 想"加一个有读条的火球术"，得自己跨 5 个 ref 页拼出全貌（AbilityController / AbilityDefinition / CastAction / EffectExecutor / GameplayContext），没有一篇把它们串起来。
- 没有"定义 .tres → 注册 database → 实体注册 → 运行触发"这条贯穿数据驱动全流程的指引。

### ④ 自己写——缺"可运行的完整调用链"
- pipeline 零 GDScript，没有"入口对象怎么造、service 怎么取、输出信号怎么接"。
- 部分核心类（`State`、`GameEffect`、`GameplayContext`）ref 页**没有任何使用示例**；薄弱类只有孤立单行片段，读者不知道"这段放进哪个文件的哪个方法"。

---

## 二、贯穿设计：以 `village_rpg` demo 为"黄金样例"

这是本次优化的关键杠杆，也是和上一版最大的区别。

**原则：每一个概念、每一条 pipeline、每一篇 recipe，都尽量指向 `game/demo/village_rpg` 里一段真实、能跑、有测试覆盖的代码。**

带来三个好处：

1. **可信**——示例不是凭空捏造的伪代码，而是"打开这个场景就能看到、运行就能验证"的真实代码，学习者可以边读边跑。
2. **抗腐烂**——示例源自真实 demo / GUT 测试，addon API 一旦变化、demo 跑挂，就会暴露文档过期（配合 Phase 4 的 `make docs-check`）。
3. **连贯**——所有文档共享同一套角色（player、field_beast、npc_elder、试炼房、长老任务），学习者不必每篇都重新建立上下文。

落地动作：
- 在 demo 关键脚本（如 `village_rpg_demo.gd`）顶部和关键方法处，用文档锚注释标注它演示的 pipeline / recipe（注意：addon 内禁止注释，但 `game/demo/` 不受此约束）。
- Cookbook 每篇 recipe 末尾给出"在 demo 里看实物"链接，指向对应场景与脚本行号。
- pipeline / ref 的 Level 2 示例优先**从 demo 真实代码节选**，而非新造。

---

## 三、五个文档产物

### 产物 1：Getting Started（服务"跑通"）— 新增 `docs/getting_started.md`

新手的唯一入口。目标：照着做就能在 30 分钟内看到东西在动。

结构：
1. **5 分钟跑通**：用什么 Godot 版本、`make ut` 验证环境、直接打开 `village_rpg_demo.tscn` 运行，看到村庄→战斗→奖励 loop。
2. **这局 demo 发生了什么**：一张图把刚才看到的画面对应到 5–6 条核心 pipeline（输入→命令→状态机→战斗→事件→反馈），点击图中节点跳到对应 pipeline / 概念文档。
3. **改一行试试**：引导做一处最小改动（如调一个 .tres 里的伤害数值或冷却），重跑看到变化——建立"数据驱动"的第一感觉。
4. **学习地图**：明确的阅读顺序——getting started → concepts → 跑通对应 pipeline → 照着 cookbook 改 → 查 ref 深入。把 133 个 ref 定位为"字典"而非"读物"。
5. **常用代码速查（cheat sheet）**：一屏放下最高频的几个 idiom——取服务（`ServiceRegistry.get_service("id") as T`）、发命令、建 `GameplayContext`、连事件、加 `StatModifier`。新人不必每次翻 ref 也能写出第一行代码。

同时**改造 `docs/readme.md` 顶部**：加一句醒目的"👉 新手从 [Getting Started](getting_started.md) 开始"，把 readme 还原为参考索引。

### 产物 2：概念与心智模型（服务"看懂 / 理解机制"）— 新增 `docs/concepts.md`

回答"整体怎么转、为什么这么设计"。这是上一版完全缺失、却对"理解机制"最关键的一层。

包含七块，**每块用同一个贯穿例子**（玩家攻击 field_beast）讲，避免抽象：

1. **一条主管线的心智模型**：`Input → Command → HFSM → Action → Effect → Domain → Event → 表现`。逐段讲：每一步**产出什么对象、交给谁、为什么要这一跳**（命令为什么和效果解耦？为什么要 Action 这一层？）。配一张**时序图**（玩家、CommandRouter、StateMachine、CombatResolver、HealthComponent、EventRouter 之间的调用与信号）。
2. **Resource / Instance / Node 三分**：为什么静态配置、运行时状态、场景行为要拆开；用 `AbilityDefinition → AbilityInstance → AbilityController` 走一遍。配**数据流图**。
3. **Service 的三种 flavor**：Node service / RefCounted service / Utility class 各自何时用、怎么取（统一走 `ServiceRegistry.get_service("id") as T`）。配一张 bootstrap 启动时序 + service id 对照表（顺带补上 docreview Q2）。
4. **两条存档契约**：`Saveable`（全局，按 save_id）vs `SaveableComponent`（实体内，按节点名）何时选哪个、谁来收集——这是最容易踩坑的机制。
5. **扩展点地图（框架的接缝在哪）**：一张表讲清"哪些是固定主干、哪些地方插你自己的逻辑"。理解了"什么固定、什么可换"就抓住了机制本质。至少覆盖：自定义 `GameEffect` / `Condition` / `GameAction` / `State` / `Brain` / service 实现，以及 override 钩子（`GameBootstrap._initialize_runtime_systems` / `_load_profile`、`Interactable._interact_impl`、`SaveableComponent.to_save_data`）。每个扩展点标明：父类、要实现的方法、谁来调用它、对应的 cookbook recipe。
6. **反模式与设计取舍（❌/✅ 对照）**：把 CLAUDE.md 里的硬规则转成"别这么做 / 应该这样 / 为什么"对照——如反向依赖 `game/`、把 RefCounted service 改成 Node、绕过 `ProgressionSystem` 直接改 `ProgressionState`、用裸 Dictionary 穿过核心 API。理解边界即理解机制。
7. **动画与表现的两条集成通道（核心机制，当前零文档）**：讲清"动画到底接在管线哪里、何时用哪条"，配一张两通道对照图。
   - **通道 A — Action 驱动（动画时机 = 玩法时机，同步）**：当动画节奏就是玩法节奏（攻击 startup/active/recovery、读条、冲刺 i-frame）时，由 **GameAction 拥有动画**。`TimedAttackAction._on_start()` 播 `"attack"`，**同一个 Action 时钟**在 active 窗口开关 Hitbox（`timed_attack_action.gd:13,17-28`）——动画与命中帧共用一个时钟，这是关键。`CastAction` 播 `animation_name` 持续 `duration`，结束/打断时回调 `source.on_cast_action_finished()`（`cast_action.gd:32-45`）。
   - **通道 B — 事件驱动反馈（动画是对既成事实的反应，解耦）**：受击闪白、死亡特效、伤害数字走 `EventRouter` → `FeedbackSystem` → `VFXSpawner` / `AudioManager`。FeedbackSystem 监听 `damage_applied` / `entity_died` 后调 `VFXSpawner.spawn("hit", pos)` → `node.play()`（`feedback_system.gd`、`vfx_spawner.gd:9-29`）——战斗代码完全不知道有特效。
   - **三个支撑约定**：① 节点路径接缝 `Presentation/AnimationPlayer`（Action 在此 `play()`，`has_animation` 检查后才播，找不到就静默跳过，所以无动画实体也能跑——demo player 当前是 `Visual` Polygon2D 占位）；② 朝向走 Blackboard 的 `facing`（move/idle/dash/attack 状态写，Hitbox 位置与精灵翻转读）；③ 生成体自定向 `set_direction(Vector2)`（投射物 / VFX 实现，`SpawnSceneEffect`、`VFXSpawner` 调用）。
   - **选哪条（心智模型）**：动画节奏 = 玩法节奏 → A（同一时钟驱动逻辑与画面）；动画是事后反应 → B（保持战斗与表现解耦）。

并在文档库内新增**术语表** `docs/glossary.md`：一句话定义所有反复出现的名词（Command / Action / Effect / Condition / Definition / Instance / Controller / System / Resolver / Service / Saveable / Blackboard / GameplayContext …），每条带一个跳转链接到主文档。让新人遇到生词随时能查。

**图的标准（Mermaid 已支持 ✅）**：`docs/index.html` 已加入 Mermaid 渲染——` ```mermaid ` 代码块会被渲染成图。mermaid.js 已 vendored 在 `docs/vendor/mermaid.min.js`（本地引用、离线可用，`make docs-server` 无需联网）。因此：
- **优先用 Mermaid**（`sequenceDiagram` / `flowchart`）画时序图与数据流图，纯文本可 diff。
- 渲染兼容性：文档站已支持；GitHub 原生支持；多数 IDE 插件支持。万一某处渲染器不支持，文档站有**降级样式**（把图源显示为等宽代码块，仍可读），不会崩。
- **配色规范（用户 vs mkit 边界，所有图强制执行）**：`flowchart` 类图必须包含以下 `classDef` 并按归属着色（`sequenceDiagram` 不支持 participant 着色，改用归属 Note，见本节末条）：
  ```
  classDef mkitCore  fill:#4A90D9,color:#fff,stroke:#2C6FAC  %% 蓝色 = mkit 内部，学习者不需改
  classDef userOwned fill:#7ED321,color:#fff,stroke:#5A9A18  %% 绿色 = 用户扩展点，学习者在这里写内容
  ```
  图例说明（放在每张图下方）：`🔵 蓝色 = mkit 负责 / 🟢 绿色 = 你负责`。时序图（`sequenceDiagram`）用矩形 Note 标注归属（`Note over X: [mkit]` / `Note over Y: [你]`）。
- 至少产出：主管线时序图、Resource/Instance/Node 数据流图、bootstrap 启动时序图、战斗伤害结算时序图、**动画两通道对照图（Action 驱动 vs 事件反馈）**。每张图均按上述规范标明 user/mkit 归属（flowchart 着色 / sequenceDiagram 用 Note）。
- 参考示范：`docs/readme.md` 的 Runtime Pipeline 已改用 Mermaid flowchart（后续同步补色）。

### 产物 3：Pipeline 代码示例（服务"自己写"）— 扩充 `docs/pipeline.md`

在每条 pipeline 末尾增加 `### 代码示例`（不动现有伪代码），优先级如下：

| 优先级 | 管线 | 原因 |
|--------|------|------|
| P0 | Runtime Bootstrap / Main Gameplay | 入门必经、核心主干 |
| P1 | Ability Cast / Damage Resolution / Effect Execution | 最复杂、最常调试、几乎所有系统都用 |
| P2 | Entity Spawn / Event Notification / HFSM Transition | demo 基础、解耦关键、理解难点 |
| P2 | **Animation & Presentation（新增管线）** | 核心机制、当前零文档；展示 Action 驱动 + 事件反馈两条通道如何挂到攻击/受击流程上 |
| P3 | Quest / Save·Load / Loot Roll / Inventory | RPG·Roguelike 常用集成 |
| P4 | 其余 20+ 条 | 按需补充 |

每段示例聚焦三件事（不必逐行覆盖管线）：**① 入口对象怎么造 ② service 怎么取 ③ 输出信号怎么接**。示例尽量从 `village_rpg` 节选并标注来源文件。每条 pipeline 顶部补一行"对应概念见 [concepts](concepts.md#…) / 对应配方见 [cookbook](cookbook/…)"，打通三层。

### 产物 4：任务导向 Cookbook（服务"照着改 / 自己写"）— 新增 `docs/cookbook/`

```
docs/cookbook/
  index.md                     # 配方总览 + 难度标注 + 推荐顺序
  01_run_the_demo.md           # 跑通并读懂 village_rpg（与 getting_started 衔接）
  02_add_ability.md            # 加一个有读条时间的技能（P0，涉及管线最多）
  03_add_enemy_in_room.md      # 在试炼房 spawn 一个带技能的敌人（P1，核心循环）
  04_custom_effect.md          # 实现一个自定义 GameEffect（P1，扩展基础）
  05_add_quest.md              # 长老对话接任务→击杀目标→提交奖励（P2，步骤最多）
  06_status_effect.md          # 加一个 DOT 状态效果（P2）
  07_loot_table.md             # 配一张带权重和条件的战利品表（P2，数据驱动范例）
  08_state_machine.md          # 为新实体定义 HFSM 状态树（P2，最难理解）
  09_hook_up_animation.md      # 给实体接上动画：Presentation/AnimationPlayer + 攻击/读条动画 + 受击 VFX（P1，核心机制）
  10_meta_upgrade.md           # 定义元升级、解锁内容、持久化（P3）
  11_save_custom_system.md     # 给新系统加存档支持（P3）
```

> recipe `09_hook_up_animation` 尤其关键：demo player 当前用 `Visual` Polygon2D 占位、没有真正的 `AnimationPlayer`，这篇带读者从占位升级到"攻击/读条动画随 Action 时钟播放 + 受击特效随事件触发"，把两条通道一次性走通——是"易用 + 易理解"动画机制的落地闭环。

每篇 recipe 固定结构（强制一致，降低学习成本）：

```markdown
# Recipe N：标题  ·  难度：★☆☆  ·  预计 15 分钟

## 你将做到
一句话 + 一张做完后的效果示意。

## 前置
- 已跑通 Recipe 01
- 涉及的概念：[Resource/Instance/Node 三分](../concepts.md#…)

## 你负责 / mkit 负责
| 你需要做的 | mkit 帮你做的 |
|-----------|-------------|
| 定义 .tres 配置文件（填写参数） | 解析并验证资源格式 |
| 在 ResourceDatabase 注册 | 运行时加载与缓存 |
| 在实体初始化时调用接线方法 | 执行逻辑、触发事件、更新状态 |
（每篇按实际内容填写，绿色 = 你，蓝色 = mkit；配一张按配色规范着色的小图）

## 心智模型（30 秒）
这个任务在主管线的哪一段、动到哪几层（一句话 + 小图，按配色规范标注用户/mkit 归属）。

## 步骤
1. 定义资源 .tres（字段逐项说明，标"必填/可选/默认值语义"）
2. 注册到 ResourceDatabase
3. 在实体初始化时接线
4. 运行触发

## 在 demo 里看实物
对应 `game/demo/village_rpg/...` 的场景与脚本行号。

## 常见错误
| 现象 | 原因 | 修复 |
（出问题先翻 [debugging 指南](../debugging.md)）

## 试一试（巩固）
一个小挑战，靠动手固化理解（如"再加第二个目标到这个任务里"）。

## 延伸
相关 pipeline / ref / concepts 链接。
```

关键改进（相比上一版）：每篇都有**"心智模型 30 秒"**（先理解再动手）和**"在 demo 里看实物"**（连回黄金样例），而不只是堆步骤；末尾加一道**"试一试"**小挑战（如"自己给任务加第二个目标"），靠动手而非只读来固化理解。

### 产物 5：调试与可观测性指南（服务"理解机制 + 排错"）— 新增 `docs/debugging.md`

人是通过"看着系统跑"来理解机制的。Mkit 已有现成的可观测设施，却没有一篇文档教学习者怎么用它们看清管线到底做了什么。这是理解机制最快、也最被忽视的路径。

内容（每项配"怎么看 + 看到什么 + 能定位什么问题"）：
- **`DebugOverlay`**：实时看某实体的当前状态路径、HP、最近命令、最近事件——一眼看出"卡在哪个状态/有没有收到命令"。
- **`EventRouter.recent_events`**：回放最近发生的领域事件，确认"该发的事件发了没、顺序对不对"。
- **`EffectExecutor.recent_results` / trace**：看效果链每一步成功/失败与失败原因，定位"技能放了但没生效"。
- **`CombatResolver` 的 trace**：看伤害结算每阶段中间值（base → 攻击力 → 暴击 → 防御 → final），调平衡和查"伤害数字不对"。
- **`StateMachine.last_transition_reason` / `last_failed_transition_reason`**：查"为什么没切状态/切换被拒"。
- **固定随机种子复现**：用 `RandomService` 固定 seed 复现一次战斗/掉落，把偶发 bug 变成可重放。
- **动画不播 / 朝向不对**：查 `Presentation/AnimationPlayer` 是否存在、`has_animation(name)` 是否为真（Action 找不到会**静默跳过**，最易踩）、Blackboard 的 `facing` 有没有被状态写入、生成体是否实现 `set_direction`——这是动画两条通道最常见的断点。

并给一张**"症状 → 先看哪个工具"速查表**（如"技能按了没反应"→先看 DebugOverlay 当前状态 + EffectExecutor trace）。这张表本身就是一份机制自检清单。

### 让新文档被找到（可发现性，关键落地项）

`index.html` 的侧边栏导航是**写死的 `navGroups` 数组**（`docs/index.html:517`），并非扫描目录。新增的 getting_started / concepts / glossary / debugging / cookbook 若不手动加进去，文档站侧边栏不会列出，等于白写。落地动作：
- 在 `navGroups` 新增两个分组：**「新手入门」**（getting_started → concepts → glossary → debugging，按推荐阅读顺序排列）和 **「Cookbook」**（index + 各 recipe）。
- 「Overview」组置顶加 getting_started 链接。
- 同步更新 `readme.md` 索引与 cookbook 子目录的相对链接（注意 `cookbook/` 下指向 `../ref/`、`../pipeline.md` 的层级）。

---

## 四、Class Ref 增补（服务"自己写"的细节查阅）

ref 是字典而非读物，定位下沉到产物 1-4 之后，但核心类仍需补到"看一眼就会用"。

**批次 A（P0/P1，立即补，每个 3–4 例）**

| 类 | 现状 | 重点补充 |
|----|------|----------|
| `GameBootstrap` / `ServiceRegistry` | 伪代码 / 1 例 | 加自定义服务、测试中注册 mock、防御性 has/get |
| `GameCommand` / `CommandRouter` / `CommandReceiver` | 2 / 1 / 缺 | AI 发命令、注册 receiver、失败处理 |
| `StateMachine` / `State` | 2 / **0** | 子状态转换、blackboard 传值、自定义 State 子类 |
| `GameEffect` / `EffectExecutor` / `GameplayContext` | **0** / 1 / **0** | 自定义 Effect、stop_on_failure、构建并跨系统传 context |
| `EventRouter` / `AbilityController` | 2 / 3 | 连 UI 监听、自定义 DomainEvent、多充能、条件失败 |
| `CombatResolver` / `HealthComponent` / `StatsComponent` | 2 / 1 / 1 | 带状态附加的 DamageRequest、trace 调试、监听 died、临时 modifier 叠加 |

**批次 B（P2）**：`EntitySpawner`、`EntityRoot`、`ActionRunner`、`DamageRequest`、`DungeonGenerator`、`LootSystem`、`InventoryController`、`QuestSystem`，以及**动画相关的 `TimedAttackAction`、`CastAction`、`VFXSpawner`、`FeedbackSystem`**（重点写清 `Presentation/AnimationPlayer` 约定、Action 时钟与 active 帧的关系、`set_direction` / `facing`）——各补 1–2 个 Level 2 场景示例。

**批次 C（P3/P4，有余力）**：Effect / Condition 子类、平台 mock 类——各补一个"在 .tres 配置 + 运行触发"示例。

**配合修复**：批次 A 同步清理 docreview.md 的 D1–D5 偏差与 Q1 模板化字段描述。字段说明必须回答：由谁写、由谁读、生命周期、默认值语义。

---

## 五、示例分级与质量标准

### 三级示例（按信息密度）

- **Level 1 微示例**（≤10 行，用于 ref 小节）：单方法最小调用，强类型，必要前置变量就地声明。
- **Level 2 场景示例**（10–40 行，用于 pipeline / 复杂方法 / recipe）：含背景注释行、前置声明、**成功 + 失败两条路径**，可直接放进 demo 跑。
- **Level 3 配方**（用于 cookbook）：从零到可运行，含场景树、.tres 配置、代码、常见错误。

### 质量门槛（所有新增示例必须满足）

1. **可运行**：配合已配置的 GameBootstrap 能跑，不留"这个变量哪来的"悬念；Level 2/3 尽量源自 `village_rpg` 真实代码。
2. **强类型**：一律 `as TypeName` 或显式类型，不写裸 `var x = ...`。
3. **取服务统一**：`ServiceRegistry.get_service("id") as ClassName`，不直接持 autoload 引用。
4. **有失败分支**：凡返回 bool 的方法（`can_cast` / `add_item` / `spend_currency`）必须演示失败处理。
5. **注释只写 WHY**：解释"为什么用 CONNECT_ONE_SHOT"，不解释 GDScript 语法。
6. **图能 diff 且能渲染**：用 Mermaid 文本（文档站已支持渲染，GitHub / IDE 也支持），不用截图。

---

## 六、验收标准（每个 Phase 一条，标尺：易学 / 易用 / 易理解）

产出页面 ≠ 达成目标。**每个 Phase 必须通过验收才算完成**，验收靠**真人实操 dry-run**或**可运行的检查**，不靠作者自审——作者觉得显然的地方，恰恰是读者卡住的地方。

### Phase 1 验收 —— 易学 + 易理解
- **谁来验**：一位完全没接触过 Mkit 的开发者。
- **怎么算过**（须全部满足）：
  1. 只看 `getting_started`，**30 分钟内**跑起 `village_rpg` demo，并完成一处"改一行 .tres 数值"看到游戏内变化——全程不提问。
  2. 看完 `concepts`，能用**自己的话**复述"玩家攻击 → 扣血"经过哪些层、为什么命令要和效果解耦。
  3. 阅读中遇到的生词，都能在 `glossary` 自助查到，不需要问人。
  4. **边界验收**：看完 `concepts` 的扩展点地图后，能不翻源码地说出"加一个新技能，我需要自己写哪几个文件、mkit 帮我处理哪些"——答案与扩展点地图一致，不遗漏也不多填。图中蓝色节点和绿色节点的区分无歧义。

### Phase 2 验收 —— 易用
- **谁来验**：通过了 Phase 1 验收的同一人。
- **怎么算过**（须全部满足）：
  1. 只靠 recipe `02_add_ability`，**独立加出一个新技能并在 demo 里释放成功**；不看 addon 源码、不提问；过程中所有报错都能在该 recipe 的"常见错误"表里找到对应条目。
  2. **边界验收**：看完 recipe 的"你负责 / mkit 负责"节后，能准确指出"这一步是我填数据，那一步是 mkit 跑逻辑"——不把需要自己写的步骤误认为框架自动完成，也不把框架已处理的部分重复实现。

### Phase 3 验收 —— 易用 + 易理解
- **谁来验**：一位有 Godot 基础、但没写过 Mkit 扩展的开发者。
- **怎么算过**（须全部满足）：
  1. 照 pipeline 代码示例 + `concepts` 的扩展点地图，写出一个自定义 `GameEffect` 并**通过一个 GUT 测试**。
  2. 给 demo 故意植入一个 bug（如"技能放了不生效"），该开发者**只用 `debugging` 指南的工具**（DebugOverlay / recent_events / EffectExecutor trace）就能定位到出问题的那一跳。
  3. **边界验收**：自定义 `GameEffect` 实现中，无多余的胶水代码（重复实现 mkit 已内置的注册/调度逻辑），也无遗漏的必要代码（未填 mkit 要求实现的接口方法）——代码 review 时发现的"误越界"或"误遗漏"条数为零。

### Phase 4 验收 —— 防腐（文档长期可信）
- **怎么算过**：`make docs-check` 通过（无断链、无漏 ref、公共 API 与接口块一致、新文档已接入 `navGroups`）；CI 的 demo 冒烟通过；抽查 5 个示例均可直接粘贴运行。
- **边界验收**：`make docs-check` 额外检查：① 所有 recipe 文件均包含"你负责 / mkit 负责"节（缺失则报错）；② Mermaid 图块均标明 user/mkit 归属——`flowchart` 含 `classDef mkitCore` 与 `classDef userOwned` 声明、`sequenceDiagram` 含 `[mkit]`/`[你]` 归属 Note（缺失则报 warning）。

**通用规则**：每次 Phase 验收都记录 dry-run 的卡点，**回灌对应文档后才关闭该 Phase**。验收本身就是 tracker 里的一项任务，必须勾上才算 Phase 完成。

---

## 七、实施计划（按学习者价值排序）

### Phase 1：先让人能"跑通 + 看懂"（约 3 天，最高价值）
- P1.1 新增 `docs/getting_started.md`（5 分钟跑通 + 学习地图 + 改一行 + cheat sheet）。
- P1.2 新增 `docs/concepts.md`（主管线心智模型 + 三分 + service flavor + 存档契约 + 扩展点地图 + 反模式对照 + 动画两通道集成，含 5 张 Mermaid 图）。
- P1.3 新增 `docs/glossary.md`、`docs/debugging.md`；改造 `docs/readme.md` 顶部加新手入口；**把新文档接入 `index.html` 的 `navGroups`（新增「新手入门」「Cookbook」两组）**；在**仓库根 `README.MD` 的 Getting Started 段落把首链接指向 `docs/getting_started.md`**（它当前只指向 `docs/readme.md`，是比文档站更上一级的入口）。
- P1.4 给 `village_rpg` 关键脚本加文档锚注释，标注其演示的 pipeline / recipe。

### Phase 2：让人能"照着改"（约 3 天）
- P2.1 Cookbook 骨架 + `01_run_the_demo`、`02_add_ability`、`03_add_enemy_in_room`（三篇打通"概念→改动→demo 实物"闭环）。
- P2.2 `04_custom_effect`、`05_add_quest`。
- P2.3 `09_hook_up_animation`（核心动画机制落地，把两条通道一次性走通）。

### Phase 3：让人能"自己写"（约 3 天）
- P3.1 pipeline P0/P1 六条 + Animation & Presentation 管线加 `### 代码示例`（Bootstrap / Main Gameplay / Ability Cast / Damage Resolution / Effect Execution / Event Notification / Animation），并加 concepts/cookbook 互链。
- P3.2 批次 A 的 14 个核心类补 3–4 例，同步修复 docreview D1–D5 / Q1。

### Phase 4：补全与防腐（按需）
- 剩余 pipeline 示例、批次 B/C ref、cookbook 06–10。
- 新增 `tools/check_docs_sync.py` + `make docs-check`（docreview Q3）：校验 ref 覆盖、`## 文件`路径、内部断链、公共 API 与接口块一致性、**新文档已接入 `navGroups`**；CI 跑 demo 冒烟以防示例腐烂。

---

## 八、不在本规划范围内
- **docreview D1–D7 的准确性修复**：已在 `spec/docreview.md` 有独立建议，本规划只在批次 A 顺带带上 D1–D5。
- **Layer 概览文档**（kernel/module/platform_layer.md）：结构清晰，不需示例扩充，仅在 glossary / concepts 中链接。
- **CLAUDE.md 改动**：现有内容已够指导代码规范。
- **新增 class / 功能**：本规划只优化文档与 demo 注释，不扩展 addon 功能（demo 注释除外）。
