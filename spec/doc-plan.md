# Mkit 文档规划

**目标：** 让使用 mkit 构建游戏的开发者能够 ①快速上手、②理解机制、③找到答案、④照着写出代码。  
**原则：** 以插件源码为唯一 source of truth，不暴露 `game/demo/` 内部实现，所有示例基于真实 API。  
**日期：** 2026-06-07

---

## 一、文档站结构

```
docs/
├── index.html                        # 文档站入口（Mermaid 已支持）
├── readme.md                         # 项目概览 + 架构速览
├── getting_started.md                # 5 分钟快速上手
├── architecture.md                   # 层架构 + 依赖规则 + 服务注册
├── concepts.md                       # 核心心智模型
├── glossary.md                       # 术语表
├── debugging.md                      # 调试工具 + 常见错误
├── pipeline.md                       # 所有管线（伪代码 + 代码示例）
├── cookbook/
│   ├── index.md                      # 主线路径图 + 各篇难度/预计时间
│   ├── 01_bootstrap.md               # [主线 1] 游戏启动，services 在线
│   ├── 02_player_entity.md           # [主线 2] 玩家实体 + StateMachine + 输入命令
│   ├── 03_health_and_stats.md        # [主线 3] 血量 / 属性 / 伤害 / 死亡
│   ├── 04_attack_action.md           # [主线 4] 攻击动作时序 + Hitbox
│   ├── 05_ability.md                 # [主线 5] 可配置技能（AbilityDefinition）
│   ├── 06_ai_enemy.md                # [主线 6] 敌人实体 + AI Brain
│   ├── 07_room.md                    # [主线 7] 房间 + RunDirector 多房间序列
│   ├── 08_loot_and_rewards.md        # [主线 8] 房间清空触发战利品与奖励选择
│   ├── 09_npc_dialogue.md            # [主线 9] NPC 交互 + 对话树
│   ├── 10_quest.md                   # [主线 10] 任务接受 / 推进 / 完成
│   ├── 11_progression_and_save.md    # [主线 11] XP / 升级 / 全局存读档  ← 完整 RPG loop
│   ├── 12_status_effects.md          # [扩展] DOT / buff 状态效果
│   ├── 13_animation.md               # [扩展] 动画接入（Action 驱动 + 事件 VFX）
│   └── 14_shop.md                    # [扩展] 商店购买
└── ref/
    ├── kernel/
    │   ├── GameBootstrap.md
    │   ├── ServiceRegistry.md
    │   ├── GameCommand.md
    │   ├── CommandService.md
    │   ├── CommandReceiver.md
    │   ├── BuiltinCommands.md
    │   ├── GameAction.md
    │   ├── ActionService.md
    │   ├── ActionContext.md
    │   ├── GameEffect.md
    │   ├── EffectService.md
    │   ├── EffectResult.md
    │   ├── SpawnSceneEffect.md
    │   ├── LogEffect.md
    │   ├── GameplayContext.md
    │   ├── Blackboard.md
    │   ├── DomainEvent.md
    │   ├── EventService.md
    │   ├── ContentDefinition.md
    │   ├── ContentService.md
    │   ├── ContentValidationResult.md
    │   ├── ResourceDatabase.md
    │   ├── Saveable.md
    │   ├── SaveableComponent.md
    │   ├── SaveService.md
    │   ├── SaveMigration.md
    │   ├── State.md
    │   ├── StateMachine.md
    │   ├── Condition.md
    │   ├── ConditionEvaluator.md
    │   ├── TargetInRangeCondition.md
    │   ├── TimeService.md
    │   ├── RandomService.md
    │   ├── SceneService.md
    │   ├── PoolService.md
    │   ├── AudioService.md
    │   ├── AnalyticsService.md
    │   ├── AdService.md
    │   ├── IAPService.md
    │   ├── CloudSaveService.md
    │   └── DebugOverlay.md
    └── modules/
        ├── AbilityDefinition.md
        ├── AbilityInstance.md
        ├── AbilityController.md
        ├── CastAction.md
        ├── CooldownReadyCondition.md
        ├── Brain.md
        ├── SimpleAIEnemyBrain.md
        ├── CombatService.md
        ├── DamageRequest.md
        ├── DamageResult.md
        ├── HitboxComponent.md
        ├── HurtboxComponent.md
        ├── DealDamageEffect.md
        ├── DashAction.md
        ├── TimedAttackAction.md
        ├── DialogueDefinition.md
        ├── DialogueNode.md
        ├── DialogueChoice.md
        ├── DialogueRuntime.md
        ├── DialogueInteractable.md
        ├── DialogueService.md
        ├── EntityDefinition.md
        ├── EntityIdentity.md
        ├── EntityRoot.md
        ├── EntitySpawner.md
        ├── HealthComponent.md
        ├── ResourcePoolComponent.md
        ├── HealEffect.md
        ├── Interactable.md
        ├── InteractionComponent.md
        ├── ItemDefinition.md
        ├── ItemInstance.md
        ├── InventorySlot.md
        ├── InventoryModel.md
        ├── InventoryController.md
        ├── EquipmentController.md
        ├── GrantItemEffect.md
        ├── LootTableDefinition.md
        ├── LootEntry.md
        ├── LootService.md
        ├── LootRollResult.md
        ├── RewardDefinition.md
        ├── RewardOption.md
        ├── RewardSystem.md
        ├── ExperienceComponent.md
        ├── ExperienceCurve.md
        ├── ProgressionState.md
        ├── ProgressionService.md
        ├── UpgradeDefinition.md
        ├── AddCurrencyEffect.md
        ├── SpendCurrencyEffect.md
        ├── QuestDefinition.md
        ├── QuestObjectiveDefinition.md
        ├── QuestState.md
        ├── QuestLog.md
        ├── QuestService.md
        ├── AcceptQuestEffect.md
        ├── AdvanceObjectiveEffect.md
        ├── CompleteQuestEffect.md
        ├── RoomDefinition.md
        ├── RoomGraph.md
        ├── RoomLoader.md
        ├── RoomNode.md
        ├── RoomRuntime.md
        ├── RoomController.md
        ├── DungeonGenerator.md
        ├── RunState.md
        ├── RunDirector.md
        ├── RewardCoordinator.md
        ├── ShopDefinition.md
        ├── ShopEntry.md
        ├── ShopService.md
        ├── StatDefinition.md
        ├── StatModifier.md
        ├── StatModifierDefinition.md
        ├── StatsComponent.md
        ├── ApplyStatModifierEffect.md
        ├── StatusEffectDefinition.md
        ├── StatusEffectInstance.md
        ├── StatusEffectController.md
        ├── ApplyStatusEffect.md
        ├── UIManager.md
        ├── DialogueUI.md
        ├── QuestLogUI.md
        ├── ShopUI.md
        ├── RewardSelectionUI.md
        ├── FeedbackSystem.md
        ├── DamageNumberSystem.md
        ├── VFXSpawner.md
        ├── ZoneDefinition.md
        ├── WorldService.md
        ├── Portal.md
        └── SpawnPoint.md
```

**导航分组（`index.html` navGroups）：**

| 组名 | 文档 |
|------|------|
| 入门 | readme → getting_started → architecture → concepts → glossary |
| 指南 | pipeline → debugging |
| Cookbook | cookbook/index → 01–14（主线 01–11，扩展 12–14）|
| Kernel Ref | ref/kernel/ 下所有文件 |
| Module Ref | ref/modules/ 下所有文件 |

---

## 二、各文档内容规范

### 2.1 `readme.md` — 项目概览

**定位：** 文档站首页，一眼看懂"mkit 是什么、能做什么、怎么用"。  
**不包含：** 详细 API、代码实现、平台适配细节。

**必须涵盖：**
1. 一句话介绍（mkit 是什么、适用场景）
2. 层架构图（Mermaid flowchart，三层 + 依赖箭头方向）
3. 标准管线一览（见下），每段一行说明职责：
   ```
   Input / AI / Script
     → GameCommand                                        ← 意图封装为类型化对象（kernel）
     → CommandService.dispatch → CommandReceiver          ← kernel 路由到目标实体的接收器
     → StateMachine / State.handle_command                ← kernel HFSM 决定是否响应、触发状态转换
     → AbilityController.cast → 条件/cost 检查            ← module 技能桥接；cast_time>0 时走 ActionService
     → ActionService.start_action → GameAction            ← kernel 管理带时序的行为生命周期
     → GameAction._on_start / _on_complete / _on_cancel   ← 生命周期钩子（module subclass override）
       start/complete 后 kernel 自动 _fire_effects(on_xxx_effects + _resolve_effects(ctx))
       cancel 后 kernel 自动 _fire_effects(on_cancel_effects)  # cancel 不调 _resolve_effects
     → EffectService.execute_many → GameEffect._apply_impl ← kernel 调度；_apply_impl 由 module 实现
        │ 例（DealDamageEffect，位于 modules/combat/damage/）：
        │   target.get_node_or_null("Components/HealthComponent") → health.apply_damage()
        │   ServiceRegistry.get_service("combat") → CombatService.resolve()
     → EventService.emit_*                                ← kernel 广播领域事件
     → UI / Audio / VFX / Analytics                      ← modules 订阅信号，产生表现
   ```
   **kernel 是管线的骨架（Command / HFSM / Action / Effect / Event 均在 kernel）。`GameEffect` 是 kernel 的抽象基类；具体效果实现（`DealDamageEffect` 等）位于 modules，通过覆写 `_apply_impl` 访问 module 组件。`GameAction` 在每个生命周期钩子执行完毕后，由 kernel 自动触发 `on_start/complete/cancel_effects` 数组（data-driven）；subclass 可 override `_resolve_effects` 在运行时动态补充 effect。`AbilityController`（module）是 StateMachine 与 ActionService/EffectService 之间的桥接层。**
4. 文件结构速览（`addons/mkit/kernel/`、`addons/mkit/modules/`、`res://game/` 各含什么）
5. 快速导航表（"我想做 X → 看 Y"）

---

### 2.2 `getting_started.md` — 快速上手

**定位：** 新用户的唯一入口，目标是在 5 分钟内让项目跑起来。  
**不包含：** 概念深讲、完整 API、架构原因。

**必须涵盖：**
1. 前置条件（Godot 4.7+，复制 `addons/mkit/` 到项目，启用插件，添加 `ServiceRegistry` autoload）
2. 创建 Bootstrap 场景（新建 Node 场景 → 挂 `GameBootstrap` → 配置 `resource_databases`、`initial_scene_path`）
3. 运行验证（`make ut` 或直接运行场景；预期输出是什么）
4. 下一步学习路径（→ architecture.md → concepts.md → cookbook/01）

---

### 2.3 `architecture.md` — 层架构

**定位：** 解释三层模型、依赖规则、ServiceRegistry 模式、实体节点约定。读完能回答"我的代码放哪层、为什么"。

**必须涵盖：**

#### 层模型（Mermaid flowchart）
```
Game Content (res://game/)
  ↓
Module Layer (addons/mkit/modules/)
  ↓
Kernel Layer (addons/mkit/kernel/)
  ↓
Platform Adapter Layer (services/mocks)
```
- 每层职责一句话
- 依赖只能向下，不能反向
- `game/` 可以依赖 modules + kernel；modules 只能依赖 kernel；kernel 不依赖任何上层

#### ServiceRegistry 模式
- 唯一的 autoload 是 `ServiceRegistry`
- 所有服务通过 `ServiceRegistry.get_service("id") as T` 获取
- `GameBootstrap` 在启动时注册所有内置服务
- 完整服务 ID 对照表（见下方）

**服务 ID 对照表（源自 `game_bootstrap.gd`）：**

| 服务 ID | 类型 | 说明 |
|---------|------|------|
| `"events"` | `EventService` | 领域事件路由 |
| `"content"` | `ContentService` | 内容注册与查询 |
| `"random"` | `RandomService` | 有种子随机数 |
| `"time"` | `TimeService` | delta / 帧管理 |
| `"actions"` | `ActionService` | Action 生命周期 |
| `"effects"` | `EffectService` | Effect 执行链 |
| `"commands"` | `CommandService` | 命令分发 |
| `"combat"` | `CombatService` | 伤害结算 |
| `"scenes"` | `SceneService` | 场景切换 |
| `"pool"` | `PoolService` | 对象池 |
| `"save"` | `SaveService` | 存读档 |
| `"progression"` | `ProgressionService` | 经验 / 升级 |
| `"quest"` | `QuestService` | 任务系统 |
| `"shop"` | `ShopService` | 商店系统 |
| `"audio"` | `AudioService` | 音频播放 |
| `"dialogue"` | `DialogueService` | 对话系统 |
| `"world"` | `WorldService` | 世界 / 区域 |
| `"analytics"` | `AnalyticsService` | 数据统计（默认 Mock）|
| `"ads"` | `AdService` | 广告（默认 Mock）|
| `"iap"` | `IAPService` | 内购（默认 Mock）|
| `"cloud_save"` | `CloudSaveService` | 云存档（默认 Mock）|

#### Definition / Instance / Controller / System 四分模式
每个游戏系统的对象都遵循同一形状：

| 角色 | 基类 | 生命周期 | 例子 |
|------|------|----------|------|
| **Definition** | `Resource` / `ContentDefinition` | 静态，编辑器配置，`.tres` | `AbilityDefinition` |
| **Instance** | `RefCounted` | 运行时，每个实体一份 | `AbilityInstance` |
| **Controller / Component** | `Node` / `SaveableComponent` | 挂在实体节点树上 | `AbilityController` |
| **System / Service** | `Node` / `RefCounted` | 全局单例，通过 ServiceRegistry 取 | `CombatService` |

#### 实体节点约定（固定布局）
```
EntityRoot
  EntityIdentity          ← 唯一 ID
  Components/             ← 数据组件（HealthComponent、StatsComponent…）
  Controllers/            ← 系统控制器（AbilityController、EquipmentController…）
  Presentation/           ← 渲染与动画
    AnimationPlayer       ← Action 播动画的接缝节点
```
- 模块通过 `owner.get_node_or_null("Components/XxxComponent")` 定位兄弟节点
- 改动节点路径会破坏所有依赖此路径的系统

---

### 2.4 `concepts.md` — 核心心智模型

**定位：** 解释"整体怎么转、为什么这么设计"的五个核心模型。读完能自信地回答"加一个技能，我负责什么、mkit 负责什么"。

**必须涵盖（顺序即阅读顺序）：**

#### 模型 1：标准管线（时序图）
> 一个输入/命令从发出到产生游戏效果的完整路径。

```
Input / AI / Script
  → GameCommand                                        # 意图封装为类型化对象（kernel）
  → CommandService.dispatch → CommandReceiver          # kernel 路由；CommandReceiver 由实体实现
  → StateMachine / State.handle_command                # kernel HFSM，决定是否响应、触发状态转换
  → AbilityController.cast → 条件/cost 检查            # module 技能桥接层（cast_time>0 时走 ActionService）
  → ActionService.start_action → GameAction            # kernel 管理行为时序（start/update/complete/cancel）
  → GameAction._on_start / _on_complete / _on_cancel   # 生命周期钩子；钩子结束后 kernel 自动
    start/complete: _fire_effects(on_xxx_effects + _resolve_effects(ctx))  # _resolve_effects 可 override
    cancel:         _fire_effects(on_cancel_effects)                        # cancel 不调 _resolve_effects
  → EffectService.execute_many → GameEffect            # kernel 调度效果链；GameEffect 是 kernel 抽象基类
       _apply_impl 由 module 实现（如 DealDamageEffect，位于 modules/combat/damage/）：
         target.get_node_or_null("Components/HealthComponent") → health.apply_damage()
         ServiceRegistry.get_service("combat") → CombatService.resolve()
  → EventService.emit_*                               # kernel 广播领域事件（damage_applied、entity_died…）
  → UI / Audio / VFX / Analytics                      # modules 订阅信号，产生表现
```

**核心关系：kernel 包含管线骨架（Command / HFSM / Action / Effect / Event）。`GameAction` 在每个生命周期钩子执行完毕后，由 kernel 自动触发 `on_start/complete/cancel_effects` 数组（data-driven）；subclass 可 override `_resolve_effects` 在运行时动态补充 effect，无需手动调用 EffectService。`GameEffect` 是 kernel 的抽象基类；具体效果实现（`DealDamageEffect`、`HealEffect` 等）位于 modules，通过覆写 `_apply_impl` 直接访问 module 组件。`AbilityController`（module）是 State 与 ActionService/EffectService 之间的桥接层，没有"Domain System"这层抽象。`EventService` 是 module 工作完成后向外广播的出口。**

每一跳解释：产出什么对象、交给谁、**为什么要这一跳**（命令与效果解耦的原因；Action 层的价值；Effect 是 Resource 的意义）。

配图：`sequenceDiagram`，参与者包括 `[你的代码]` / `CommandService` / `StateMachine` / `ActionService` / `EffectService` / `CombatService` / `EventService`，用 Note 标注哪些节点是 `[你实现]`，哪些是 `[mkit 内置]`。

#### 模型 2：GameplayContext 是共享信使
- `GameplayContext` 是整条管线中传递状态的对象（source、target、ability_id、amount、direction、tags、payload）
- 从 `GameCommand` 创建（`GameplayContext.from_command(cmd, source_node, target_node)`）
- 沿 Effect 链传递，每个 Effect 读写同一个 context
- **不要在 context 里放 Node 引用以外的重型对象**

#### 模型 3：内容注册与查询（ContentService + ResourceDatabase）
- 所有配置数据（技能、物品、任务、房间…）继承 `ContentDefinition`，打包为 `.tres`
- 统一放入 `ResourceDatabase` 资源，挂到 `GameBootstrap.resource_databases`
- 查询：`ContentService.get_resource("ability_id") as AbilityDefinition`
- 注意：`ContentDefinition.get_content_id()` 必须返回唯一字符串；`ContentService.validate_all()` 会在启动时检查

#### 模型 4：两条存档契约
| 契约 | 基类 | 键的来源 | 适合场景 |
|------|------|----------|----------|
| `Saveable` | `Node` | `save_id`（全局唯一）| 全局状态，如玩家存档根节点 |
| `SaveableComponent` | `Node` | 节点 `name`（实体内唯一）| 实体内组件，如 `AbilityController`、`InventoryController` |

- `SaveService` 在 `save_game()` 时遍历树，找到所有 `Saveable` 和 `SaveableComponent` 节点，调 `to_save_data()`
- 实现存档只需 override `to_save_data() -> Dictionary` 和 `from_save_data(data: Dictionary)`

#### 模型 5：扩展点地图（你写什么 / mkit 管什么）

| 扩展点 | 你继承的类 | 你实现的方法 | mkit 负责什么 |
|--------|-----------|------------|--------------|
| 自定义效果 | `GameEffect` | `_apply_impl(ctx)` | 条件检查、结果包装、执行链调度 |
| 自定义动作 | `GameAction` | `_on_start/update/cancel/complete`；声明 `on_start/complete/cancel_effects` 数组；可 override `_resolve_effects(_ctx)` 动态补充 effect | 生命周期管理、钩子后自动 `_fire_effects`、complete/cancelled 信号 |
| 自定义状态 | `State` | `enter/exit/update/handle_command/can_enter/can_exit` | 层级结构、transition 路由、blackboard 注入 |
| 自定义 AI | `Brain` | `think(entity, delta)` | 被 AI 系统按帧调用 |
| 自定义交互 | `Interactable` | `_interact_impl(interactor)` | 交互检测、触发时机 |
| 自定义内容 | `ContentDefinition` | `get_content_id()` + `@export` 字段 | 注册、校验、按 ID 查询 |
| 自定义存档 | `Saveable` / `SaveableComponent` | `to_save_data()` / `from_save_data()` | 序列化协调、版本迁移调度 |
| 自定义服务 | 任意类 | 你的服务逻辑 | `ServiceRegistry` 持有引用，其他系统按 ID 取 |
| Bootstrap 扩展 | `GameBootstrap` | `_register_kernel_services` override（添加自定义服务）/ `_load_profile` override | 其余启动步骤 |

配图：Mermaid flowchart，蓝色节点 = mkit 内部，绿色节点 = 用户扩展点。

---

### 2.5 `glossary.md` — 术语表

每条格式：`**术语**：一句话定义。` 加跳转链接到主文档。

**必须包含：**
Command、Action、Effect、Condition、EffectResult、GameplayContext、Definition、Instance、Controller、Component、System、Service、ServiceRegistry、Saveable、SaveableComponent、ContentDefinition、ResourceDatabase、DomainEvent、EventService、Blackboard、Brain、HFSM / StateMachine、State、Hitbox / Hurtbox、AbilityDefinition / AbilityInstance / AbilityController、DamageRequest / DamageResult、RunState / RunDirector、EntityRoot / EntityIdentity、Presentation/AnimationPlayer、Platform Adapter。

---

### 2.6 `debugging.md` — 调试工具与常见错误

**定位：** 当系统不按预期运行时的第一查阅点。每个工具说明"怎么用 + 看到什么 + 能定位什么问题"。

**必须涵盖：**

#### 内置调试工具
- **`DebugOverlay`**：实时显示实体当前状态路径、HP、最近命令、最近事件
- **`EventService.recent_events`**：回放最近 100 个领域事件，确认事件是否发出、顺序是否正确
- **`EffectService`（trace）**：查效果链每步成功/失败及原因，定位"技能放了不生效"
- **`CombatService`（trace）**：查伤害各阶段中间值（base → 攻击力 → 暴击 → 防御 → final）
- **`StateMachine.last_transition_reason` / `last_failed_transition_reason`**：查"为什么没切状态"
- **`RandomService` 固定种子**：复现概率性 bug

#### 常见问题速查表

| 现象 | 先检查 | 常见原因 |
|------|--------|----------|
| 技能按了没反应 | `AbilityController.get_cast_failure_reason()` | 冷却中、cost 不足、conditions 不满足、ability_id 未注册 |
| Effect 执行了但没效果 | `EffectService` trace | conditions 未通过、`_apply_impl` 未 override、context.target 为 null |
| 状态没切换 | `StateMachine.last_failed_transition_reason` | `can_enter()` 返回 false、路径写错 |
| 动画不播 | `Presentation/AnimationPlayer` 是否存在、`has_animation(name)` | 节点路径不对；Action 中 `has_animation` 检查失败后静默跳过 |
| 存档读取后数据丢失 | `to_save_data()` 返回值 | 忘记 override；`get_save_key()` 返回空串；节点 name 与存档 key 不匹配 |
| 服务取到 null | `ServiceRegistry.has_service("id")` | Bootstrap 未运行；服务 ID 拼错；测试环境未注册 |
| 实体组件找不到兄弟 | `owner.get_node_or_null("Components/XxxComponent")` | 节点路径不符合实体约定布局 |

---

### 2.7 `pipeline.md` — 管线参考

**定位：** 每条管线描述一个完整流程的调用序列——从触发点到最终输出。

**每条管线的结构：**
```markdown
## <管线名>

**触发点：** <谁发起>  
**涉及系统：** <逗号分隔的类名列表>  
**输出：** <最终产出>

### 流程（Mermaid sequenceDiagram）
（含 [mkit] / [你] 归属 Note）

### 关键代码
（Level 2 示例：入口怎么造、服务怎么取、信号怎么接）

### 相关文档
（→ concepts#模型N、→ cookbook/0N、→ ref/XxxClass）
```

**需要覆盖的管线（按优先级）：**

#### P0 — 核心必读
1. **Runtime Bootstrap**：`GameBootstrap._ready` → `_register_kernel_services` → `_load_content` → `_validate_content` → `_load_profile` → `_enter_initial_scene`
2. **Main Gameplay Loop**：每帧 `StateMachine._process` → `State.update` → `GameAction.update` → `AbilityController._process`（cooldown tick）

#### P1 — 最高频
3. **Command Dispatch**：发出 `GameCommand` → `CommandService.dispatch` → `CommandReceiver.receive` → `State.handle_command`
4. **HFSM Transition**：`State.request_transition` → `StateMachine.transition_to` → `can_exit` / `can_enter` → `exit` / `enter`
5. **Ability Cast**：`AbilityController.cast` → 条件检查 → cost 扣除 → cast_time > 0 时 `ActionService.start_action(CastAction)`，cast_time == 0 时创建临时 `GameAction` 并立即 `start()`+`complete()`；两条路径均通过 `GameAction.on_complete_effects` data-driven 触发 effect，kernel 自动 `_fire_effects`，不直接调用 `EffectService`
6. **Effect Execution**：`EffectService.execute` → `GameEffect.apply` → `ConditionEvaluator.evaluate_all` → `_apply_impl` → `EffectResult`
7. **Damage Resolution**：`CombatService` 接收 `DamageRequest` → stat 计算 → `HealthComponent.apply_damage` → `EventService.emit_damage_applied`

#### P2 — 解耦关键
8. **Event Notification**：`EventService.emit_*` → `domain_event_emitted` 信号 → UI / FeedbackSystem / AudioService 订阅
9. **Entity Spawn**：`EntitySpawner.spawn` → 实例化 `PackedScene` → 注入 `EntityIdentity` → 挂入场景树
10. **Animation — Action 驱动通道**：`GameAction._on_start` → `Presentation/AnimationPlayer.play(name)` → active 窗口内逻辑生效（Hitbox 开关等）
11. **Animation — 事件反馈通道**：`EventService.damage_applied` → `FeedbackSystem` → `VFXSpawner.spawn` / `AudioService.play`

#### P3 — RPG 流程
12. **Quest Lifecycle**：`QuestService.accept` → `QuestState` 创建 → `AdvanceObjectiveEffect` 推进 → `QuestService.complete` → `EventService.emit_quest_completed`
13. **Save / Load**：`SaveService.save_game` → 遍历树收集 Saveable + SaveableComponent → 序列化 → 写文件；`load_game` 反向
14. **Loot Roll**：`LootService.roll_table(table_id, ctx)` → 权重计算 → `LootRollResult` → `LootService.apply_selected` / `RewardSystem`
15. **Dialogue**：`DialogueService.start` → `DialogueRuntime` 状态机 → 推进节点 → 发 `EventService.emit_dialogue_ended`
16. **Shop Purchase**：`ShopService.purchase` → 检查 currency / stock → `InventoryController.add_item` → `EventService.emit_item_purchased`

#### P4 — 按需补充
17. **Progression / Level Up**：`ExperienceComponent.add_xp` → 检查 `ExperienceCurve` 阈值 → `ProgressionService` 处理升级
18. **Room / Run**：`RunDirector` 初始化 `RunState` → `DungeonGenerator` 生成 `RoomGraph` → `RoomController` 加载房间 → `room_cleared` → `RewardCoordinator`
19. **Status Effect Tick**：`StatusEffectController._process` → 每个 `StatusEffectInstance.tick(delta)` → effect 到期或被清除
20. **Scene Transition**：`SceneService.change_scene` → 卸载当前 → 加载新场景 → `zone_changed` 事件

---

### 2.8 Cookbook — 累进式 RPG Loop 构建

**定位：** Cookbook 是一条**单一项目的累进构建主线**。每篇 recipe 在上一篇已有场景的基础上新增一层，做完 Recipe 01–11 就得到一个完整可玩的 RPG loop（玩家 + 敌人战斗 + 房间序列 + 奖励 + NPC 对话 + 任务 + 存档）。Recipe 12–14 是独立的功能扩展，可按需选做。

**设计原则：**
- 每篇都在同一个 Godot 项目里操作，不重建场景
- 每篇开头明确写出"本篇结束后，场景里多了什么"
- 不引用 `game/demo/` 内部文件；所有示例基于 mkit API 自成体系

---

#### Cookbook 主线：累进构建路径

```
Recipe 01  → 游戏启动，services 在线
Recipe 02  → 玩家实体出现在场景，可以移动
Recipe 03  → 玩家有血量/属性，可以被伤害和死亡
Recipe 04  → 玩家有攻击动作，能命中区域造成伤害
Recipe 05  → 玩家有可配置技能（AbilityDefinition），可 cast
Recipe 06  → 敌人实体上场，有 AI，会主动攻击玩家
Recipe 07  → 战斗发生在房间里（RoomController），房间清空后推进
Recipe 08  → 房间清空触发奖励选择（Loot + RewardSelectionUI）
Recipe 09  → NPC 可以对话，对话结束后接受任务（Quest）
Recipe 10  → 击杀敌人推进任务目标，完成任务领奖励
Recipe 11  → 击杀/完成任务获得 XP，升级，全局存读档
           ↑ 完整 RPG loop
Recipe 12  → 为技能添加状态效果（DOT / buff）       [扩展]
Recipe 13  → 为实体接入动画（Action 驱动 + 事件 VFX）[扩展]
Recipe 14  → 在房间之间开放商店购买物品             [扩展]
```

---

#### 每篇固定结构

```markdown
# Recipe N：标题  ·  难度 ★☆☆  ·  预计 X 分钟

## 本篇结束后，你的项目新增了什么
（一句话 + 可观察的效果，如"运行场景后控制台打印所有已注册服务 ID"）

## 前置
- 需完成：Recipe 0N-1（主线）或独立（扩展 recipe）
- 用到的概念：[concepts.md 对应章节链接]

## 你负责 / mkit 负责
| 你写的 | mkit 处理的 |
|--------|------------|
（按实际内容逐行填写）

## 步骤
（每步：说明目的 → 给出完整可粘贴代码 → 标注放在哪个文件的哪个方法）

## 运行验证
告知运行后应看到什么输出/行为，用于确认步骤正确。

## 常见错误
| 现象 | 原因 | 修复 |

## 延伸阅读
相关 pipeline / ref / concepts 链接。
```

---

#### 各 Recipe 详细规格

| # | 文件 | 本篇新增内容 | 涉及类 |
|---|------|------------|--------|
| 01 | `01_bootstrap.md` | `GameBootstrap` 场景、`ResourceDatabase`、服务启动验证 | `GameBootstrap`、`ServiceRegistry`、`ResourceDatabase`、`ContentService` |
| 02 | `02_player_entity.md` | 玩家实体场景树（EntityRoot 布局）、`StateMachine` + idle/move 状态、输入 → `GameCommand` → `CommandReceiver` → 状态切换 | `EntityRoot`、`EntityIdentity`、`EntityDefinition`、`StateMachine`、`State`、`CommandService`、`CommandReceiver`、`GameCommand`、`Blackboard` |
| 03 | `03_health_and_stats.md` | `StatsComponent`（ATK/DEF）、`HealthComponent`、`DealDamageEffect` 直接触发伤害、监听 `entity_died` | `StatsComponent`、`StatDefinition`、`HealthComponent`、`DealDamageEffect`、`GameplayContext`、`EventService`、`DamageRequest`、`DamageResult`、`CombatService` |
| 04 | `04_attack_action.md` | 攻击状态、`TimedAttackAction`（startup/active/recovery 时序）、`HitboxComponent` / `HurtboxComponent` 在 active 窗口开关 | `TimedAttackAction`、`ActionService`、`ActionContext`、`HitboxComponent`、`HurtboxComponent`、`GameAction` |
| 05 | `05_ability.md` | `AbilityDefinition`（`.tres`）注册到 `ResourceDatabase`、`AbilityController` 注册并 cast、ResourcePool 消耗、冷却 | `AbilityDefinition`、`AbilityInstance`、`AbilityController`、`ContentService`、`ResourcePoolComponent`、`CooldownReadyCondition` |
| 06 | `06_ai_enemy.md` | 敌人实体（同样的场景树约定）、继承 `Brain` 实现决策逻辑、敌人发 `GameCommand` 攻击玩家 | `Brain`、`EntitySpawner`、`StateMachine`、`GameCommand`、`CommandService` |
| 07 | `07_room.md` | `RoomDefinition`（`.tres`）、`RoomController`、`RoomLoader`、在房间里 spawn 敌人、监听 `room_cleared`；`RunDirector` 串联多个房间 | `RoomDefinition`、`RoomRuntime`、`RoomController`、`RoomLoader`、`RoomGraph`、`DungeonGenerator`、`RunDirector`、`RunState` |
| 08 | `08_loot_and_rewards.md` | 房间清空后 `LootService` 掷骰子、`RewardDefinition` 定义奖励池、`RewardSelectionUI` 让玩家选 | `LootTableDefinition`、`LootEntry`、`LootService`、`LootRollResult`、`RewardDefinition`、`RewardOption`、`RewardSystem`、`RewardCoordinator`、`RewardSelectionUI`、`GrantItemEffect` |
| 09 | `09_npc_dialogue.md` | NPC 实体 + `Interactable` / `InteractionComponent`、`DialogueDefinition`（`.tres`）树形对话、`DialogueService` 推进、监听 `dialogue_ended` | `Interactable`、`InteractionComponent`、`DialogueDefinition`、`DialogueNode`、`DialogueChoice`、`DialogueRuntime`、`DialogueService`、`DialogueInteractable` |
| 10 | `10_quest.md` | `QuestDefinition`（`.tres`）、NPC 对话末尾触发 `AcceptQuestEffect`、击杀敌人时 `AdvanceObjectiveEffect` 推进、达成后 `CompleteQuestEffect` + 奖励 | `QuestDefinition`、`QuestObjectiveDefinition`、`QuestState`、`QuestLog`、`QuestService`、`AcceptQuestEffect`、`AdvanceObjectiveEffect`、`CompleteQuestEffect`、`EventService` |
| 11 | `11_progression_and_save.md` | `ExperienceComponent` 击杀获 XP、`ExperienceCurve` 定义升级阈值、`ProgressionService` 处理升级；`Saveable` / `SaveableComponent` 实现存读档 | `ExperienceComponent`、`ExperienceCurve`、`ProgressionState`、`ProgressionService`、`UpgradeDefinition`、`Saveable`、`SaveableComponent`、`SaveService`、`SaveMigration` |
| 12 | `12_status_effects.md` | `StatusEffectDefinition`（`.tres`）DOT/buff、`ApplyStatusEffect` 挂到技能 effect 链、`StatusEffectController` 每帧 tick | `StatusEffectDefinition`、`StatusEffectInstance`、`StatusEffectController`、`ApplyStatusEffect` |
| 13 | `13_animation.md` | `Presentation/AnimationPlayer` 接缝；通道 A：`GameAction._on_start` 播攻击动画；通道 B：`EventService.damage_applied` → `FeedbackSystem` → `VFXSpawner` | `GameAction`、`FeedbackSystem`、`VFXSpawner`、`AudioService`、`DamageNumberSystem` |
| 14 | `14_shop.md` | `ShopDefinition`（`.tres`）、`ShopService.purchase`、`ShopUI`、`item_purchased` 事件、`InventoryController` | `ShopDefinition`、`ShopEntry`、`ShopService`、`ShopUI`、`InventoryController`、`ItemDefinition`、`ItemInstance` |

---

### 2.9 Class Ref 规范

**定位：** 字典式参考，不是读物。快速查清"这个类有哪些字段/方法、什么时候用"。

**每个 ref 文件的固定结构：**

```markdown
# ClassName

**层：** Kernel / Module  
**文件：** `addons/mkit/kernel(或modules)/path/class_name.gd`  
**继承：** `extends XxxBase`

## 职责
一句话说明这个类做什么（不超过两行）。

## 字段（@export 和 public var）
| 字段名 | 类型 | 默认值 | 说明（由谁写、由谁读、生命周期） |

## 方法
| 方法签名 | 返回值 | 说明 |

## 信号（如有）
| 信号名 | 参数 | 触发时机 |

## 使用模式
### 最小示例（Level 1，≤10 行）
（单方法最小调用，强类型，必要前置变量就地声明）

### 典型场景（Level 2，10–40 行，核心类必须有）
（含 context/前置、成功 + 失败两条路径、可放进项目直接运行）

## 相关
（→ 配套类、→ pipeline#段落、→ cookbook/0N）
```

**Level 2 必须有的类（P0 优先）：**

| 优先级 | 类 |
|--------|----|
| P0 | `GameBootstrap`、`ServiceRegistry`、`GameCommand`、`CommandService`、`GameAction`、`ActionService`、`GameEffect`、`EffectService`、`GameplayContext`、`EventService`、`ContentService`、`ResourceDatabase`、`State`、`StateMachine` |
| P1 | `AbilityController`、`AbilityDefinition`、`CombatService`、`DamageRequest`、`HealthComponent`、`StatsComponent`、`Saveable`、`SaveableComponent`、`SaveService` |
| P2 | `EntityRoot`、`EntitySpawner`、`QuestService`、`QuestDefinition`、`StatusEffectController`、`LootService`、`InventoryController`、`ProgressionService`、`FeedbackSystem`、`VFXSpawner` |
| P3 | 其余所有类 |

---

## 三、图表标准

**渲染支持：** `docs/index.html` 已集成 Mermaid，` ```mermaid ` 块直接渲染。

**配色规范（所有 flowchart 强制执行）：**
```
classDef mkitCore  fill:#4A90D9,color:#fff,stroke:#2C6FAC
classDef userOwned fill:#7ED321,color:#fff,stroke:#5A9A18
```
图例（放每图下方）：`🔵 蓝色 = mkit 负责 / 🟢 绿色 = 你实现`

**sequenceDiagram 归属 Note 规范：**
```
Note over CommandService,EffectService: [mkit 内部]
Note over YourState,YourEffect: [你实现]
```

**必须产出的图：**

| 图 | 位置 | 类型 |
|----|------|------|
| 层架构依赖图 | `architecture.md` | flowchart TB |
| 标准管线时序图 | `concepts.md` | sequenceDiagram |
| Definition/Instance/Controller 数据流 | `concepts.md` | flowchart LR |
| Bootstrap 启动时序 | `concepts.md` / `pipeline.md` | sequenceDiagram |
| 伤害结算时序 | `pipeline.md` | sequenceDiagram |
| 动画两通道对照图 | `pipeline.md` / `cookbook/10` | flowchart |
| 扩展点地图 | `concepts.md` | flowchart |

---

## 四、代码示例质量门槛

所有新增示例必须满足：

1. **基于真实 API**：字段名、方法签名、服务 ID 与源码一致，不捏造方法
2. **强类型**：一律 `as TypeName`，不写裸 `var x = ...`
3. **取服务统一**：`ServiceRegistry.get_service("id") as ClassName`，不直接持 autoload 引用（`ServiceRegistry` 除外）
4. **有失败分支**：返回 bool 的方法（`can_cast`、`cast`、`register_ability`…）必须演示失败路径
5. **注释只写 WHY**：不解释语法，不复述方法名，只写非显然的约束或原因
6. **不暴露 demo 路径**：示例不引用 `game/demo/`，不依赖 demo 专有脚本；Level 2 示例自成体系

---

## 五、全类覆盖清单（生成检查用）

以下 139 个类每个必须在某个 ref 文件中有完整条目。

### Kernel（46 类）

**Actions（3）**：`GameAction`、`ActionService`、`ActionContext`  
**Bootstrap（1）**：`GameBootstrap`  
**Commands（4）**：`GameCommand`、`CommandService`、`CommandReceiver`、`BuiltinCommands`  
**Conditions（3）**：`Condition`、`ConditionEvaluator`、`TargetInRangeCondition`  
**Context（3）**：`GameplayContext`、`ActionContext`、`Blackboard`  
**Debug（1）**：`DebugOverlay`  
**Effects（5）**：`GameEffect`、`EffectService`、`EffectResult`、`SpawnSceneEffect`、`LogEffect`  
**Events（2）**：`DomainEvent`、`EventService`  
**Registry（4）**：`ContentDefinition`、`ContentService`、`ContentValidationResult`、`ResourceDatabase`  
**Save（4）**：`Saveable`、`SaveableComponent`、`SaveService`、`SaveMigration`  
**Services（14）**：`ServiceRegistry`、`TimeService`、`RandomService`、`SceneService`、`PoolService`、`AudioService`、`AnalyticsService`、`AnalyticsServiceMock`、`AdService`、`AdServiceMock`、`IAPService`、`IAPServiceMock`、`CloudSaveService`、`CloudSaveServiceMock`  
**StateMachine（2）**：`State`、`StateMachine`

> `ActionContext` 同时属于 context 目录，ref 文件放 `ref/kernel/ActionContext.md`，目录以文件位置为准。  
> 模块特定的 Effects（`DealDamageEffect` 等）、Actions（`CastAction` 等）、Conditions（`CooldownReadyCondition`）均在 modules，ref 文件放 `ref/modules/`。

### Modules（93 类）

**Abilities（5）**：`AbilityDefinition`、`AbilityInstance`、`AbilityController`、`CastAction`、`CooldownReadyCondition`  
**AI（2）**：`Brain`、`SimpleAIEnemyBrain`  
**Combat（8）**：`CombatService`、`DamageRequest`、`DamageResult`、`HitboxComponent`、`HurtboxComponent`、`DealDamageEffect`、`DashAction`、`TimedAttackAction`  
**Dialogue（6）**：`DialogueDefinition`、`DialogueNode`、`DialogueChoice`、`DialogueRuntime`、`DialogueInteractable`、`DialogueService`  
**Entity（4）**：`EntityDefinition`、`EntityIdentity`、`EntityRoot`、`EntitySpawner`  
**Health（3）**：`HealthComponent`、`ResourcePoolComponent`、`HealEffect`  
**Interaction（2）**：`Interactable`、`InteractionComponent`  
**Inventory（7）**：`ItemDefinition`、`ItemInstance`、`InventorySlot`、`InventoryModel`、`InventoryController`、`EquipmentController`、`GrantItemEffect`  
**Loot（7）**：`LootTableDefinition`、`LootEntry`、`LootService`、`LootRollResult`、`RewardDefinition`、`RewardOption`、`RewardSystem`  
**Progression（7）**：`ExperienceComponent`、`ExperienceCurve`、`ProgressionState`、`ProgressionService`、`UpgradeDefinition`、`AddCurrencyEffect`、`SpendCurrencyEffect`  
**Quest（8）**：`QuestDefinition`、`QuestObjectiveDefinition`、`QuestState`、`QuestLog`、`QuestService`、`AcceptQuestEffect`、`AdvanceObjectiveEffect`、`CompleteQuestEffect`  
**Room（10）**：`RoomDefinition`、`RoomGraph`、`RoomLoader`、`RoomNode`、`RoomRuntime`、`RoomController`、`DungeonGenerator`、`RunState`、`RunDirector`、`RewardCoordinator`  
**Shop（3）**：`ShopDefinition`、`ShopEntry`、`ShopService`  
**Stats（5）**：`StatDefinition`、`StatModifier`、`StatModifierDefinition`、`StatsComponent`、`ApplyStatModifierEffect`  
**Status Effects（4）**：`StatusEffectDefinition`、`StatusEffectInstance`、`StatusEffectController`、`ApplyStatusEffect`  
**UI（8）**：`UIManager`、`DialogueUI`、`QuestLogUI`、`ShopUI`、`RewardSelectionUI`、`FeedbackSystem`、`DamageNumberSystem`、`VFXSpawner`  
**World（4）**：`ZoneDefinition`、`WorldService`、`Portal`、`SpawnPoint`

---

## 六、实施优先级

### Phase 1 — 基础骨架（先让文档站能跑、能找到东西）
- [x] `docs/index.html`（带 navGroups，参考第一节分组）
- [x] `docs/readme.md`
- [x] `docs/getting_started.md`
- [x] `docs/architecture.md`（含服务 ID 表、实体节点约定、层依赖图）
- [x] `docs/glossary.md`

### Phase 2 — 核心理解层
- [x] `docs/concepts.md`（5 个心智模型 + 所有图）
- [x] `docs/pipeline.md`（P0 + P1 共 7 条管线，含代码示例）
- [x] `docs/debugging.md`

### Phase 3 — 动手层
- [ ] `docs/cookbook/` 骨架 + 主线 recipes 01–06（bootstrap → AI enemy）
- [ ] P0 优先的 14 个 ref 文件（含 Level 2 示例）

### Phase 4 — 完整覆盖
- [ ] 主线 Recipes 07–11（rooms → save，完成完整 RPG loop）；扩展 12–14
- [ ] P1/P2 ref 文件
- [ ] Pipeline P2–P4（剩余 13 条）
- [ ] P3 ref 文件（剩余所有类）

### Phase 5 — 防腐
- [ ] `tools/check_docs_sync.py` + `make docs-check`（断链、漏 ref、navGroups 同步）
- [ ] 每个 recipe 包含"你负责 / mkit 负责"节的自动检查

---

## 七、范围外

- **`game/demo/` 相关内容**：demo 是内部测试资产，不出现在任何用户文档中；文档示例自成体系，不引用 demo 路径或脚本。
- **新增 class / 功能**：本规划只产出文档，不修改 addon 代码。
- **CLAUDE.md / AGENTS.md 改动**：开发者规范维持原样。
- **翻译**：代码、标识符、文件路径保持英文；概念说明保持中文。
