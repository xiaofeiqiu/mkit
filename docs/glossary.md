# Glossary

每条格式：**术语**：一句话定义。

---

## A

**Action**：→ **GameAction**。带时序生命周期的行为单元，kernel 中由 `ActionService` 管理。

**AbilityDefinition**：描述一个技能的静态配置资源（冷却、cost、effect 链、conditions），保存为 `.tres`，通过 `ContentService` 按 ID 查询。→ [ref/modules/AbilityDefinition.md](ref/modules/AbilityDefinition.md)

**AbilityInstance**：运行时每个实体持有的技能状态对象（冷却计时器、当前 charges），由 `AbilityController` 管理。→ [ref/modules/AbilityInstance.md](ref/modules/AbilityInstance.md)

**AbilityController**：挂在实体 `Controllers/` 下的节点，管理该实体所有技能的注册、cast 触发、冷却 tick。→ [ref/modules/AbilityController.md](ref/modules/AbilityController.md)

**ActionContext**：`GameAction` 运行期间持有的上下文对象（source 实体、target、关联 `GameplayContext`）。→ [ref/kernel/ActionContext.md](ref/kernel/ActionContext.md)

**ActionService**：管理所有 `GameAction` 生命周期的 kernel 服务，通过 `"actions"` ID 获取。→ [ref/kernel/ActionService.md](ref/kernel/ActionService.md)

**AudioDefinition**：音频内容定义资源，把 `audio_id` 绑定到 `AudioStream`，并声明它是 SFX 还是 BGM；随 `ResourceDatabase` 加载后由 `GameBootstrap` 注册到 `AudioService`。→ [ref/kernel/AudioDefinition.md](ref/kernel/AudioDefinition.md)

**AudioService**：全局音频服务，播放一次性音效和背景音乐，并持久化音频总线音量。→ [ref/kernel/AudioService.md](ref/kernel/AudioService.md)

---

## B

**Blackboard**：`StateMachine` 持有的共享键值存储，同一状态机内所有 `State` 节点共享读写，用于跨状态传递临时数据。→ [ref/kernel/Blackboard.md](ref/kernel/Blackboard.md)

**Brain**：AI 决策基类，override `think(entity, delta)` 实现 AI 逻辑，每帧由 AI 系统调用。→ [ref/modules/Brain.md](ref/modules/Brain.md)

---

## C

**Command**：→ **GameCommand**。意图封装对象，是管线的起点。

**CastAction**：处理技能施法前摇（cast time）的内置 `GameAction`，前摇结束后执行 effect 链。→ [ref/modules/CastAction.md](ref/modules/CastAction.md)

**Command**：→ **GameCommand**

**CommandReceiver**：实体上的接口，接收 `CommandService` 路由来的 `GameCommand` 并交给 `StateMachine` 处理。→ [ref/kernel/CommandReceiver.md](ref/kernel/CommandReceiver.md)

**CommandService**：将 `GameCommand` 路由到目标实体 `CommandReceiver` 的 kernel 服务，通过 `"commands"` ID 获取。→ [ref/kernel/CommandService.md](ref/kernel/CommandService.md)

**Component**：挂在实体 `Components/` 子树下的 `Node`，持有运行时数据（`HealthComponent`、`StatsComponent` 等），对应四分模式中的 **Controller / Component** 角色。

**Condition**：`GameEffect.apply()` 执行前的前置检查基类，override `evaluate(ctx) -> bool`，多个 Condition 由 `ConditionEvaluator` 统一评估。→ [ref/kernel/Condition.md](ref/kernel/Condition.md)

**ConditionEvaluator**：工具类，`evaluate_all(conditions, ctx)` 返回是否全部通过，`collect_failures()` 收集失败原因。→ [ref/kernel/ConditionEvaluator.md](ref/kernel/ConditionEvaluator.md)

**ContentDefinition**：所有游戏配置资源的基类（`Resource`），子类必须实现 `get_content_id() -> String` 返回全局唯一 ID。→ [ref/kernel/ContentDefinition.md](ref/kernel/ContentDefinition.md)

**ContentService**：内容注册与按 ID 查询的 kernel 服务，通过 `"content"` ID 获取；`validate_all()` 在 bootstrap 时校验所有注册资源。→ [ref/kernel/ContentService.md](ref/kernel/ContentService.md)

**Controller**：→ 四分模式中挂在实体节点树上的 Node 层，如 `AbilityController`、`StatusEffectController`。

---

## D

**DamageRequest**：向 `CombatService` 提交伤害计算请求的数据对象（source、target、base_damage、damage_type、tags）。→ [ref/modules/DamageRequest.md](ref/modules/DamageRequest.md)

**DamageIntent**：`CombatService` 从 `DamageRequest` 转换出的伤害意图，承载可复用的攻击元数据、标签与命中状态配置。→ [ref/modules/DamageIntent.md](ref/modules/DamageIntent.md)

**DamageResolution**：伤害结算中间结果，记录最终数值、闪避/暴击/格挡、命中状态和 trace。→ [ref/modules/DamageResolution.md](ref/modules/DamageResolution.md)

**DamageApplication**：把 `DamageResolution` 装配为公开 `DamageResult` 的终态对象。→ [ref/modules/DamageApplication.md](ref/modules/DamageApplication.md)

**DamageResult**：`CombatService` 返回的伤害结算结果（final_damage、is_crit、stat 中间值）。→ [ref/modules/DamageResult.md](ref/modules/DamageResult.md)

**Definition**：四分模式中的静态配置层，继承 `ContentDefinition` 或 `Resource`，保存为 `.tres`，通过 `ContentService` 查询。

**DomainEvent**：通过 `EventService` 发布的领域事件数据对象，包含事件类型和相关数据。→ [ref/kernel/DomainEvent.md](ref/kernel/DomainEvent.md)

---

## E

**Effect**：→ **GameEffect**。效果执行单元，是管线的末端动作层。

**EffectResult**：`GameEffect.apply()` 的返回值，包含 `success: bool`、`effect_id: String`、失败原因等。→ [ref/kernel/EffectResult.md](ref/kernel/EffectResult.md)

**EffectService**：执行 `GameEffect` 并维护执行历史（trace）的 kernel 服务，通过 `"effects"` ID 获取。→ [ref/kernel/EffectService.md](ref/kernel/EffectService.md)

**EntityIdentity**：挂在实体根节点下的组件，持有运行时唯一 `entity_id`（字符串）。→ [ref/kernel/EntityIdentity.md](ref/kernel/EntityIdentity.md)

**EntityContract**：实体组件/控制器/身份/状态机的语义访问入口，优先替代散落的 `get_node("Components/...")`。→ [ref/kernel/EntityContract.md](ref/kernel/EntityContract.md)

**EntityRoot**：实体根节点基类，持有实体约定的节点结构并提供快捷访问方法。→ [ref/kernel/EntityRoot.md](ref/kernel/EntityRoot.md)

**EntitySaveAgent**：实体级存档聚合器（`Node`），用稳定 `entity_id` 把实体下的 `SaveableComponent` 和显式 opt-in duck participant 写入 `entities[entity_id].components`。→ [ref/kernel/EntitySaveAgent.md](ref/kernel/EntitySaveAgent.md)

**EntitySpawner**：按 `EntityDefinition` 或 `PackedScene` 实例化实体、注入 `EntityIdentity` 并挂入场景树的工具类。→ [ref/modules/EntitySpawner.md](ref/modules/EntitySpawner.md)

**EventService**：领域事件广播的 kernel 服务（`"events"`），通过信号将事件发布给所有订阅方（UI、Audio、VFX、Analytics）。→ [ref/kernel/EventService.md](ref/kernel/EventService.md)

---

## G

**GameAction**：带时序生命周期的行为基类（`_on_start` / `_on_update` / `_on_cancel` / `_on_complete`），由 `ActionService` 管理，执行期间驱动动画和 Hitbox 开关。→ [ref/kernel/GameAction.md](ref/kernel/GameAction.md)

**GameBootstrap**：启动编排节点，在 `_ready()` 中依次注册服务、加载内容、校验、加载存档、切换初始场景。→ [ref/kernel/GameBootstrap.md](ref/kernel/GameBootstrap.md)

**GameCommand**：意图封装对象（类型化的"玩家想做什么"），由 Input / AI / Script 创建，通过 `CommandService` 路由到目标实体。→ [ref/kernel/GameCommand.md](ref/kernel/GameCommand.md)

**GameEffect**：效果基类（`Resource`），override `_apply_impl(ctx) -> EffectResult` 实现效果逻辑；`apply()` 先做 Condition 检查再调 `_apply_impl`。→ [ref/kernel/GameEffect.md](ref/kernel/GameEffect.md)

**GameplayContext**：管线中传递状态的共享信使对象（source、target、ability_id、amount、direction、tags、payload），从 `GameCommand` 创建，沿 Effect 链传递。→ [ref/kernel/GameplayContext.md](ref/kernel/GameplayContext.md)

---

## H

**HFSM / StateMachine**：层级有限状态机（Hierarchical FSM），支持嵌套状态、LCA 转换、blackboard 注入，kernel 中由 `StateMachine` + `State` 实现。→ [ref/kernel/StateMachine.md](ref/kernel/StateMachine.md)

**HitboxComponent**：攻击碰撞体组件，在 `GameAction` 的 active 窗口内开启，命中 `HurtboxComponent` 后触发伤害。→ [ref/modules/HitboxComponent.md](ref/modules/HitboxComponent.md)

**HurtboxComponent**：受击碰撞体组件，被 `HitboxComponent` 命中时接收 `DamageRequest` 并转发给 `CombatService`。→ [ref/modules/HurtboxComponent.md](ref/modules/HurtboxComponent.md)

---

## I

**Instance**：四分模式中的运行时状态层，继承 `RefCounted`，每个实体持有独立的一份，如 `AbilityInstance`、`StatusEffectInstance`。

**Interactable**：可交互对象基类，override `_interact_impl(interactor)` 实现交互逻辑；交互检测和触发时机由 `InteractionComponent` 负责。→ [ref/modules/Interactable.md](ref/modules/Interactable.md)

---

## P

**Platform Adapter**：隔离平台相关服务的接口层（`AnalyticsService`、`IAPService`、`AdService`、`CloudSaveService`），开发期默认注册 Mock 实现，发布时替换为真实 SDK。

**Presentation/AnimationPlayer**：实体节点树中 `Presentation/` 下的默认动画接缝节点，是 `GameAction` 驱动动画的接缝——新代码通过 `EntityContract.get_contract_node(entity, "Presentation", "AnimationPlayer")` 访问它。

---

## R

**ResourceSet**：通用当前值/最大值资源池模型，用于 mana、stamina 等可恢复可消耗资源。→ [ref/modules/ResourceSet.md](ref/modules/ResourceSet.md)

**ResourceDatabase**：批量打包 `ContentDefinition` 资源的容器资源（`.tres`），挂到 `GameBootstrap.resource_databases` 后在启动时由 `ContentService` 统一加载。→ [ref/kernel/ResourceDatabase.md](ref/kernel/ResourceDatabase.md)

**RunDirector**：管理一次 roguelike Run 的节点——初始化 `RunState`、调用 `DungeonGenerator` 生成 `RoomGraph`、驱动 `RoomController` 序列推进。→ [ref/modules/RunDirector.md](ref/modules/RunDirector.md)

**RunState**：`RunDirector` 持有的当前 Run 数据对象（当前房间、房间历史、随机种子、run-level 统计）。→ [ref/modules/RunState.md](ref/modules/RunState.md)

## S

**Saveable**：全局/root 级存档节点基类（`Node`），override `to_save_data() -> Dictionary` 和 `from_save_data(data)` 实现序列化；键由 `save_id` 属性决定，并可声明 `save_scope` 分片以支持场景树缺失恢复。→ [ref/kernel/Saveable.md](ref/kernel/Saveable.md)

**SaveableComponent**：实体内组件级存档基类（`Node`），与 `Saveable` 同接口，键由节点 `name` 决定（实体内唯一），通常由 `EntitySaveAgent` 收集。→ [ref/kernel/SaveableComponent.md](ref/kernel/SaveableComponent.md)

**SaveService**：唯一存读档 facade，协调 `roots`（`Saveable`）、`entities`（`EntitySaveAgent`）与 scope-scope 持久化。→ [ref/kernel/SaveService.md](ref/kernel/SaveService.md)

**Service / Port**：四分模式中的全局流程层，通过 `ServiceRegistry.get_port(ServiceRegistry.SERVICE_*)` 获取；`get_service` / `get_service_or_null` 为兼容入口。

**ServiceRegistry**：唯一的框架 autoload（Node），持有服务表，`get_port` 提供带类型检查的访问。→ [ref/kernel/ServiceRegistry.md](ref/kernel/ServiceRegistry.md)

**State**：HFSM 状态基类（`Node`），override `enter` / `exit` / `update` / `handle_command` / `can_enter` / `can_exit` 实现状态逻辑；通过 `request_transition(path)` 请求状态切换。→ [ref/kernel/State.md](ref/kernel/State.md)

**StateMachine**：HFSM 根节点，管理状态树、执行 LCA 转换、按帧 tick 活跃状态链、分发 `GameCommand`。→ [ref/kernel/StateMachine.md](ref/kernel/StateMachine.md)

**System / Service**：→ **Service**

---

## 架构图快速导航

## W

**Wallet**：离散货币余额模型，`ProgressionState` 通过它读写和序列化货币。→ [ref/modules/Wallet.md](ref/modules/Wallet.md)

---

## 架构图快速导航

| 想看… | 去哪… |
|-------|-------|
| 三层依赖关系图 | [architecture.md](architecture.md) |
| 管线完整时序 | [concepts.md](concepts.md) |
| 所有服务 ID 列表 | [architecture.md#完整服务-id-对照表](architecture.md) |
| 扩展点全览 | [concepts.md#模型-5扩展点地图](concepts.md) |
