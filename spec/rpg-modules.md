# Mkit RPG Content Modules Design

## 目标

本设计用于把现有 mkit 框架补齐到能够实现一款"村庄叙事型"2D RPG 所需的可复用机制。目标游戏循环：

```text
进村 -> 进房间 -> 与房间内 NPC 对话/获取信息 -> 走出房间 -> 走出村庄
  -> 野外打怪(攻击/技能/Effect) -> 怪掉落物品 -> 升级
  -> 接任务 / 推进任务 / mark 任务完成 / 领取任务奖励
  -> 回村对话 / 商店补给(买消耗品并使用) -> 循环
  -> 全程有 BGM 与音效
```

与 `int-test.md` 一致，本设计只在 `addons/mkit/` 中新增**通用、数据驱动的机制**。具体村庄、NPC 台词、任务"杀 5 只哥布林"、商品定价、地图布局都属于游戏内容，放在 `game/`。本阶段**只产出设计文档与实施计划**,不写实现代码。

## 范围

- 设计文档：`spec/rpg-modules.md`(本文件)
- 计划新增模块：`modules/quest/`、`modules/dialogue/`、`modules/shop/`、`modules/world/`
- 计划新增 UI:`modules/ui/dialogue_ui.gd`、`modules/ui/shop_ui.gd`、`modules/ui/quest_log_ui.gd`
- 计划修改的既有文件:`kernel/registry/content_registry.gd`、`kernel/events/event_router.gd`、`kernel/bootstrap/game_bootstrap.gd`、`modules/inventory/item_definition.gd`
- 计划新增 demo 内容:`game/demo/phase8_village_rpg*`(具体内容,不进 addon)
- 最终实现完成后,按"文档计划"把每个新 class document 到 `docs/ref/` 并更新 `docs/module_layer.md`、`docs/pipeline.md`

## 现状审核结论

下表把目标游戏功能逐项映射到 mkit 现状。✅ 已具备、⚠️ 半成品需补强、❌ 缺失。

| 功能 | 状态 | 现有支撑 |
|---|---|---|
| 打怪(攻击/受击/死亡) | ✅ | `combat`(CombatResolver / Hitbox / Hurtbox)、`ai`(Brain / SimpleAIEnemyBrain)、`health` |
| 释放技能 | ✅ | `abilities`(AbilityDefinition→Instance→Controller)、`CastAction` |
| 普通攻击 | ✅ | `TimedAttackAction` |
| Effect | ✅ | kernel `effects/builtin`(deal_damage / heal / apply_status / stat_modifier / grant_item / spawn_scene)、`status_effects` |
| 掉落物品 | ✅ | `loot`(LootTable / LootSystem)、`inventory`(ItemDefinition / InventoryController) |
| 升级 | ✅ | `progression`(ExperienceComponent + ExperienceCurve,`level_up` 信号;UpgradeDefinition 升级树;currency 存取) |
| 存档 | ✅ | `save`(SaveManager / Saveable) |
| 音乐/音效 | ⚠️ | `ui/AudioManager` 可 play_sfx / play_music,但 fade 未实现、无音量持久化、无按场景切 BGM |
| 进村 / 进房间 / 走出 | ⚠️ | `SceneRouter` 只能整场景平切,**不记返回坐标**,无传送点/出生点 |
| 房间交互触发 | ⚠️ | `interaction`(Interactable / InteractionComponent)只能跑 effects 返回 bool |
| 对话 | ❌ | 无对话树/台词/分支/对话 UI |
| 任务 / mark 完成 / 任务奖励 | ❌ | 无任务定义/目标追踪/任务日志(RewardSystem 是 roguelike 选奖,非任务奖励) |
| 回村补给(商店买卖) | ❌ | currency 有存取,但**无商店/定价/买卖**,ItemDefinition 也无 `value` 字段 |

**结论**:战斗核心循环完整;缺的是"村庄叙事层"的四块通用机制——**任务、对话、商店、场景导航(传送点)**,外加 ItemDefinition 价格字段与 Audio 增强(可选)。

## 分层与依赖检查

新模块全部位于 Module 层,依赖只向下:

```text
quest      -> kernel(events / effects / content / save) , 监听 entity_died / inventory_changed
dialogue   -> kernel(content / effects / conditions) + interaction(同层)
shop       -> kernel(content) + progression(currency,同层) + inventory(同层)
world      -> kernel(scenes / events) + interaction(同层) , 可通知 ui/AudioManager
```

约束:

- 不出现 addon 依赖 `game/`;具体 NPC/任务/商品/地图全部在 `game/`。
- 新增的 domain effect(AdvanceObjectiveEffect / CompleteQuestEffect)**放在所属 module 内**,extends 的是 kernel 的 `GameEffect` 基类(module→kernel,合法),由 kernel `EffectExecutor` 多态执行,无需 kernel 反向认识它们。
- 对话/商店/任务的"目标匹配""奖励发放"统一复用既有 `Condition` / `GameEffect` / `EffectExecutor` / `EventRouter`,不新发明并行机制。

## 既有文件需要的最小改动

### 1. `kernel/registry/content_registry.gd`

`_extract_content_id()` 用**硬编码 id 属性名列表**给资源建索引。新增 Definition 必须把各自 id 字段加入该列表,否则 `register_resource` 会报 `Resource missing stable content id` 且无法被 `get_resource()` 查到。

需追加:`quest_id`、`dialogue_id`、`shop_id`、`zone_id`。

### 2. `kernel/events/event_router.gd`

追加 typed signal 与 `emit_*`,与既有风格(`entity_died` / `inventory_changed`)一致:

```gdscript
signal quest_accepted(quest_id: String)
signal quest_objective_advanced(quest_id: String, objective_id: String, current: int, required: int)
signal quest_completed(quest_id: String)
signal quest_turned_in(quest_id: String)
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal npc_talked(npc_id: String)
signal zone_changed(from_zone_id: String, to_zone_id: String)
signal item_purchased(shop_id: String, item_id: String, quantity: int)
signal item_sold(shop_id: String, item_id: String, quantity: int)
```

设计原则:`world`/`dialogue`/`shop` 在发上述 typed signal 的**同时**调用 `emit_domain_event(DomainEvent.create(type, source, target, payload))`,让 `QuestSystem` 有一条统一的 `domain_event_emitted` 匹配路径(详见 QuestSystem)。

### 3. `kernel/bootstrap/game_bootstrap.gd`

在 `_register_kernel_services()` 之后新增一段注册 module services:`quest`、`dialogue`、`shop`、`world`(构造、`add_child`、`register_service(id, svc)`)。这些是 Node service,与现有 `progression` 注册方式相同。

### 4. `modules/inventory/item_definition.gd`

新增一个字段供商店定价:

```gdscript
@export var value: int = 0
```

`value` 是物品"基础价值";商店买价/卖价在 ShopEntry / ShopDefinition 上以倍率或覆盖价表达。

## 新增 service id

| id | 类型 | 职责 |
|----|------|------|
| `quest` | `QuestSystem` | 任务接取、目标追踪、完成、发奖 |
| `dialogue` | `DialogueController` | 同一时刻运行一段对话,推进节点/选项 |
| `shop` | `ShopController` | 打开商店、买/卖、扣/加货币与物品 |
| `world` | `WorldRouter` | 带出生点的场景跳转,记录当前 zone,切 BGM |

---

# 模块设计

每个 class 按 `docs/ref` 的格式给出:概念、设计目的、文件、关键字段、接口(gdscript)、函数场景。命名遵循 `Definition(Resource) -> Instance/State/Runtime(RefCounted) -> Controller/Component/System(Node)`,强类型、无注释。

## 模块一:`modules/quest/` 任务系统

把战斗、掉落、对话、奖励串起来的中枢。任务由若干"目标"组成,目标通过监听 `EventRouter` 的事件自动推进,也可被脚本/对话直接 mark。完成后通过 `EffectExecutor` 跑奖励 effects。

### QuestDefinition

#### 概念说明
一个任务的静态配置:展示信息、目标列表、奖励 effects、前置任务、是否可重复。

#### 设计目的
让任务完全数据驱动。具体"杀 5 哥布林得 100 金"的内容放 `game/` 的 `.tres`,addon 只定义结构。

#### 文件
`res://addons/mkit/modules/quest/quest_definition.gd`

#### 接口
```gdscript
class_name QuestDefinition
extends Resource
@export var quest_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var quest_type: String = "side"
@export var objectives: Array[QuestObjectiveDefinition] = []
@export var prerequisite_quest_ids: Array[String] = []
@export var accept_conditions: Array[Condition] = []
@export var reward_effects: Array[GameEffect] = []
@export var auto_complete: bool = false
@export var repeatable: bool = false
@export var tags: Array[String] = []
func get_resource_id() -> String
```

#### 函数场景
- `get_resource_id()`:返回 `quest_id`,供 ContentRegistry 索引(并需在 `_extract_content_id` 列表登记)。
- `auto_complete=true`:所有必需目标达成即自动完成并发奖;`false` 表示需回到 NPC 处 turn-in(对话触发 CompleteQuestEffect)。

### QuestObjectiveDefinition

#### 概念说明
一个任务目标:监听哪个事件、匹配什么、需要多少次。

#### 设计目的
用"事件类型 + payload 匹配 + 计数"表达任意目标(杀怪/收集/到达/对话),不为每种目标写新类。

#### 文件
`res://addons/mkit/modules/quest/quest_objective_definition.gd`

#### 接口
```gdscript
class_name QuestObjectiveDefinition
extends Resource
@export var objective_id: String = ""
@export_multiline var description: String = ""
@export var event_type: String = ""
@export var match_key: String = ""
@export var match_value: String = ""
@export var count_payload_key: String = ""
@export var required_count: int = 1
@export var optional: bool = false
```

#### 函数场景
- `event_type`:匹配 `DomainEvent.event_type`,例如 `"enemy_killed"`、`"item_acquired"`、`"zone_entered"`、`"npc_talked"`,或游戏自定义类型。
- `match_key` / `match_value`:可选过滤,例如 `match_key="tag"`, `match_value="goblin"`,或 `match_key="item_id"`, `match_value="item.herb"`;留空表示该类型任意事件都计数。
- `count_payload_key`:可选;给定时按 `event.payload[count_payload_key]` 累加(如一次拾取多个),否则每次匹配 +1。

### QuestState

#### 概念说明
单个任务的运行时进度:状态 + 各目标计数。

#### 文件
`res://addons/mkit/modules/quest/quest_state.gd`

#### 接口
```gdscript
class_name QuestState
extends RefCounted
var quest_id: String = ""
var status: String = "available"
var objective_progress: Dictionary = {}
static func create(quest_id: String) -> QuestState
func get_progress(objective_id: String) -> int
func set_progress(objective_id: String, value: int) -> void
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

`status` 取值:`locked` / `available` / `active` / `completed`(目标达成待 turn-in)/ `turned_in` / `failed`。

### QuestLog

#### 概念说明
玩家所有 `QuestState` 的集合,按 `quest_id` 索引;负责整体存档序列化。

#### 文件
`res://addons/mkit/modules/quest/quest_log.gd`

#### 接口
```gdscript
class_name QuestLog
extends RefCounted
var states: Dictionary = {}
func get_state(quest_id: String) -> QuestState
func has(quest_id: String) -> bool
func get_active() -> Array[QuestState]
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

### QuestLogUI(放 `modules/ui/`)

#### 文件
`res://addons/mkit/modules/ui/quest_log_ui.gd`

#### 接口
```gdscript
class_name QuestLogUI
extends Control
var quest_system: QuestSystem = null
func bind(system: QuestSystem) -> void
func refresh() -> void
```

订阅 `QuestSystem.quest_accepted` / `objective_advanced` / `quest_completed` / `quest_turned_in` 后刷新 `QuestContainer`;标题优先用 `QuestDefinition.display_name`,缺失 definition 时回退到 `quest_id`;objective 行显示 `description current/required_count`。这是 UI 层默认任务日志,不持有任务推进或奖励逻辑。

### QuestSystem

#### 概念说明
任务域的核心系统,注册为 service `quest`。监听 `EventRouter` 推进目标,管理 accept/complete/turn-in,发奖。`extends Saveable` 以持久化 QuestLog。

#### 设计目的
成为任务的单一协调者:把"事件→目标推进""目标全达成→可完成""完成→发奖"集中起来,UI 与 NPC 只调用它的公开方法/订阅它的信号。

#### 文件
`res://addons/mkit/modules/quest/quest_system.gd`

#### 接口
```gdscript
class_name QuestSystem
extends Saveable
signal quest_offered(quest_id: String)
signal quest_accepted(quest_id: String)
signal objective_advanced(quest_id: String, objective_id: String, current: int, required: int)
signal quest_completed(quest_id: String)
signal quest_turned_in(quest_id: String)
var log: QuestLog = QuestLog.new()
var content: ContentRegistry = null
func can_accept(quest_id: String, context: GameplayContext) -> bool
func accept_quest(quest_id: String, context: GameplayContext) -> bool
func notify_event(event: DomainEvent) -> void
func advance_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool
func is_quest_complete(quest_id: String) -> bool
func complete_quest(quest_id: String, context: GameplayContext) -> bool
func turn_in_quest(quest_id: String, context: GameplayContext) -> bool
func get_definition(quest_id: String) -> QuestDefinition
func get_state(quest_id: String) -> QuestState
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

#### 函数场景
- `_ready()`:`save_id` 默认 `"quest"`;连接 `EventRouter`:订阅 `domain_event_emitted` 统一走 `notify_event`,并把 typed `entity_died` / 带 `change_type="added"` payload 的 `inventory_changed` 桥接成 `DomainEvent`(`enemy_killed` / `item_acquired`)再喂给 `notify_event`,保证一条匹配路径。
- `can_accept` / `accept_quest`:校验前置任务 `turned_in`、`accept_conditions`(复用 ConditionEvaluator)、是否已在进行;通过则建 `QuestState(active)`,发 `quest_accepted` + EventRouter。
- `notify_event`:遍历 `active` 任务的目标,`event_type` 命中且 `match_key/value` 通过则按计数累加,发 `objective_advanced`;若 `auto_complete` 且全部必需目标满足,调用 `complete_quest`。
- `advance_objective`:供脚本/对话/`AdvanceObjectiveEffect` 直接推进("可以 mark 任务"诉求之一),实际推进成功返回 `true`。
- `complete_quest`:必需目标全满足时把状态置 `completed`;若 `auto_complete` 直接发奖+`turned_in`,否则等 NPC turn-in。
- `turn_in_quest`:状态 `completed` 时执行 `reward_effects`(EffectExecutor),全部成功后置 `turned_in`,发 `quest_turned_in` + EventRouter;`repeatable` 任务回到 `available`;奖励失败时保持 `completed` 并返回 `false`。
- 存档:`to_save_data/from_save_data` round-trip `QuestLog`;因 `extends Saveable`,会被 `SaveManager.save_game(root)` 自动收集。

### AdvanceObjectiveEffect / CompleteQuestEffect

#### 概念说明
两个 module-local `GameEffect`,让对话选项、交互、脚本能直接推进或完成任务——满足"可以 mark 任务完成"。

#### 文件
`res://addons/mkit/modules/quest/advance_objective_effect.gd`
`res://addons/mkit/modules/quest/complete_quest_effect.gd`

#### 接口
```gdscript
class_name AdvanceObjectiveEffect
extends GameEffect
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var amount: int = 1
func _apply_impl(context: GameplayContext) -> EffectResult

class_name CompleteQuestEffect
extends GameEffect
@export var quest_id: String = ""
@export var turn_in: bool = true
func _apply_impl(context: GameplayContext) -> EffectResult
```

#### 函数场景
- 二者经 `ServiceRegistry.get_service("quest")` 拿 QuestSystem 并调用对应方法;失败返回 `EffectResult.fail`。`accept` 任务也可由对话选项挂一个 `AcceptQuestEffect`(同模式,可按需补)。

---

## 模块二:`modules/dialogue/` 对话系统

NPC 对话树:线性台词 + 分支选项,选项可挂 Condition(是否可见/可选)与 GameEffect(接任务/给物品/触发事件)。同一时刻只运行一段对话(RPG 常见)。

### DialogueDefinition

#### 文件
`res://addons/mkit/modules/dialogue/dialogue_definition.gd`

#### 接口
```gdscript
class_name DialogueDefinition
extends Resource
@export var dialogue_id: String = ""
@export var start_node_id: String = ""
@export var nodes: Array[DialogueNode] = []
func get_resource_id() -> String
func get_node(node_id: String) -> DialogueNode
```

### DialogueNode

#### 概念说明
对话中的一屏:说话人、台词、进入时 effects、后继(线性 `next_node_id` 或分支 `choices`)。

#### 文件
`res://addons/mkit/modules/dialogue/dialogue_node.gd`

#### 接口
```gdscript
class_name DialogueNode
extends Resource
@export var node_id: String = ""
@export var speaker_id: String = ""
@export_multiline var text: String = ""
@export var on_enter_effects: Array[GameEffect] = []
@export var choices: Array[DialogueChoice] = []
@export var next_node_id: String = ""
```

`choices` 非空时呈现选项;为空时按 `next_node_id` 推进,`next_node_id` 也为空表示对话结束。

### DialogueChoice

#### 文件
`res://addons/mkit/modules/dialogue/dialogue_choice.gd`

#### 接口
```gdscript
class_name DialogueChoice
extends Resource
@export_multiline var text: String = ""
@export var next_node_id: String = ""
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []
```

#### 函数场景
- `conditions`:过滤选项是否对玩家可见/可选(例如"我接这个任务"仅在未接时出现)。
- `effects`:选择时执行,例如 `AcceptQuestEffect`、`GrantItemEffect`、`CompleteQuestEffect`。

### DialogueRuntime

#### 文件
`res://addons/mkit/modules/dialogue/dialogue_runtime.gd`

#### 接口
```gdscript
class_name DialogueRuntime
extends RefCounted
var dialogue_id: String = ""
var current_node_id: String = ""
var history: Array[String] = []
var context: GameplayContext = null
```

### DialogueController

#### 概念说明
对话域的核心,注册为 service `dialogue`。运行当前会话:进入节点(跑 on_enter_effects、发节点信号)、按选项/线性推进、结束。

#### 设计目的
单一会话协调者。NPC 的 Interactable 只负责"用哪个 dialogue_id 启动",节点呈现交给 DialogueUI(订阅信号),选项的判定与副作用复用 Condition / Effect。

#### 文件
`res://addons/mkit/modules/dialogue/dialogue_controller.gd`

#### 接口
```gdscript
class_name DialogueController
extends Node
signal dialogue_started(dialogue_id: String)
signal node_entered(node: DialogueNode)
signal choices_presented(node: DialogueNode, available: Array[DialogueChoice])
signal dialogue_ended(dialogue_id: String)
var runtime: DialogueRuntime = null
var content: ContentRegistry = null
func is_active() -> bool
func start(dialogue_id: String, context: GameplayContext) -> bool
func get_available_choices() -> Array[DialogueChoice]
func choose(choice_index: int) -> void
func advance() -> void
func end() -> void
```

#### 函数场景
- `start`:已有会话时拒绝;从 ContentRegistry 取 DialogueDefinition,建 runtime,发 `dialogue_started` + EventRouter `dialogue_started`,进入 `start_node_id`。
- 进入节点:执行 `on_enter_effects`,发 `node_entered`;有 choices 则过滤可用项发 `choices_presented`。
- `choose`:执行该选项 `effects`,跳到 `next_node_id`(空则 `end`)。
- `advance`:线性节点前进。
- `end`:发 `dialogue_ended` + EventRouter;若该 NPC 用于任务"talk to",由 DialogueInteractable 在 start 时发 `npc_talked` 事件(见下),供 QuestSystem 计数。

### DialogueInteractable

#### 概念说明
`extends Interactable`,把"交互"绑定到"启动一段对话"。

#### 文件
`res://addons/mkit/modules/dialogue/dialogue_interactable.gd`

#### 接口
```gdscript
class_name DialogueInteractable
extends Interactable
@export var dialogue_id: String = ""
@export var npc_id: String = ""
func _interact_impl(context: GameplayContext) -> bool
```

#### 函数场景
- `_interact_impl`:经 service `dialogue` 启动对话;并发 `EventRouter.npc_talked(npc_id)` + `emit_domain_event("npc_talked", payload={"npc_id": npc_id})`,供任务"与 X 对话"目标计数。这是"房间里 NPC 给信息/给任务"的入口。

### DialogueUI(放 `modules/ui/`)

#### 文件
`res://addons/mkit/modules/ui/dialogue_ui.gd`

#### 接口
```gdscript
class_name DialogueUI
extends Control
func bind(controller: DialogueController) -> void
```

订阅 `node_entered` 显示台词、`choices_presented` 生成选项按钮(点击回调 `controller.choose(i)`)、`dialogue_ended` 关闭。与 `reward_selection_ui.gd` 同层同风格。

---

## 模块三:`modules/shop/` 商店补给

复用 `ProgressionSystem` 的 currency(`add/get/spend_currency`)作钱包,复用 `InventoryController` 增减物品。本模块只补"交易层":目录、定价、买/卖。

### ShopDefinition

#### 文件
`res://addons/mkit/modules/shop/shop_definition.gd`

#### 接口
```gdscript
class_name ShopDefinition
extends Resource
@export var shop_id: String = ""
@export var display_name: String = ""
@export var currency_id: String = "gold"
@export var entries: Array[ShopEntry] = []
@export var buy_price_multiplier: float = 1.0
@export var sell_price_multiplier: float = 0.5
@export var allow_sell: bool = true
func get_resource_id() -> String
```

### ShopEntry

#### 文件
`res://addons/mkit/modules/shop/shop_entry.gd`

#### 接口
```gdscript
class_name ShopEntry
extends Resource
@export var item_id: String = ""
@export var price_override: int = -1
@export var stock: int = -1
@export var conditions: Array[Condition] = []
```

`price_override < 0` 时用 `ItemDefinition.value`;`stock < 0` 表示无限;`conditions` 用于解锁/限购门槛。

### ShopController

#### 概念说明
商店域核心,注册为 service `shop`。打开某商店、计算价格、执行买卖。

#### 设计目的
把"能不能买(货币够吗、有货吗、条件过吗)"和"怎么买(扣币、加物品、减库存、发事件)"集中,UI 只调用它。买消耗品 + 既有 `use_effects`/`HealEffect` 即"回村补给"。

#### 文件
`res://addons/mkit/modules/shop/shop_controller.gd`

#### 接口
```gdscript
class_name ShopController
extends Node
signal shop_opened(shop_id: String)
signal item_purchased(item_id: String, quantity: int, total_cost: int)
signal item_sold(item_id: String, quantity: int, total_gain: int)
signal transaction_failed(item_id: String, reason: String)
var current_shop: ShopDefinition = null
var content: ContentRegistry = null
func open_shop(shop_id: String) -> bool
func get_buy_price(item_id: String) -> int
func get_sell_price(item_id: String) -> int
func can_buy(item_id: String, quantity: int, buyer: Node) -> bool
func buy(item_id: String, quantity: int, buyer: Node) -> bool
func sell(item_instance_id: String, quantity: int, seller: Node) -> bool
func close_shop() -> void
```

#### 函数场景
- `buy`:`can_buy` 通过后,`ProgressionSystem.spend_currency(currency_id, total)`(已有);成功则用 `GrantItemEffect`/`InventoryController.add_item` 入包,减 `stock`,发 `item_purchased` + EventRouter。任一步失败发 `transaction_failed`。
- `sell`:`allow_sell` 时从买家背包移除物品,`add_currency(value * sell_price_multiplier)`,发 `item_sold`。
- 货币与背包都经 `ServiceRegistry` 取 `progression` 与买家 `Controllers/InventoryController`,不自己持有状态(钱包持久化由 ProgressionSystem 负责)。

### ShopUI(放 `modules/ui/`)
`res://addons/mkit/modules/ui/shop_ui.gd`,`extends Control`,`bind(controller)` 列出 entries、价格、买/卖按钮,订阅 controller 信号刷新。

---

## 模块四:`modules/world/` 场景导航与传送点

把 `SceneRouter` 的"平切场景"升级为"带出生点的 zone 跳转",解决"走出房间回到村里原来的位置""进村/进房间/出村"的导航与返回坐标问题,并按 zone 切 BGM、发 zone 事件供任务计数。

### ZoneDefinition

#### 文件
`res://addons/mkit/modules/world/zone_definition.gd`

#### 接口
```gdscript
class_name ZoneDefinition
extends Resource
@export var zone_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var bgm_id: String = ""
@export var default_spawn_id: String = "default"
@export var tags: Array[String] = []
func get_resource_id() -> String
```

### SpawnPoint

#### 概念说明
场景内一个命名出生点(村口、房间门口、传送落点)。

#### 文件
`res://addons/mkit/modules/world/spawn_point.gd`

#### 接口
```gdscript
class_name SpawnPoint
extends Marker2D
@export var spawn_id: String = "default"
func _ready() -> void
```

`_ready()` 把自己加入 group `"spawn_point"`,供 WorldRouter 在新场景中按 `spawn_id` 查找。

### Portal

#### 概念说明
`extends Interactable` 的"门/出口":交互后请求 WorldRouter 跳到目标 zone 的目标出生点。

#### 设计目的
复用 InteractionComponent 的就近选择 + Condition 门槛。玩家走到门口按交互键即转场;若要"走进区域自动转场",游戏侧可用一个 Area2D 在 `body_entered` 里直接调 `WorldRouter.go_to_zone()`——addon 只提供交互式 Portal,自动式留给 `game/`,保持最小。

#### 文件
`res://addons/mkit/modules/world/portal.gd`

#### 接口
```gdscript
class_name Portal
extends Interactable
@export var target_zone_id: String = ""
@export var target_spawn_id: String = "default"
func _interact_impl(context: GameplayContext) -> bool
```

### WorldRouter

#### 概念说明
世界导航核心,注册为 service `world`,包裹 `SceneRouter`。记录当前 zone、待落点 spawn_id;场景切换完成后把玩家移到对应 SpawnPoint;发 `zone_changed` 并切 BGM。

#### 设计目的
让"去某地并落在某点"成为一次调用,且可在切换前记录"返回点",实现房间↔村庄的来回。把场景级 BGM 与 zone 进入事件集中,供 AudioManager 与 QuestSystem 消费。

#### 文件
`res://addons/mkit/modules/world/world_router.gd`

#### 接口
```gdscript
class_name WorldRouter
extends Node
signal zone_changed(from_zone_id: String, to_zone_id: String)
@export var player_group: String = "player"
var current_zone_id: String = ""
var _pending_spawn_id: String = ""
var scene_router: SceneRouter = null
var content: ContentRegistry = null
func go_to_zone(zone_id: String, spawn_id: String = "") -> bool
func get_current_zone() -> ZoneDefinition
```

#### 函数场景
- `go_to_zone`:取 ZoneDefinition;记 `_pending_spawn_id`(空则用 `default_spawn_id`);经 `SceneRouter.change_scene(scene_path)` 切换;监听 `SceneRouter.scene_changed` 回调里:在 group `"spawn_point"` 找匹配 `spawn_id` 的 SpawnPoint,把 group `player` 的玩家 `global_position` 设过去;发 `zone_changed` + `EventRouter.zone_changed` + `emit_domain_event("zone_entered", payload={"zone_id": zone_id})`(供任务"到达 X"计数);若 `bgm_id` 非空,调 `AudioManager.play_music(bgm_id)`(经 service `ui`/`audio` 获取,缺失则跳过)。
- 返回坐标:房间的出口 Portal 设 `target_zone_id="village"`, `target_spawn_id="village_room_door"`,村庄场景在该门口放同名 SpawnPoint,即可"出房回到原位"。

### Audio 增强(可选,改既有 `modules/ui/audio_manager.gd`)
- `play_music(music_id, fade_seconds)` 真正实现淡入淡出(目前忽略 `fade_seconds`)。
- 增加 `set_bus_volume(bus, db)` 并接 `Saveable` 持久化音量设置。
- 由 WorldRouter 的 `zone_changed` 驱动按 zone 自动换曲(上面已接)。
此项不阻塞主功能,列为后续增强。

---

## Pipeline 接入(将补充到 docs/pipeline.md)

```text
Dialogue Pipeline
  InteractionComponent.try_interact -> DialogueInteractable._interact_impl
  -> DialogueController.start -> node_entered(on_enter_effects via EffectExecutor)
  -> choices_presented -> DialogueUI -> choose(effects) -> ... -> dialogue_ended
  -> EventRouter(dialogue_started/npc_talked/dialogue_ended)

Quest Pipeline
  EventRouter(domain_event_emitted / entity_died / inventory_changed)
  -> inventory_changed(added payload) bridges to item_acquired
  -> QuestSystem.notify_event -> objective_advanced
  -> (auto_complete) complete_quest / (NPC) DialogueChoice -> CompleteQuestEffect
  -> turn_in_quest -> reward_effects via EffectExecutor(stop on failure) -> EventRouter(quest_turned_in)

Shop Pipeline
  DialogueChoice/Interactable -> ShopController.open_shop -> ShopUI
  -> buy -> ProgressionSystem.spend_currency + GrantItemEffect/InventoryController
  -> EventRouter(item_purchased)

World Navigation Pipeline
  Portal._interact_impl -> WorldRouter.go_to_zone -> SceneRouter.change_scene
  -> place player at SpawnPoint(spawn_id) -> AudioManager.play_music(bgm)
  -> EventRouter(zone_changed / zone_entered)
```

## game/ 内容放置(demo,phase8)

具体内容全部在 `game/demo/`,不进 addon:

- `game/demo/phase8_village_rpg.tscn` + `bootstrap_phase8.tscn`(注册新 service、加载新 ResourceDatabase)。
- 场景:`village.tscn`(含若干 NPC + DialogueInteractable + 进房间 Portal + 出村 Portal + SpawnPoint)、`village_room.tscn`(NPC 给信息/任务 + 出口 Portal)、`field.tscn`(刷怪 + 怪掉落 LootTable + 回村 Portal)。
- Resources:`QuestDefinition`/`QuestObjectiveDefinition`、`DialogueDefinition`/`DialogueNode`/`DialogueChoice`、`ShopDefinition`/`ShopEntry`、`ZoneDefinition`、给现有怪/物品的 `value` 与 BGM/SFX 资产映射。
- NPC = EntityRoot(无战斗组件)+ `Interactable`/`DialogueInteractable`,沿用既有实体节点布局约定。

## 测试计划(GUT,放 `test/unit/modules/`)

命名遵循 `test_tc_<area>_<nn>_<desc>`。

- `test_quest_system.gd`
  - `test_tc_quest_01_accept_requires_prerequisites_and_conditions`
  - `test_tc_quest_02_kill_event_advances_objective_to_complete`
  - `test_tc_quest_03_item_acquired_event_counts_with_payload_key`
  - `test_tc_quest_04_auto_complete_grants_reward_effects`
  - `test_tc_quest_05_manual_turn_in_grants_reward_and_repeatable_resets`
  - `test_tc_quest_06_save_load_roundtrips_quest_log`
- `test_quest_log_ui.gd`
  - `test_tc_qlui_01_bind_renders_empty_and_refreshes_from_quest_signals`
  - `test_tc_qlui_02_refresh_sorts_states_and_falls_back_to_quest_id`
  - `test_tc_qlui_03_bind_with_missing_container_is_safe`
  - `test_tc_qlui_04_repeatable_turn_in_renders_final_reset_state`
- `test_dialogue_controller.gd`
  - `test_tc_dlg_01_start_enters_start_node_and_runs_enter_effects`
  - `test_tc_dlg_02_choices_filtered_by_conditions`
  - `test_tc_dlg_03_choose_runs_effects_and_advances`
  - `test_tc_dlg_04_linear_advance_until_end_emits_ended`
  - `test_tc_dlg_05_second_start_rejected_while_active`
- `test_shop_controller.gd`
  - `test_tc_shop_01_buy_spends_currency_and_grants_item`
  - `test_tc_shop_02_buy_fails_when_currency_insufficient`
  - `test_tc_shop_03_stock_decrements_and_blocks_when_zero`
  - `test_tc_shop_04_sell_removes_item_and_adds_currency`
  - `test_tc_shop_05_price_override_and_multipliers`
- `test_world_router.gd`
  - `test_tc_world_01_go_to_zone_changes_scene_and_sets_pending_spawn`
  - `test_tc_world_02_player_placed_at_matching_spawn_point`
  - `test_tc_world_03_zone_changed_event_and_bgm_triggered`
  - `test_tc_world_04_missing_zone_definition_fails_gracefully`
- 既有改动回归:ContentRegistry 能注册并查到新 id(`test_content_registry.gd` 补 case);ItemDefinition `value` 默认值不破坏现有 loot/inventory 测试。
- integration:在 `spec/int-test.md` 的矩阵补 Dialogue / Quest / Shop / World Navigation 四条 pipeline,各加 1 个端到端 case。

## 文档计划(实现完成后)

- 为每个新 class 在 `docs/ref/` 建 `<ClassName>.md`,沿用现有格式(概念说明 / 设计目的 / 文件 / 字段说明 / 接口 / 函数使用场景 / 使用示例)。共需:QuestDefinition、QuestObjectiveDefinition、QuestState、QuestLog、QuestSystem、AdvanceObjectiveEffect、CompleteQuestEffect、DialogueDefinition、DialogueNode、DialogueChoice、DialogueRuntime、DialogueController、DialogueInteractable、DialogueUI、ShopDefinition、ShopEntry、ShopController、ShopUI、ZoneDefinition、SpawnPoint、Portal、WorldRouter、QuestLogUI。
- 更新 `docs/module_layer.md`:新增 quest / dialogue / shop / world 四个 domain 段落与 class 链接。
- 更新 `docs/pipeline.md`:加入上面四条新 pipeline。
- 更新 `docs/readme.md` 的 Docs Index / Core Data Model 例子(增加 `QuestDefinition -> QuestState -> QuestSystem` 等配对)。
- 中文概念段保持中文,代码与标识符保持英文(沿用现有文档约定)。

## 实施顺序计划

1. **Kernel 地基**:改 `content_registry.gd` 的 id 列表;给 `event_router.gd` 加新 signal + `emit_*`;给 `item_definition.gd` 加 `value`。先跑 `make ut-kernel` 确认无回归。
2. **quest 模块**(最高价值、其它模块的奖励/事件枢纽):实现 Definition/Objective/State/Log/System + 两个 effect;写 `test_quest_system.gd`;`make ut-modules`。
3. **dialogue 模块**:实现对话树 + Controller + DialogueInteractable + DialogueUI;选项接 quest effects 验证联动;写 `test_dialogue_controller.gd`。
4. **shop 模块**:实现 ShopDefinition/Entry/Controller + ShopUI,复用 progression 货币与 inventory;写 `test_shop_controller.gd`。
5. **world 模块**:实现 ZoneDefinition/SpawnPoint/Portal/WorldRouter,接 SceneRouter 与 AudioManager;写 `test_world_router.gd`。
6. **bootstrap 接线**:在 `game_bootstrap.gd` 注册 quest/dialogue/shop/world 四个 service。
7. **(可选)Audio 增强**:实现 fade、音量持久化、按 zone 换曲。
8. **(可选)QuestLogUI**:实现任务日志 UI,绑定 QuestSystem 信号显示任务列表与 objective 进度。
9. **demo 内容**:做 `game/demo/phase8_village_rpg`(村庄/房间/野外三场景 + NPC + 任务/对话/商店/zone 资源),手动跑通完整循环。
10. **integration**:按 `spec/int-test.md` 补四条新 pipeline 的端到端 case。
11. **`.uid` 与文档**:每个新 `.gd` 跑一次 Godot/GUT 生成 `.gd.uid` 并提交;按"文档计划"补 `docs/ref` 与 layer/pipeline/readme。
12. **全量验证**:`make ut` 全绿;layering 自查(无 addon→game 反向依赖、无 addon 内具体内容)。

## 风险与约束

- **ContentRegistry id 列表是硬编码的**:漏登记新 id 会导致 `register_resource` 报错且 `get_resource` 查不到。这是新内容类型最易踩的坑。
- **`InventoryController` 不是 `Saveable`**(见 `int-test.md`):shop 改变背包后,背包持久化仍走既有限制;`QuestSystem`/`ProgressionSystem` 是 `Saveable` 会被自动收集,任务与货币能存,但物品需沿用项目既有的背包存档方式。
- **ServiceRegistry 是 autoload**:新增 service 同样需在测试 teardown 中 `for c in ServiceRegistry.get_children(): c.queue_free()` 再 `clear()`,避免重复服务(见 int-test 约束)。
- **Area2D overlap 需 physics frame**:Portal / InteractionComponent 基于 Area2D,headless 测试需 CollisionShape2D + 匹配 layer/mask + `await physics_frame`;world/dialogue 的交互式 case 优先直接调 controller 公开方法,避免依赖物理帧导致 flaky。
- **同时只一段对话/一个商店**:DialogueController 与 ShopController 设计为单活动会话/单活动商店;若未来需要并发,需要改为 per-instance,届时再评估。
- **module 间依赖**:dialogue→interaction、shop→progression/inventory、world→interaction 属于同层 module 互相引用,符合既有惯例(combat→health、room→loot/reward),但严禁任何 module→game 的反向依赖。

## 完成标准

- 上述四模块的核心机制均有 GUT 单测覆盖,`make ut` 全绿。
- `spec/int-test.md` 矩阵新增的 Dialogue / Quest / Shop / World Navigation 四条 pipeline 各至少 1 个 integration case 覆盖。
- `game/demo/phase8_village_rpg` 能手动跑通:进村→进房间→NPC 对话接任务→出房→野外打怪掉落升级→任务自动/turn-in 发奖→回村商店补给→BGM/SFX 正常。
- 每个新 class 有对应 `docs/ref/<ClassName>.md`,`docs/module_layer.md` / `pipeline.md` / `readme.md` 同步更新。
- 新增 `.gd` 均生成并提交 `.gd.uid`。
- 无 addon→`game/` 反向依赖,addon 内无具体游戏内容(村名/NPC/任务/定价/地图均在 `game/`)。
