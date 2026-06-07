# 文档优化规划：让人快速上手、学会、理解机制

**范围：** `docs/`（新增 getting-started / concepts / cookbook，扩充 pipeline 与 ref）  
**日期：** 2026-06-06  
**一句话目标：** 让一个没接触过 Mkit 的开发者，能在 30 分钟内跑通一个 demo、在半天内改出自己的内容、在一周内理解整套运行机制。

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

---

## 一、现状诊断（按阶段重述）

### ① 看懂——缺"心智模型"层
- `docs/readme.md` 讲清了分层和数据模型，但停在"是什么"，没讲"一个请求进来后各层之间如何交接、为什么要这么拆"。
- `pipeline.md` 的 30+ 条管线是 `text` 箭头伪代码，能看出步骤顺序，但看不出**数据如何在对象间流动**、**哪些是同步调用哪些是信号回调**。
- 反复出现的核心词汇（Definition / Instance / Controller / System；Saveable vs SaveableComponent；三种 service flavor）散落在 CLAUDE.md 和各 ref 页，没有一处统一的**术语表**。

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

包含六块，**每块用同一个贯穿例子**（玩家攻击 field_beast）讲，避免抽象：

1. **一条主管线的心智模型**：`Input → Command → HFSM → Action → Effect → Domain → Event → 表现`。逐段讲：每一步**产出什么对象、交给谁、为什么要这一跳**（命令为什么和效果解耦？为什么要 Action 这一层？）。配一张**时序图**（玩家、CommandRouter、StateMachine、CombatResolver、HealthComponent、EventRouter 之间的调用与信号）。
2. **Resource / Instance / Node 三分**：为什么静态配置、运行时状态、场景行为要拆开；用 `AbilityDefinition → AbilityInstance → AbilityController` 走一遍。配**数据流图**。
3. **Service 的三种 flavor**：Node service / RefCounted service / Utility class 各自何时用、怎么取（统一走 `ServiceRegistry.get_service("id") as T`）。配一张 bootstrap 启动时序 + service id 对照表（顺带补上 docreview Q2）。
4. **两条存档契约**：`Saveable`（全局，按 save_id）vs `SaveableComponent`（实体内，按节点名）何时选哪个、谁来收集——这是最容易踩坑的机制。
5. **扩展点地图（框架的接缝在哪）**：一张表讲清"哪些是固定主干、哪些地方插你自己的逻辑"。理解了"什么固定、什么可换"就抓住了机制本质。至少覆盖：自定义 `GameEffect` / `Condition` / `GameAction` / `State` / `Brain` / service 实现，以及 override 钩子（`GameBootstrap._initialize_runtime_systems` / `_load_profile`、`Interactable._interact_impl`、`SaveableComponent.to_save_data`）。每个扩展点标明：父类、要实现的方法、谁来调用它、对应的 cookbook recipe。
6. **反模式与设计取舍（❌/✅ 对照）**：把 CLAUDE.md 里的硬规则转成"别这么做 / 应该这样 / 为什么"对照——如反向依赖 `game/`、把 RefCounted service 改成 Node、绕过 `ProgressionSystem` 直接改 `ProgressionState`、用裸 Dictionary 穿过核心 API。理解边界即理解机制。

并在文档库内新增**术语表** `docs/glossary.md`：一句话定义所有反复出现的名词（Command / Action / Effect / Condition / Definition / Instance / Controller / System / Resolver / Service / Saveable / Blackboard / GameplayContext …），每条带一个跳转链接到主文档。让新人遇到生词随时能查。

**图的标准**：用 Mermaid（`sequenceDiagram` / `flowchart`），纯文本可 diff、可在 `index.html` 与多数 Markdown 渲染器中显示。至少产出：主管线时序图、Resource/Instance/Node 数据流图、bootstrap 启动时序图、战斗伤害结算时序图。

### 产物 3：Pipeline 代码示例（服务"自己写"）— 扩充 `docs/pipeline.md`

在每条 pipeline 末尾增加 `### 代码示例`（不动现有伪代码），优先级如下：

| 优先级 | 管线 | 原因 |
|--------|------|------|
| P0 | Runtime Bootstrap / Main Gameplay | 入门必经、核心主干 |
| P1 | Ability Cast / Damage Resolution / Effect Execution | 最复杂、最常调试、几乎所有系统都用 |
| P2 | Entity Spawn / Event Notification / HFSM Transition | demo 基础、解耦关键、理解难点 |
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
  09_meta_upgrade.md           # 定义元升级、解锁内容、持久化（P3）
  10_save_custom_system.md     # 给新系统加存档支持（P3）
```

每篇 recipe 固定结构（强制一致，降低学习成本）：

```markdown
# Recipe N：标题  ·  难度：★☆☆  ·  预计 15 分钟

## 你将做到
一句话 + 一张做完后的效果示意。

## 前置
- 已跑通 Recipe 01
- 涉及的概念：[Resource/Instance/Node 三分](../concepts.md#…)

## 心智模型（30 秒）
这个任务在主管线的哪一段、动到哪几层（一句话 + 小图）。

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

**批次 B（P2）**：`EntitySpawner`、`EntityRoot`、`ActionRunner`、`DamageRequest`、`DungeonGenerator`、`LootSystem`、`InventoryController`、`QuestSystem`——各补 1–2 个 Level 2 场景示例。

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
6. **图能 diff**：所有图用 Mermaid 文本，不用截图。

---

## 六、验收标准（怎么算"真的更容易学了"）

产出页面 ≠ 达成目标。每阶段定义**可检验**的成功标准，避免"作者觉得显然、读者依旧卡住"：

| 阶段 | 验收标准（可检验） |
|------|-------------------|
| 跑通 | 没接触过 Mkit 的人只靠 getting_started，30 分钟内运行 demo + 完成"改一行"看到变化，全程不提问 |
| 看懂 | 读完 concepts 能用自己的话复述"玩家攻击到扣血"经过哪些层、为什么命令与效果要解耦；生词都能用 glossary 自助解决 |
| 照着改 | 只靠 recipe 02 能独立加出一个新技能并在 demo 里释放成功；遇到的报错都能在"常见错误"表里找到 |
| 自己写 | 照 pipeline 代码示例 + 扩展点地图，能写出一个自定义 `GameEffect` 并通过一个 GUT 测试 |
| 调试 | 任一 pipeline 行为不符预期时，能用 debugging 指南的工具（DebugOverlay / recent_events / trace）定位到出问题的那一跳 |

**验证方式：** 每完成一个 phase，请一位没参与该模块的人按文档实操一次（onboarding dry-run），记录卡点回灌文档。真人 dry-run 比作者自审更能暴露盲区。

---

## 七、实施计划（按学习者价值排序）

### Phase 1：先让人能"跑通 + 看懂"（约 3 天，最高价值）
- P1.1 新增 `docs/getting_started.md`（5 分钟跑通 + 学习地图 + 改一行 + cheat sheet）。
- P1.2 新增 `docs/concepts.md`（主管线心智模型 + 三分 + service flavor + 存档契约 + 扩展点地图 + 反模式对照，含 4 张 Mermaid 图）。
- P1.3 新增 `docs/glossary.md`、`docs/debugging.md`；改造 `readme.md` 顶部加新手入口；**把新文档接入 `index.html` 的 `navGroups`（新增「新手入门」「Cookbook」两组）**。
- P1.4 给 `village_rpg` 关键脚本加文档锚注释，标注其演示的 pipeline / recipe。

### Phase 2：让人能"照着改"（约 3 天）
- P2.1 Cookbook 骨架 + `01_run_the_demo`、`02_add_ability`、`03_add_enemy_in_room`（三篇打通"概念→改动→demo 实物"闭环）。
- P2.2 `04_custom_effect`、`05_add_quest`。

### Phase 3：让人能"自己写"（约 3 天）
- P3.1 pipeline P0/P1 六条加 `### 代码示例`（Bootstrap / Main Gameplay / Ability Cast / Damage Resolution / Effect Execution / Event Notification），并加 concepts/cookbook 互链。
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
