# Glossary

每条格式：**术语**：一句话定义。

---

## A

**Action**：→ **GameAction**。带时序生命周期的行为单元，kernel 中由 `ActionService` 管理。

**AbilityDefinition**：描述一个技能的静态配置资源（冷却、cost、effect 链、conditions），保存为 `.tres`，通过 `ContentService` 按 ID 查询。→ [generated/html/classes/AbilityDefinition.html](generated/html/classes/AbilityDefinition.html)

**AbilityInstance**：运行时每个实体持有的技能状态对象（冷却计时器、当前 charges），由 `AbilityController` 管理。→ [generated/html/classes/AbilityInstance.html](generated/html/classes/AbilityInstance.html)

**AbilityController**：挂在实体 `Controllers/` 下的节点，管理该实体所有技能的注册、cast 触发、冷却 tick。→ [generated/html/classes/AbilityController.html](generated/html/classes/AbilityController.html)

**ActionContext**：`GameAction` 运行期间持有的上下文对象（source 实体、target、关联 `GameplayContext`）。→ [generated/html/classes/ActionContext.html](generated/html/classes/ActionContext.html)

**ActionService**：管理所有 `GameAction` 生命周期的 kernel 服务，通过 `"actions"` ID 获取。→ [generated/html/classes/ActionService.html](generated/html/classes/ActionService.html)

**AudioDefinition**：音频内容定义资源，把 `audio_id` 绑定到 `AudioStream`，并声明它是 SFX 还是 BGM；随 `ResourceDatabase` 加载后由 `GameBootstrap` 注册到 `AudioService`。→ [generated/html/classes/AudioDefinition.html](generated/html/classes/AudioDefinition.html)

**AudioService**：全局音频服务，播放一次性音效和背景音乐，并持久化音频总线音量。→ [generated/html/classes/AudioService.html](generated/html/classes/AudioService.html)

---

## B

**Blackboard**：状态机（`Hfsm` 或 `Fsm`）持有的共享键值存储，同一状态机内所有状态节点共享读写，用于跨状态传递临时数据。→ [generated/html/classes/Blackboard.html](generated/html/classes/Blackboard.html)

**Brain**：AI 决策基类，override `think(entity, delta)` 实现 AI 逻辑，每帧由 AI 系统调用。→ [generated/html/classes/Brain.html](generated/html/classes/Brain.html)

---

## C

**Command**：→ **GameCommand**。意图封装对象，是管线的起点。

**CastAction**：处理技能施法前摇（cast time）的内置 `GameAction`，前摇结束后执行 effect 链。→ [generated/html/classes/CastAction.html](generated/html/classes/CastAction.html)

**Command**：→ **GameCommand**

**CommandReceiver**：实体上的接口，接收 `GameCommand` 并交给状态机（`Hfsm` 或 `Fsm`）处理。同实体输入/AI 可直接调用它，跨实体按 id 路由可由 `CommandService` 转交。→ [generated/html/classes/CommandReceiver.html](generated/html/classes/CommandReceiver.html)

**CommandService**：可选命令路由服务。调用方只知道目标实体 id、没有目标节点引用时，通过 `"commands"` ID 获取并将 `GameCommand` 路由到目标实体 `CommandReceiver`。→ [generated/html/classes/CommandService.html](generated/html/classes/CommandService.html)

**Component**：挂在实体 `Components/` 子树下的 `Node`，持有运行时数据（`HealthComponent`、`StatsComponent` 等），对应四分模式中的 **Controller / Component** 角色。

**Condition**：`GameEffect.apply()` 执行前的前置检查基类，override `evaluate(ctx) -> bool`，多个 Condition 由 `ConditionEvaluator` 统一评估。→ [generated/html/classes/Condition.html](generated/html/classes/Condition.html)

**ConditionEvaluator**：工具类，`evaluate_all(conditions, ctx)` 返回是否全部通过，`collect_failures()` 收集失败原因。→ [generated/html/classes/ConditionEvaluator.html](generated/html/classes/ConditionEvaluator.html)

**ContentDefinition**：所有游戏配置资源的基类（`Resource`），子类必须实现 `get_content_id() -> String` 返回全局唯一 ID。→ [generated/html/classes/ContentDefinition.html](generated/html/classes/ContentDefinition.html)

**ContentService**：内容注册与按 ID 查询的 kernel 服务，通过 `"content"` ID 获取；`validate_all()` 在 bootstrap 时校验所有注册资源。→ [generated/html/classes/ContentService.html](generated/html/classes/ContentService.html)

**Controller**：→ 四分模式中挂在实体节点树上的 Node 层，如 `AbilityController`、`StatusEffectController`。

---

## D

**DamageRequest**：向 `CombatService` 提交伤害计算请求的数据对象（source、target、base_damage、damage_type、tags）。→ [generated/html/classes/DamageRequest.html](generated/html/classes/DamageRequest.html)

**DamageResult**：`CombatService` 返回的伤害结算结果（final_damage、is_crit、stat 中间值）。→ [generated/html/classes/DamageResult.html](generated/html/classes/DamageResult.html)

**Definition**：四分模式中的静态配置层，继承 `ContentDefinition` 或 `Resource`，保存为 `.tres`，通过 `ContentService` 查询。

**DomainEvent**：通过 `EventService` 发布的领域事件数据对象，包含事件类型和相关数据。→ [generated/html/classes/DomainEvent.html](generated/html/classes/DomainEvent.html)

---

## E

**Effect**：→ **GameEffect**。效果执行单元，是管线的末端动作层。

**EffectResult**：`GameEffect.apply()` 的返回值，包含 `success: bool`、`effect_id: String`、失败原因等。→ [generated/html/classes/EffectResult.html](generated/html/classes/EffectResult.html)

**EffectService**：执行 `GameEffect` 并维护执行历史（trace）的 kernel 服务，通过 `"effects"` ID 获取。→ [generated/html/classes/EffectService.html](generated/html/classes/EffectService.html)

**EntityIdentity**：挂在实体根节点下的组件，持有运行时唯一 `entity_id`（字符串）。→ [generated/html/classes/EntityIdentity.html](generated/html/classes/EntityIdentity.html)

**EntityContract**：实体组件/控制器/身份/状态机的语义访问入口，优先替代散落的 `get_node("Components/...")`。→ [generated/html/classes/EntityContract.html](generated/html/classes/EntityContract.html)

**EntityRoot**：实体根节点基类，持有实体约定的节点结构并提供快捷访问方法。→ [generated/html/classes/EntityRoot.html](generated/html/classes/EntityRoot.html)

**EntitySaveAgent**：实体级存档聚合器（`Node`），用稳定 `entity_id` 把实体下的 `SaveableComponent` 和显式 opt-in duck participant 写入 `entities[entity_id].components`。→ [generated/html/classes/EntitySaveAgent.html](generated/html/classes/EntitySaveAgent.html)

**EntitySpawner**：按 `EntityDefinition` 或 `PackedScene` 实例化实体、注入 `EntityIdentity` 并挂入场景树的工具类。→ [generated/html/classes/EntitySpawner.html](generated/html/classes/EntitySpawner.html)

**EventService**：领域事件广播的 kernel 服务（`"events"`），通过信号将事件发布给所有订阅方（UI、Audio、VFX）。→ [generated/html/classes/EventService.html](generated/html/classes/EventService.html)

---

## F

**FSM / Fsm**：扁平有限状态机（Flat FSM），管理一组互斥状态，按 `state_id` 单步转移，无嵌套、LCA 或命令冒泡，但与 HFSM 共享 hook 集合、`Blackboard` 与信号语义；kernel 中由 `Fsm` + `FsmState` 实现；需要嵌套结构或命令向父状态冒泡时改用 `Hfsm`。→ [generated/html/classes/Fsm.html](generated/html/classes/Fsm.html)

**FsmState**：扁平 FSM 状态基类（`Node`），互斥状态之一、无子状态，override `enter` / `exit` / `update` / `handle_command` / `can_enter` / `can_exit` 实现状态逻辑；通过 `request_transition(state_id)` 请求切换。→ [generated/html/classes/FsmState.html](generated/html/classes/FsmState.html)

---

## G

**GameAction**：带时序生命周期的行为基类（`_on_start` / `_on_update` / `_on_cancel` / `_on_complete`），由 `ActionService` 管理，执行期间驱动动画和 Hitbox 开关。→ [generated/html/classes/GameAction.html](generated/html/classes/GameAction.html)

**GameBootstrap**：启动编排节点，在 `_ready()` 中依次注册服务、加载内容、校验、加载存档、切换初始场景。→ [generated/html/classes/GameBootstrap.html](generated/html/classes/GameBootstrap.html)

**GameCommand**：意图封装对象（类型化的"玩家想做什么"），由 Input / AI / Script 创建，交给 `CommandReceiver` 或可选的 `CommandService` 路由到目标实体。→ [generated/html/classes/GameCommand.html](generated/html/classes/GameCommand.html)

**GameEffect**：效果基类（`Resource`），override `_apply_impl(ctx) -> EffectResult` 实现效果逻辑；`apply()` 先做 Condition 检查再调 `_apply_impl`。→ [generated/html/classes/GameEffect.html](generated/html/classes/GameEffect.html)

**GameplayContext**：管线中传递状态的共享信使对象（source、target、position、direction、tags、payload），从 `GameCommand` 创建，沿 Effect 链传递；模块私有字段放在 `payload`。→ [generated/html/classes/GameplayContext.html](generated/html/classes/GameplayContext.html)

---

## H

**HFSM / Hfsm**：层级有限状态机（Hierarchical FSM），支持嵌套状态、LCA 转换、命令向父状态冒泡、blackboard 注入，kernel 中由 `Hfsm` + `HfsmState` 实现；状态互斥且扁平、不需要层级时改用 `Fsm`。→ [generated/html/classes/Hfsm.html](generated/html/classes/Hfsm.html)

**HfsmState**：HFSM 状态基类（`Node`），可嵌套子状态，override `enter` / `exit` / `update` / `handle_command` / `can_enter` / `can_exit` 实现状态逻辑；通过 `request_transition(path)` 按层级路径请求切换。→ [generated/html/classes/HfsmState.html](generated/html/classes/HfsmState.html)

**HitboxComponent**：攻击碰撞体组件，在 `GameAction` 的 active 窗口内开启，命中 `HurtboxComponent` 后触发伤害。→ [generated/html/classes/HitboxComponent.html](generated/html/classes/HitboxComponent.html)

**HurtboxComponent**：受击碰撞体组件，被 `HitboxComponent` 命中时接收 `DamageRequest` 并转发给 `CombatService`。→ [generated/html/classes/HurtboxComponent.html](generated/html/classes/HurtboxComponent.html)

---

## I

**Instance**：四分模式中的运行时状态层，继承 `RefCounted`，每个实体持有独立的一份，如 `AbilityInstance`、`StatusEffectInstance`。

**Interactable**：可交互对象基类，override `_interact_impl(interactor)` 实现交互逻辑；交互检测和触发时机由 `InteractionComponent` 负责。→ [generated/html/classes/Interactable.html](generated/html/classes/Interactable.html)

---

## P

**Presentation/AnimationPlayer**：实体节点树中 `Presentation/` 下的默认动画接缝节点，是 `GameAction` 驱动动画的接缝——新代码通过 `EntityContract.get_contract_node(entity, "Presentation", "AnimationPlayer")` 访问它。

---

## R

**ResourceSet**：通用当前值/最大值资源池模型，用于 mana、stamina 等可恢复可消耗资源。→ [generated/html/classes/ResourceSet.html](generated/html/classes/ResourceSet.html)

**ResourceDatabase**：批量打包 `ContentDefinition` 资源的容器资源（`.tres`），挂到 `GameBootstrap.resource_databases` 后在启动时由 `ContentService` 统一加载。→ [generated/html/classes/ResourceDatabase.html](generated/html/classes/ResourceDatabase.html)

**RunDirector**：管理一次 roguelike Run 的节点——初始化 `RunState`、调用 `DungeonGenerator` 生成 `RoomGraph`、驱动 `RoomController` 序列推进。→ [generated/html/classes/RunDirector.html](generated/html/classes/RunDirector.html)

**RunState**：`RunDirector` 持有的当前 Run 数据对象（当前房间、房间历史、随机种子、run-level 统计）。→ [generated/html/classes/RunState.html](generated/html/classes/RunState.html)

## S

**Saveable**：全局/root 级存档节点基类（`Node`），override `to_save_data() -> Dictionary` 和 `from_save_data(data)` 实现序列化；键由 `save_id` 属性决定，并可声明 `save_scope` 分片以支持场景树缺失恢复。→ [generated/html/classes/Saveable.html](generated/html/classes/Saveable.html)

**SaveableComponent**：实体内组件级存档基类（`Node`），与 `Saveable` 同接口，键由节点 `name` 决定（实体内唯一），通常由 `EntitySaveAgent` 收集。→ [generated/html/classes/SaveableComponent.html](generated/html/classes/SaveableComponent.html)

**SaveService**：唯一存读档 facade，协调 `roots`（`Saveable`）、`entities`（`EntitySaveAgent`）与 scope-scope 持久化。→ [generated/html/classes/SaveService.html](generated/html/classes/SaveService.html)

**Service / Port**：四分模式中的全局流程层，通过类型化门面 `Mkit.xxx()` 获取（底层为 `ServiceRegistry.get_port`）；`get_service` 已废弃。

**ServiceRegistry**：唯一的框架 autoload（Node），持有服务表；推荐经 `Mkit` 门面访问。→ [generated/html/classes/ServiceRegistry.html](generated/html/classes/ServiceRegistry.html)

**Mkit（门面）**：类型化静态门面，`Mkit.combat()` 等访问器返回具体服务类型。→ [generated/html/classes/Mkit.html](generated/html/classes/Mkit.html)

**StateMachineBase**：状态机共享基类（`Node`），统一命令入口 `handle_command` 与 `state_changed` / `transition_failed` 信号，并持有 `owner_entity` 与 `blackboard`；`Hfsm` 与 `Fsm` 都继承它。实体接线层（`EntityRoot` / `CommandReceiver` / `EntityContract`）面向它编程，因此两种状态机都能即插即用挂到 `EntityRoot/StateMachine` 节点。→ [generated/html/classes/StateMachineBase.html](generated/html/classes/StateMachineBase.html)

**System / Service**：→ **Service**

---

## 架构图快速导航

## W

**Wallet**：离散货币余额模型，`ProgressionState` 通过它读写和序列化货币。→ [generated/html/classes/Wallet.html](generated/html/classes/Wallet.html)

---

## 架构图快速导航

| 想看… | 去哪… |
|-------|-------|
| 三层依赖关系图 | [architecture.md](architecture.md) |
| 管线完整时序 | [concepts.md](concepts.md) |
| 所有服务 ID 列表 | [architecture.md#完整服务-id-对照表](architecture.md) |
| 扩展点全览 | [concepts.md#模型-5扩展点地图](concepts.md) |
