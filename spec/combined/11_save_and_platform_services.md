# Save, Progression, and Platform Services

---

# 21. Save / Load 模块接口设计

---

## 21.1 Saveable

### 概念说明

- 是什么：节点可存档的契约。
- 负责什么：提供 save id、to_save_data、from_save_data。
- 为什么需要：SaveManager 不应该知道每个模块内部字段，由对象自己贡献可持久化数据。

```gdscript
class_name Saveable
extends Node

@export var save_id: String = ""

func get_save_id() -> String:
    if save_id == "":
        return owner.name
    return save_id

func to_save_data() -> Dictionary:
    return {}

func from_save_data(data: Dictionary) -> void:
    pass
```

#### 字段说明
- **save_id**：稳定 ID 字段。例：Saveable 通过 save_id 引用某个定义或运行时对象，避免直接保存节点路径。
#### 函数使用场景
- **get_save_id()**：读取数据入口。实际例子：CombatResolver 通过 get_save_id 获取最终攻击力，而不是直接读内部变量。
- **to_save_data()**：序列化。实际例子：保存游戏时把背包、装备、RunState 转成 Dictionary。
- **from_save_data()**：反序列化。实际例子：读档时用存档 Dictionary 恢复玩家 HP、位置和背包。

---

### 27.77 Saveable 使用示例

#### 详细实际用例

- 真实场景：PlayerSaveable 保存玩家位置、当前 HP、背包数据；RunSaveable 保存当前 floor、room 和 seed。
- 怎么使用：每个需要持久化的节点实现 to_save_data/from_save_data，SaveManager 只负责收集和分发。
- 验证重点：读档后对象恢复到安全状态，例如玩家回到 Idle，而不是恢复到攻击前摇中间帧。
### PlayerSaveable

```gdscript
class_name PlayerSaveable
extends Saveable

func to_save_data() -> Dictionary:
    var health := owner.get_node("Components/HealthComponent") as HealthComponent
    var inventory := owner.get_node("Controllers/InventoryController") as InventoryController
    return {
        "position": owner.global_position,
        "current_hp": health.current_hp,
        "inventory": inventory.to_save_data()
    }

func from_save_data(data: Dictionary) -> void:
    owner.global_position = data.get("position", Vector2.ZERO)
    var health := owner.get_node("Components/HealthComponent") as HealthComponent
    health.current_hp = float(data.get("current_hp", health.get_max_hp()))

    var inventory := owner.get_node("Controllers/InventoryController") as InventoryController
    inventory.from_save_data(data.get("inventory", {}))
```

---

---

---

## 21.2 SaveManager

### 概念说明

- 是什么：存档读写协调器。
- 负责什么：收集 Saveable 数据、写文件、读文件、处理版本和迁移。
- 为什么需要：玩家、背包、装备、Meta 进度和设置需要统一持久化入口。

```gdscript
class_name SaveManager
extends Node

signal save_completed(path: String)
signal load_completed(path: String)
signal save_failed(path: String, reason: String)
signal load_failed(path: String, reason: String)

@export var save_path: String = "user://save.json"
@export var save_version: int = 1
@export var game_version: String = "0.1.0"
@export var migrations: Array[SaveMigration] = []

func save_game(root: Node) -> bool:
    var payload := _collect_saveables(root)
    var data := {
        "save_version": save_version,
        "game_version": game_version,
        "timestamp": Time.get_datetime_string_from_system(true),
        "profile_id": "profile_001",
        "payload": payload
    }

    var file := FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        save_failed.emit(save_path, "Cannot open file for write")
        return false

    file.store_string(JSON.stringify(data, "  "))
    file.close()
    save_completed.emit(save_path)
    return true

func load_game(root: Node) -> bool:
    if not FileAccess.file_exists(save_path):
        load_failed.emit(save_path, "Save file does not exist")
        return false

    var file := FileAccess.open(save_path, FileAccess.READ)
    var text := file.get_as_text()
    file.close()

    var parsed = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        load_failed.emit(save_path, "Invalid JSON")
        return false

    var data: Dictionary = parsed
    data = _migrate_data(data)
    var payload: Dictionary = data.get("payload", {})
    _restore_saveables(root, payload)
    load_completed.emit(save_path)
    return true

func _collect_saveables(root: Node) -> Dictionary:
    var result: Dictionary = {}
    for node in root.find_children("*", "Saveable", true, false):
        var saveable := node as Saveable
        result[saveable.get_save_id()] = saveable.to_save_data()
    return result

func _restore_saveables(root: Node, payload: Dictionary) -> void:
    for node in root.find_children("*", "Saveable", true, false):
        var saveable := node as Saveable
        var id := saveable.get_save_id()
        if payload.has(id):
            saveable.from_save_data(payload[id])

func _migrate_data(data: Dictionary) -> Dictionary:
    var current_version := int(data.get("save_version", 1))
    while current_version < save_version:
        var migration := _find_migration(current_version, current_version + 1)
        if migration == null:
            push_warning("Missing save migration: %d -> %d" % [current_version, current_version + 1])
            break
        data = migration.migrate(data)
        current_version = int(data.get("save_version", current_version + 1))
    return data

func _find_migration(from_version: int, to_version: int) -> SaveMigration:
    for migration in migrations:
        if migration.from_version == from_version and migration.to_version == to_version:
            return migration
    return null
```

#### 字段说明
- **save_path**：资源或节点路径。例：用 save_path 指向场景或节点，方便在 Inspector 中配置。
- **migrations**：存档迁移规则。例：从 save_version 1 读到 3 时依次执行 1->2、2->3。
#### 信号说明
- **save_completed**：当 **SaveManager** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **load_completed**：当 **SaveManager** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **save_failed**：当 **SaveManager** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **load_failed**：当 **SaveManager** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **save_game()**：公开 API。实际例子：外部系统通过它请求 **SaveManager** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **load_game()**：加载流程。实际例子：ContentRegistry.load_database 把所有 item/ability/room 资源注册进表。
- **_collect_saveables()**：内部辅助函数。实际例子：由 **SaveManager** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_restore_saveables()**：内部辅助函数。实际例子：由 **SaveManager** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_migrate_data()**：内部迁移入口。实际例子：读取旧版本存档后按版本逐步升级结构。
- **_find_migration()**：内部查找迁移规则。实际例子：查找 1 -> 2 的 SaveMigration。

---

---

### 27.78 SaveManager 使用示例

#### 详细实际用例

- 真实场景：玩家结束一局后，SaveManager 保存 meta currency、已解锁能力、设置和角色永久升级。
- 怎么使用：保存时遍历 Saveable，写入带 save_version 的结构；加载时按 save_id 分发数据。
- 验证重点：旧版本存档能迁移；保存失败时 UI 能收到错误信号。
### 保存游戏

```gdscript
func save_current_game() -> void:
    var save_manager := ServiceRegistry.get_service("save") as SaveManager
    # Use the scene-tree root, not current_scene: long-lived Saveables such as
    # ProgressionSystem are children of GameBootstrap / services, which live
    # outside the active gameplay scene and would otherwise be missed.
    save_manager.save_game(get_tree().root)
```

### 读取游戏

```gdscript
func load_current_game() -> void:
    var save_manager := ServiceRegistry.get_service("save") as SaveManager
    save_manager.load_game(get_tree().root)
```

### 监听结果

```gdscript
func _ready() -> void:
    var save_manager := ServiceRegistry.get_service("save") as SaveManager
    save_manager.save_completed.connect(func(path): print("Saved: ", path))
    save_manager.load_completed.connect(func(path): print("Loaded: ", path))
    save_manager.save_failed.connect(func(path, reason): push_error(reason))
```

---

---

---

## 21.3 UpgradeDefinition

### 概念说明

- 是什么：永久或局内升级的静态定义。
- 负责什么：定义升级 ID、最大等级、货币消耗、前置条件、解锁内容和应用效果。
- 为什么需要：Roguelite 的 meta progression 需要长期可存档的升级，但奖励和角色属性仍应走 Effect/Stats 系统。

```gdscript
class_name UpgradeDefinition
extends Resource

@export var upgrade_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var max_level: int = 1
@export var currency_id: String = "meta_currency"
@export var cost_by_level: Array[int] = [100]
@export var prerequisite_upgrade_ids: Array[String] = []
@export var unlock_content_ids: Array[String] = []
@export var effects: Array[GameEffect] = []
@export var tags: Array[String] = []
@export var is_meta_upgrade: bool = true

func get_cost_for_level(next_level: int) -> int:
    var index := max(0, next_level - 1)
    if index >= cost_by_level.size():
        return cost_by_level[-1] if not cost_by_level.is_empty() else 0
    return cost_by_level[index]
```

#### 字段说明
- **upgrade_id**：升级定义 ID。例：upgrade.attack_plus_20。
- **max_level**：最大等级。例：永久生命升级最多 5 级。
- **currency_id**：消耗货币 ID。例：meta_currency、gold、shard。
- **cost_by_level**：每级消耗。例：[100, 150, 250]。
- **prerequisite_upgrade_ids**：前置升级。例：unlock.fire_magic 需要先解锁 upgrade.mage_path。
- **unlock_content_ids**：解锁内容 ID。例：解锁 ability.fireball_basic 进入可选池。
- **effects**：升级生效效果。例：增加 max_hp 或 attack_power 的 GameEffect。
- **is_meta_upgrade**：是否跨 run 持久。例：meta upgrade 存档，run upgrade 只写入 RunState。
#### 函数使用场景
- **get_cost_for_level()**：读取下一等级消耗。实际例子：ProgressionSystem 判断玩家货币是否足够。

---

### 27.96 UpgradeDefinition 使用示例

#### 详细实际用例

- 真实场景：玩家在大厅花 100 meta_currency 购买 `upgrade.attack_plus_20`，升级后每局开局给玩家一个 attack_power modifier。
- 怎么使用：UpgradeDefinition 只描述升级；是否已购买、当前等级和货币余额放 ProgressionState。
- 验证重点：max_level、生效效果和前置升级都能被内容校验和 UI 查询。

```gdscript
var upgrade := UpgradeDefinition.new()
upgrade.upgrade_id = "upgrade.attack_plus_20"
upgrade.max_level = 3
upgrade.currency_id = "meta_currency"
upgrade.cost_by_level = [100, 200, 300]
upgrade.unlock_content_ids = ["reward.attack_plus_20"]
```

---

---

---

## 21.4 ProgressionState

### 概念说明

- 是什么：玩家长期进度的纯数据状态。
- 负责什么：保存货币、升级等级和已解锁内容，并提供序列化/反序列化。
- 为什么需要：ProgressionSystem 需要一个可保存、可测试的状态对象，不能把长期状态散落在 UI 或 SaveManager 里。

```gdscript
class_name ProgressionState
extends RefCounted

var currencies: Dictionary = {} # currency_id -> amount
var upgrade_levels: Dictionary = {} # upgrade_id -> level
var unlocked_content_ids: Array[String] = []

func get_currency(currency_id: String) -> int:
    return int(currencies.get(currency_id, 0))

func add_currency(currency_id: String, amount: int) -> void:
    currencies[currency_id] = max(0, get_currency(currency_id) + amount)

func spend_currency(currency_id: String, amount: int) -> bool:
    if get_currency(currency_id) < amount:
        return false
    currencies[currency_id] = get_currency(currency_id) - amount
    return true

func get_upgrade_level(upgrade_id: String) -> int:
    return int(upgrade_levels.get(upgrade_id, 0))

func set_upgrade_level(upgrade_id: String, level: int) -> void:
    upgrade_levels[upgrade_id] = max(0, level)

func unlock_content(content_id: String) -> void:
    if not unlocked_content_ids.has(content_id):
        unlocked_content_ids.append(content_id)

func to_save_data() -> Dictionary:
    return {
        "currencies": currencies,
        "upgrade_levels": upgrade_levels,
        "unlocked_content_ids": unlocked_content_ids
    }

func from_save_data(data: Dictionary) -> void:
    currencies = data.get("currencies", {})
    upgrade_levels = data.get("upgrade_levels", {})
    unlocked_content_ids = data.get("unlocked_content_ids", [])
```

#### 字段说明
- **currencies**：长期货币表。例：meta_currency=320。
- **upgrade_levels**：升级等级表。例：upgrade.attack_plus_20=2。
- **unlocked_content_ids**：已解锁内容。例：ability.fireball_basic 已进入奖励池。
#### 函数使用场景
- **get_currency()**：读取货币余额。实际例子：大厅 UI 显示 meta currency。
- **add_currency()**：增加货币。实际例子：run 结束后发放 meta_currency。
- **spend_currency()**：花费货币。实际例子：购买永久升级。
- **get_upgrade_level()**：读取升级等级。实际例子：UI 判断按钮显示购买还是满级。
- **set_upgrade_level()**：设置升级等级。实际例子：ProgressionSystem 成功升级后写入新等级。
- **unlock_content()**：解锁内容。实际例子：购买升级后解锁新技能进入奖励池。
- **to_save_data()**：序列化。实际例子：SaveManager 保存长期进度。
- **from_save_data()**：反序列化。实际例子：启动时恢复长期进度。

---

### 27.97 ProgressionState 使用示例

#### 详细实际用例

- 真实场景：玩家死亡结算后获得 40 meta_currency，ProgressionState 增加余额；回到大厅后 UI 读取余额并显示可购买升级。
- 怎么使用：它只存数据，不执行升级效果；升级流程由 ProgressionSystem 编排。
- 验证重点：存档后重启游戏，货币、升级等级和解锁内容完整恢复。

```gdscript
var state := ProgressionState.new()
state.add_currency("meta_currency", 40)
state.set_upgrade_level("upgrade.attack_plus_20", 1)
state.unlock_content("ability.fireball_basic")
```

---

---

---

## 21.5 ProgressionSystem

### 概念说明

- 是什么：长期进度和升级购买的控制器。
- 负责什么：管理 ProgressionState，校验升级前置和货币，应用解锁与效果，并实现 Saveable。
- 为什么需要：SaveManager 不应该知道 meta currency 或升级规则；RewardSystem 也不应该直接修改永久进度。

```gdscript
class_name ProgressionSystem
extends Saveable

signal currency_changed(currency_id: String, amount: int)
signal upgrade_level_changed(upgrade_id: String, level: int)
signal content_unlocked(content_id: String)

var state := ProgressionState.new()
var content: ContentRegistry = null

func _ready() -> void:
    if save_id == "":
        save_id = "progression"
    if ServiceRegistry.has_service("content"):
        content = ServiceRegistry.get_service("content") as ContentRegistry

func add_currency(currency_id: String, amount: int) -> void:
    state.add_currency(currency_id, amount)
    currency_changed.emit(currency_id, state.get_currency(currency_id))

func can_unlock(upgrade_id: String) -> bool:
    var definition := get_definition(upgrade_id)
    if definition == null:
        return false
    var current_level := state.get_upgrade_level(upgrade_id)
    if current_level >= definition.max_level:
        return false
    for prerequisite in definition.prerequisite_upgrade_ids:
        if state.get_upgrade_level(prerequisite) <= 0:
            return false
    var next_level := current_level + 1
    return state.get_currency(definition.currency_id) >= definition.get_cost_for_level(next_level)

func unlock_or_level_up(upgrade_id: String, context: GameplayContext = null) -> bool:
    if not can_unlock(upgrade_id):
        return false
    var definition := get_definition(upgrade_id)
    var next_level := state.get_upgrade_level(upgrade_id) + 1
    var cost := definition.get_cost_for_level(next_level)
    if not state.spend_currency(definition.currency_id, cost):
        return false

    state.set_upgrade_level(upgrade_id, next_level)
    for content_id in definition.unlock_content_ids:
        state.unlock_content(content_id)
        content_unlocked.emit(content_id)

    _apply_upgrade_effects(definition, context)
    currency_changed.emit(definition.currency_id, state.get_currency(definition.currency_id))
    upgrade_level_changed.emit(upgrade_id, next_level)
    return true

func get_definition(upgrade_id: String) -> UpgradeDefinition:
    if content == null:
        content = ServiceRegistry.get_service("content") as ContentRegistry
    if content == null:
        return null
    return content.get_resource(upgrade_id) as UpgradeDefinition

func _apply_upgrade_effects(definition: UpgradeDefinition, context: GameplayContext) -> void:
    if definition.effects.is_empty():
        return
    var executor := ServiceRegistry.get_service("effects") as EffectExecutor
    if executor == null:
        return
    var ctx := context if context != null else GameplayContext.new()
    executor.execute_many(definition.effects, ctx)

func to_save_data() -> Dictionary:
    return state.to_save_data()

func from_save_data(data: Dictionary) -> void:
    state.from_save_data(data)
```

#### 信号说明
- **currency_changed**：货币变化时发出。实际例子：大厅 UI 刷新 meta currency。
- **upgrade_level_changed**：升级等级变化时发出。实际例子：升级按钮显示新等级。
- **content_unlocked**：内容解锁时发出。实际例子：新技能进入奖励池或角色选择界面。
#### 函数使用场景
- **_ready()**：初始化 save_id 并缓存 ContentRegistry。
- **add_currency()**：增加长期货币。实际例子：run 结束结算奖励。
- **can_unlock()**：购买前检查。实际例子：UI 决定按钮是否可点。
- **unlock_or_level_up()**：购买或升级入口。实际例子：大厅升级界面购买 attack upgrade。
- **get_definition()**：读取升级定义。实际例子：从 ContentRegistry 查找 UpgradeDefinition。
- **_apply_upgrade_effects()**：应用升级效果。实际例子：购买后立刻对当前玩家应用永久属性效果。
- **to_save_data()**：序列化。实际例子：SaveManager 收集 ProgressionSystem。
- **from_save_data()**：反序列化。实际例子：启动读档后恢复 meta progression。

---

### 27.98 ProgressionSystem 使用示例

#### 详细实际用例

- 真实场景：玩家结束 run 获得 120 meta_currency，回到大厅购买 `upgrade.attack_plus_20`。ProgressionSystem 扣除货币、提升升级等级、解锁相关奖励，并通过 Saveable 被 SaveManager 持久化。
- 怎么使用：长期货币和永久升级只走 ProgressionSystem；局内三选一临时奖励仍走 RewardSystem/RunState。
- 验证重点：货币不足、前置未满足、满级时不能购买；保存再加载后升级等级不丢失。

```gdscript
var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
progression.add_currency("meta_currency", 120)

if progression.can_unlock("upgrade.attack_plus_20"):
    progression.unlock_or_level_up("upgrade.attack_plus_20")
```

---

---

---

## 21.6 SaveMigration

### 概念说明

- 是什么：一个存档版本到下一个版本的数据转换规则。
- 负责什么：声明 from_version/to_version，并把旧 save Dictionary 转成新结构。
- 为什么需要：上线后字段会改名、模块会拆分；没有迁移规则，旧玩家存档会在读档时丢失或崩溃。

```gdscript
class_name SaveMigration
extends Resource

@export var from_version: int = 1
@export var to_version: int = 2

func migrate(data: Dictionary) -> Dictionary:
    var migrated := data.duplicate(true)
    migrated["save_version"] = to_version
    return _migrate_impl(migrated)

func _migrate_impl(data: Dictionary) -> Dictionary:
    return data
```

#### 字段说明
- **from_version**：源版本。例：旧存档 save_version=1。
- **to_version**：目标版本。例：迁移完成后写成 save_version=2。
#### 函数使用场景
- **migrate()**：迁移入口。实际例子：SaveManager 读取旧存档后调用 migrate。
- **_migrate_impl()**：自定义迁移实现。实际例子：把 `gold` 字段移动到 `progression.currencies.meta_currency`。

---

### 27.99 SaveMigration 使用示例

#### 详细实际用例

- 真实场景：v1 存档把 meta currency 存在 payload.player.gold，v2 改为 payload.progression.currencies.meta_currency。SaveMigration 负责转换字段，SaveManager 再把迁移后的 payload 分发给 Saveable。
- 怎么使用：每次提升 save_version 时补一个相邻版本迁移；不要在各个 Saveable 里猜测所有旧版本结构。
- 验证重点：1->2、2->3 都能独立测试；缺失迁移规则时会给 warning 而不是静默损坏数据。

```gdscript
class_name SaveMigrationV1ToV2
extends SaveMigration

func _migrate_impl(data: Dictionary) -> Dictionary:
    var payload: Dictionary = data.get("payload", {})
    var player: Dictionary = payload.get("player", {})
    var progression: Dictionary = payload.get("progression", {})
    var currencies: Dictionary = progression.get("currencies", {})
    currencies["meta_currency"] = int(player.get("gold", 0))
    progression["currencies"] = currencies
    payload["progression"] = progression
    data["payload"] = payload
    return data
```

---

---

---

# 22. Platform Service 接口设计

---

## 22.1 AnalyticsService

### 概念说明

- 是什么：玩法数据埋点接口。
- 负责什么：记录 run_started、reward_selected、death、purchase 等结构化事件。
- 为什么需要：玩法代码不应该依赖某个具体统计 SDK。

```gdscript
class_name AnalyticsService
extends Node

func track_event(event_name: String, properties: Dictionary = {}) -> void:
    pass

func set_user_property(key: String, value) -> void:
    pass
```

#### 函数使用场景
- **track_event()**：公开 API。实际例子：外部系统通过它请求 **AnalyticsService** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **set_user_property()**：写入或配置入口。实际例子：测试场景通过 set_user_property 设置黑板值或初始化运行时状态。

---

### 27.79 AnalyticsService 使用示例

#### 详细实际用例

- 真实场景：RunDirector 开始 run 时 track `run_started`，玩家死亡时 track `run_failed`，选择奖励时 track `reward_selected`。
- 怎么使用：玩法系统只调用抽象 AnalyticsService，不引用 Firebase、GameAnalytics 等具体 SDK。
- 验证重点：事件字段稳定，比如 run_id、seed、floor、reward_id；离线或 mock 模式不影响 gameplay。
```gdscript
var analytics := ServiceRegistry.get_service("analytics") as AnalyticsService
analytics.track_event("run_started", {
    "run_id": run_state.run_id,
    "seed": run_state.seed,
    "character": "warrior"
})
```

---

---

---

## 22.2 AnalyticsServiceMock

### 概念说明

- 是什么：AnalyticsService 的开发期假实现。
- 负责什么：把埋点事件打印到控制台或存到本地列表，而不是发送到真实统计平台。
- 为什么需要：在接入真实 SDK 前，你就能验证 run_started、reward_selected、death 等事件有没有被正确触发。
```gdscript
class_name AnalyticsServiceMock
extends AnalyticsService

func track_event(event_name: String, properties: Dictionary = {}) -> void:
    print("[Analytics] %s %s" % [event_name, properties])
```

#### 函数使用场景
- **track_event()**：公开 API。实际例子：外部系统通过它请求 **AnalyticsServiceMock** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.80 AnalyticsServiceMock 使用示例

#### 详细实际用例

- 真实场景：开发阶段点击 Start Run，控制台打印 `[Analytics] run_started { seed: 12345 }`，不用真的发到服务器。
- 怎么使用：Bootstrap 在 PC/Editor 环境注册 mock analytics，移动端发布再替换真实实现。
- 验证重点：所有埋点调用都能在 mock 中看到；替换真实服务时玩法代码不改。
```gdscript
func _register_platform_services() -> void:
    var analytics := AnalyticsServiceMock.new()
    add_child(analytics)
    ServiceRegistry.register_service("analytics", analytics)
```

Console 输出：

```text
[Analytics] run_started { run_id: run_123, seed: 12345 }
```

---

---

---

## 22.3 AdService

### 概念说明

- 是什么：广告平台接口。
- 负责什么：检查广告是否就绪、展示广告并发出完成或失败信号。
- 为什么需要：复活广告、奖励广告不能写死在 Run 或死亡流程里。

```gdscript
class_name AdService
extends Node

signal rewarded_ad_completed(placement_id: String)
signal rewarded_ad_failed(placement_id: String, reason: String)

func is_rewarded_ad_ready(placement_id: String) -> bool:
    return false

func show_rewarded_ad(placement_id: String) -> void:
    rewarded_ad_failed.emit(placement_id, "not_implemented")
```

#### 信号说明
- **rewarded_ad_completed**：当 **AdService** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **rewarded_ad_failed**：当 **AdService** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **is_rewarded_ad_ready()**：状态查询。实际例子：AI 调用 is_rewarded_ad_ready 判断目标是不是敌对阵营或 Action 是否结束。
- **show_rewarded_ad()**：公开 API。实际例子：外部系统通过它请求 **AdService** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.81 AdService 使用示例

#### 详细实际用例

- 真实场景：玩家死亡后，RunDirector 询问 AdService 是否有 revive rewarded ad；广告完成后恢复 50% HP。
- 怎么使用：死亡/复活流程只依赖抽象接口，不写具体广告 SDK 调用。
- 验证重点：广告未准备好、播放失败、完成奖励三种结果都有明确处理。
```gdscript
func offer_revive_ad() -> void:
    var ads := ServiceRegistry.get_service("ads") as AdService
    if ads.is_rewarded_ad_ready("revive"):
        ads.rewarded_ad_completed.connect(_on_revive_ad_completed)
        ads.show_rewarded_ad("revive")

func _on_revive_ad_completed(placement_id: String) -> void:
    if placement_id == "revive":
        $Player/Components/HealthComponent.revive(0.5)
```

---

---

---

## 22.4 AdServiceMock

### 概念说明

- 是什么：AdService 的开发期假实现。
- 负责什么：模拟广告已准备好、播放完成、奖励发放等回调。
- 为什么需要：复活广告和奖励广告流程可以先在编辑器中跑通，不必等移动广告 SDK 接入完成。
```gdscript
class_name AdServiceMock
extends AdService

func is_rewarded_ad_ready(placement_id: String) -> bool:
    return true

func show_rewarded_ad(placement_id: String) -> void:
    await get_tree().create_timer(0.5).timeout
    rewarded_ad_completed.emit(placement_id)
```

#### 函数使用场景
- **is_rewarded_ad_ready()**：状态查询。实际例子：AI 调用 is_rewarded_ad_ready 判断目标是不是敌对阵营或 Action 是否结束。
- **show_rewarded_ad()**：公开 API。实际例子：外部系统通过它请求 **AdServiceMock** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

---

### 27.82 AdServiceMock 使用示例

#### 详细实际用例

- 真实场景：编辑器里测试复活广告时，AdServiceMock 立即发出 rewarded_ad_completed("revive")，不用等待真实广告加载。
- 怎么使用：开发期用 mock 跑通 UI、死亡暂停、奖励发放和恢复战斗流程。
- 验证重点：mock 与真实服务发出的信号一致，切换实现时上层逻辑不需要改。
```gdscript
func _register_mock_ads() -> void:
    var ads := AdServiceMock.new()
    add_child(ads)
    ServiceRegistry.register_service("ads", ads)
```

### 测试 rewarded ad

```gdscript
var ads := ServiceRegistry.get_service("ads") as AdService
ads.rewarded_ad_completed.connect(func(id): print("Mock ad completed: ", id))
ads.show_rewarded_ad("revive")
```

---

