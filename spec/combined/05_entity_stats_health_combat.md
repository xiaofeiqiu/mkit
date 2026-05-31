# Entity, Stats, Health, and Combat

---

# 8. Entity 模块接口设计

---

## 8.1 EntityIdentity

### 概念说明

- 是什么：玩法实体的身份证。
- 负责什么：保存 entity_id、definition_id、faction、tags 等识别信息。
- 为什么需要：系统需要判断“这是玩家、敌人、Boss、召唤物还是投射物”，但不应该依赖节点名字或具体脚本类。

`res://addons/mkit/modules/entity/entity_identity.gd`

```gdscript
class_name EntityIdentity
extends Node

@export var entity_id: String = ""
@export var definition_id: String = ""
@export var display_name: String = ""
@export var faction: String = "neutral"
@export var tags: Array[String] = []

func _ready() -> void:
    if entity_id == "":
        entity_id = "%s_%d" % [name.to_snake_case(), Time.get_ticks_usec()]

func has_tag(tag: String) -> bool:
    return tags.has(tag)

func has_any_tag(input_tags: Array[String]) -> bool:
    for tag in input_tags:
        if tags.has(tag):
            return true
    return false

func is_faction(value: String) -> bool:
    return faction == value
```

#### 字段说明
- **entity_id**：运行时实体 ID。例：场景里有三个 goblin，它们都来自 enemy.goblin_basic，但运行时应分别是 goblin_001、goblin_002、goblin_003，这样伤害、死亡、AI 目标和 Debug 才能指向具体个体。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **faction**：阵营。例：player 的攻击只伤害 enemy faction，敌人之间不会互相误伤。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**EntityIdentity** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **has_tag()**：存在性查询。实际例子：奖励生成前检查玩家是否已经拥有某个标签、物品或服务。
- **has_any_tag()**：存在性查询。实际例子：奖励生成前检查玩家是否已经拥有某个标签、物品或服务。
- **is_faction()**：状态查询。实际例子：AI 调用 is_faction 判断目标是不是敌对阵营或 Action 是否结束。

---

### 27.31 EntityIdentity 使用示例

#### 详细实际用例

- 真实场景：房间里有三个 goblin，它们的 `definition_id` 都是 `enemy.goblin_basic`，但 `entity_id` 分别是 `goblin_001/002/003`。玩家打中第二只时，伤害事件必须指向 `goblin_002`。
- 怎么使用：静态内容用 definition_id，运行时个体用 entity_id；faction 和 tags 给战斗、AI、条件系统判断敌我和类型。
- 验证重点：DebugOverlay、伤害事件、掉落归属都能区分具体实体，而不是只看到 “Goblin”。
### Player 配置

```gdscript
func _ready() -> void:
    var identity := $EntityIdentity as EntityIdentity
    identity.entity_id = "player_001"
    identity.definition_id = "entity.player.default"
    identity.faction = "player"
    identity.tags = ["player", "living", "controllable"]
```

### 判断目标 faction

```gdscript
func is_enemy(target: Node) -> bool:
    var identity := target.get_node_or_null("EntityIdentity") as EntityIdentity
    return identity != null and identity.faction == "enemy"
```

---

---

---

## 8.2 EntityRoot

### 概念说明

- 是什么：玩法实体场景的组合根节点。
- 负责什么：把 identity、components、controllers、behavior、presentation 串起来，并提供组件查找入口。
- 为什么需要：组合式实体比深继承更适合 RPG：玩家、敌人、召唤物、陷阱可以共享组件但有不同组合。

`res://addons/mkit/modules/entity/entity_root.gd`

```gdscript
class_name EntityRoot
extends CharacterBody2D

@onready var identity: EntityIdentity = $EntityIdentity
@onready var state_machine: StateMachine = $StateMachine
@onready var command_receiver: CommandReceiver = $CommandReceiver

func get_entity_id() -> String:
    if identity == null:
        return name
    return identity.entity_id

func get_component(component_name: String) -> Node:
    return get_node_or_null("Components/%s" % component_name)

func get_controller(controller_name: String) -> Node:
    return get_node_or_null("Controllers/%s" % controller_name)
```

#### 字段说明
- **state_machine**：所属状态机引用。例：AttackState 完成后通过 state_machine 请求回到 Idle。
#### 函数使用场景
- **get_entity_id()**：读取数据入口。实际例子：CombatResolver 通过 get_entity_id 获取最终攻击力，而不是直接读内部变量。
- **get_component()**：读取数据入口。实际例子：CombatResolver 通过 get_component 获取最终攻击力，而不是直接读内部变量。
- **get_controller()**：读取数据入口。实际例子：CombatResolver 通过 get_controller 获取最终攻击力，而不是直接读内部变量。

---

---

### 27.32 EntityRoot 使用示例

#### 详细实际用例

- 真实场景：`PlayerEntity.tscn` 的根节点是 EntityRoot，下面有 `Components/HealthComponent`、`Components/StatsComponent`、`Controllers/AbilityController`。
- 怎么使用：外部系统通过 `get_component("HealthComponent")` 或 `get_controller("AbilityController")` 找能力，不直接依赖深层节点路径。
- 验证重点：玩家和敌人可以共享 Health/Stats/Status 组件，但挂不同 AI、Input 或 Presentation。
```gdscript
func print_player_info(player: EntityRoot) -> void:
    print(player.get_entity_id())

    var health := player.get_component("HealthComponent") as HealthComponent
    print("HP: ", health.current_hp)

    var abilities := player.get_controller("AbilityController") as AbilityController
    print("Has fireball: ", abilities.has_ability("ability.fireball_basic"))
```

---

---

---

## 8.3 EntityDefinition

### 概念说明

- 是什么：可生成实体的静态定义，例如玩家默认形态、goblin、slime、陷阱或召唤物。
- 负责什么：定义实体内容 ID、场景路径、默认阵营、标签、基础属性、初始技能和掉落表。
- 为什么需要：RoomController、Spawner、存档恢复和调试工具都需要通过稳定 ID 找到实体场景，不能把 enemy_id 到 scene_path 的映射写散。

`res://addons/mkit/modules/entity/entity_definition.gd`

```gdscript
class_name EntityDefinition
extends Resource

@export var entity_definition_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var default_faction: String = "neutral"
@export var tags: Array[String] = []
@export var base_stats: Dictionary = {} # stat_id -> value
@export var starting_ability_ids: Array[String] = []
@export var loot_table_id: String = ""
```

#### 字段说明
- **entity_definition_id**：实体定义 ID。例：enemy.goblin_basic 用于房间生成、存档恢复和 ContentRegistry 查询。
- **scene_path**：实体场景路径。例：enemy.goblin_basic 指向 `res://game/enemies/goblin_basic.tscn`。
- **default_faction**：默认阵营。例：敌人定义默认 faction=enemy，生成后 EntityIdentity 会继承它。
- **tags**：标签集合。例：enemy、boss、summon、trap，用于条件、AI 和伤害过滤。
- **base_stats**：基础属性表。例：goblin 的 max_hp=30、attack_power=8、move_speed=110。
- **starting_ability_ids**：初始技能 ID。例：boss 生成后自动注册 ability.boss_rage。
- **loot_table_id**：死亡掉落表 ID。例：enemy.goblin_basic 死亡后使用 loot.goblin_common。

---

### 27.87 EntityDefinition 使用示例

#### 详细实际用例

- 真实场景：`RoomDefinition.enemy_spawn_ids` 写入 `enemy.goblin_basic`，EntitySpawner 通过 ContentRegistry 找到 EntityDefinition，再实例化对应 Goblin 场景。
- 怎么使用：房间、生成器和存档只保存 entity_definition_id；具体场景路径和默认配置放在定义里。
- 验证重点：缺失 scene_path 或重复 entity_definition_id 会在内容校验或生成阶段报错。

```gdscript
var goblin := EntityDefinition.new()
goblin.entity_definition_id = "enemy.goblin_basic"
goblin.display_name = "Goblin"
goblin.scene_path = "res://game/enemies/goblin_basic.tscn"
goblin.default_faction = "enemy"
goblin.tags = ["enemy", "living", "melee"]
goblin.base_stats = {
    "max_hp": 30.0,
    "attack_power": 8.0,
    "move_speed": 110.0
}
goblin.loot_table_id = "loot.goblin_common"
```

---

---

---

## 8.4 EntitySpawner

### 概念说明

- 是什么：通过 EntityDefinition 创建实体节点的统一入口。
- 负责什么：加载实体场景、挂到指定父节点、初始化 EntityIdentity、基础属性和初始技能。
- 为什么需要：房间刷怪、召唤物、陷阱和读档恢复都需要生成实体；统一入口可以保证 ID、阵营、属性和事件链一致。

`res://addons/mkit/modules/entity/entity_spawner.gd`

```gdscript
class_name EntitySpawner
extends Node

signal entity_spawned(entity: Node, definition_id: String)
signal entity_spawn_failed(definition_id: String, reason: String)

var content: ContentRegistry = null

func _ready() -> void:
    content = ServiceRegistry.get_service("content") as ContentRegistry

func spawn_entity(definition_id: String, parent: Node, position: Vector2 = Vector2.ZERO, runtime_id: String = "") -> Node:
    var definition := _get_definition(definition_id)
    if definition == null:
        entity_spawn_failed.emit(definition_id, "missing_definition")
        return null
    if definition.scene_path == "":
        entity_spawn_failed.emit(definition_id, "missing_scene_path")
        return null

    var scene := load(definition.scene_path) as PackedScene
    if scene == null:
        entity_spawn_failed.emit(definition_id, "cannot_load_scene")
        return null

    var entity := scene.instantiate()
    parent.add_child(entity)
    if entity is Node2D:
        entity.global_position = position

    _initialize_identity(entity, definition, runtime_id)
    _initialize_stats(entity, definition)
    _initialize_abilities(entity, definition)

    entity_spawned.emit(entity, definition_id)
    return entity

func _get_definition(definition_id: String) -> EntityDefinition:
    if content == null:
        content = ServiceRegistry.get_service("content") as ContentRegistry
    if content == null:
        return null
    return content.get_resource(definition_id) as EntityDefinition

func _initialize_identity(entity: Node, definition: EntityDefinition, runtime_id: String) -> void:
    var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
    if identity == null:
        return
    identity.definition_id = definition.entity_definition_id
    identity.display_name = definition.display_name
    identity.faction = definition.default_faction
    identity.tags = definition.tags.duplicate()
    if runtime_id != "":
        identity.entity_id = runtime_id

func _initialize_stats(entity: Node, definition: EntityDefinition) -> void:
    var stats := entity.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats == null:
        return
    for stat_id in definition.base_stats.keys():
        stats.set_base_stat(str(stat_id), float(definition.base_stats[stat_id]))

func _initialize_abilities(entity: Node, definition: EntityDefinition) -> void:
    var abilities := entity.get_node_or_null("Controllers/AbilityController") as AbilityController
    if abilities == null:
        return
    for ability_id in definition.starting_ability_ids:
        abilities.register_ability(ability_id)
```

#### 信号说明
- **entity_spawned**：实体生成成功时发出。实际例子：RoomController 用它记录 active enemy。
- **entity_spawn_failed**：实体生成失败时发出。实际例子：房间配置了不存在的 enemy id，DebugOverlay 显示具体原因。
#### 函数使用场景
- **_ready()**：进入场景树后缓存 ContentRegistry。
- **spawn_entity()**：生成实体入口。实际例子：RoomController 生成 enemy.goblin_basic。
- **_get_definition()**：读取实体定义。实际例子：通过 ContentRegistry 查询 EntityDefinition。
- **_initialize_identity()**：初始化身份信息。实际例子：把 definition_id、faction、tags 写入 EntityIdentity。
- **_initialize_stats()**：初始化基础属性。实际例子：把定义里的 max_hp 和 attack_power 写入 StatsComponent。
- **_initialize_abilities()**：初始化初始技能。实际例子：Boss 生成后注册默认技能。

---

### 27.88 EntitySpawner 使用示例

#### 详细实际用例

- 真实场景：进入战斗房时，RoomController 对 `enemy_spawn_ids` 逐个调用 EntitySpawner，生成实体后记录它们的 runtime entity_id；敌人死亡事件再通过这些 ID 更新房间状态。
- 怎么使用：任何系统需要“从定义生成实体”都走 spawner；不要在 Room、AI、Effect 中各自手写 scene_path 加载和 identity 初始化。
- 验证重点：生成后的 EntityIdentity.definition_id、faction、tags 和 StatsComponent 基础值与 EntityDefinition 一致。

```gdscript
var spawner := $EntitySpawner as EntitySpawner
var enemy := spawner.spawn_entity(
    "enemy.goblin_basic",
    $Enemies,
    Vector2(320, 160)
)
```

---

---

---

# 9. Stats 模块接口设计

---

## 9.1 StatDefinition

### 概念说明

- 是什么：一个属性类型的静态定义，例如 max_hp、attack_power、move_speed、crit_chance。
- 负责什么：定义属性 ID、默认值、取值范围和编辑器/显示层需要的元数据。
- 为什么需要：装备、Buff、奖励和敌人缩放都会修改属性；先定义属性类型，StatsComponent 才能用同一套规则计算最终值。
`res://addons/mkit/modules/stats/stat_definition.gd`

```gdscript
class_name StatDefinition
extends Resource

@export var stat_id: String = ""
@export var display_name: String = ""
@export var default_value: float = 0.0
@export var min_value: float = -INF
@export var max_value: float = INF
@export var is_percent: bool = false
```

#### 字段说明
- **stat_id**：稳定 ID 字段。例：StatDefinition 通过 stat_id 引用某个定义或运行时对象，避免直接保存节点路径。

---

### 27.33 StatDefinition 使用示例

#### 详细实际用例

- 真实场景：你定义 `attack_power`、`move_speed`、`crit_chance`。铁剑、Buff、奖励都引用这些 stat_id 修改属性。
- 怎么使用：先定义属性类型，再让 StatsComponent 用这些定义计算值。不要让装备随意创建拼写不一致的 `"atk"`、`"attack"`。
- 验证重点：不存在的 stat_id 在内容校验或运行时应报错，避免奖励加了一个无效属性。
```gdscript
var attack := StatDefinition.new()
attack.stat_id = "attack_power"
attack.display_name = "Attack Power"
attack.default_value = 10.0
attack.min_value = 0.0
attack.max_value = 9999.0
```

---

---

---

## 9.2 StatModifierDefinition

### 概念说明

- 是什么：一个“如何改变属性”的静态规则，例如 attack_power +5、move_speed +20%、max_hp clamp 到 1 以上。
- 负责什么：描述修改哪个 stat、用 FlatAdd/PercentAdd/PercentMultiply/Override 等哪种操作、数值是多少、如何叠加。
- 为什么需要：铁剑、燃烧 Debuff、房间祝福、Run 奖励都可能改属性；统一 modifier 定义可以避免每个系统自己改最终数值。
```gdscript
class_name StatModifierDefinition
extends Resource

enum Operation {
    FLAT_ADD,
    PERCENT_ADD,
    PERCENT_MULTIPLY,
    OVERRIDE,
    CLAMP_MIN,
    CLAMP_MAX
}

enum StackingRule {
    STACK,
    REPLACE_SAME_SOURCE,
    HIGHEST_ONLY,
    LOWEST_ONLY,
    UNIQUE
}

@export var modifier_id: String = ""
@export var stat_id: String = ""
@export var operation: Operation = Operation.FLAT_ADD
@export var value: float = 0.0
@export var priority: int = 0
@export var stacking_rule: StackingRule = StackingRule.STACK
@export var tags: Array[String] = []
```

#### 字段说明
- **modifier_id**：稳定 ID 字段。例：StatModifierDefinition 通过 modifier_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **stat_id**：稳定 ID 字段。例：StatModifierDefinition 通过 stat_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。

---

### 27.34 StatModifierDefinition 使用示例

#### 详细实际用例

- 真实场景：铁剑提供 `attack_power +5 flat`，狂暴 Buff 提供 `attack_power +20% percent_add`，房间诅咒提供 `move_speed -10%`。
- 怎么使用：把“怎么改属性”写成 modifier definition，来源可以是装备、状态、奖励或房间规则。
- 验证重点：FlatAdd、PercentAdd、PercentMultiply 的计算顺序稳定，叠加规则符合设计。
```gdscript
var sword_attack := StatModifierDefinition.new()
sword_attack.modifier_id = "mod.sword_iron.attack"
sword_attack.stat_id = "attack_power"
sword_attack.operation = StatModifierDefinition.Operation.FLAT_ADD
sword_attack.value = 5.0
sword_attack.stacking_rule = StatModifierDefinition.StackingRule.UNIQUE
```

---

---

---

## 9.3 StatModifier

### 概念说明

- 是什么：正在生效的运行时属性修改实例。
- 负责什么：记录 modifier 来源、剩余时间、叠加层数、优先级和当前是否仍然有效。
- 为什么需要：同一个 +20% attack 奖励可能永久存在，也可能只持续 10 秒；运行时实例让系统能正确过期、移除和调试。
```gdscript
class_name StatModifier
extends RefCounted

var modifier_id: String = ""
var stat_id: String = ""
var source_id: String = ""
var operation: StatModifierDefinition.Operation
var value: float = 0.0
var priority: int = 0
var stacking_rule: StatModifierDefinition.StackingRule
var remaining_duration: float = -1.0
var tags: Array[String] = []

static func from_definition(definition: StatModifierDefinition, source: String, duration: float = -1.0) -> StatModifier:
    var m := StatModifier.new()
    m.modifier_id = definition.modifier_id
    m.stat_id = definition.stat_id
    m.source_id = source
    m.operation = definition.operation
    m.value = definition.value
    m.priority = definition.priority
    m.stacking_rule = definition.stacking_rule
    m.remaining_duration = duration
    m.tags = definition.tags.duplicate()
    return m
```

#### 字段说明
- **modifier_id**：稳定 ID 字段。例：StatModifier 通过 modifier_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **stat_id**：稳定 ID 字段。例：StatModifier 通过 stat_id 引用某个定义或运行时对象，避免直接保存节点路径。
- **source_id**：行为来源 ID。例：伤害事件里 source_id=player_001，Analytics 和仇恨系统就知道是谁造成了伤害。
- **remaining_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
#### 函数使用场景
- **from_definition()**：公开 API。实际例子：外部系统通过它请求 **StatModifier** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.35 StatModifier 使用示例

#### 详细实际用例

- 真实场景：玩家装备铁剑后生成一个来自 `item_instance_001` 的 attack_power modifier；卸下铁剑时按 source_id 移除它。
- 怎么使用：运行时 modifier 应记录来源和持续时间，方便过期、移除和 Debug。
- 验证重点：Buff 过期或装备卸下后最终属性恢复，不留下幽灵加成。
```gdscript
var modifier := StatModifier.from_definition(
    sword_attack,
    "item_instance_001"
)

var stats := player.get_node("Components/StatsComponent") as StatsComponent
stats.add_modifier(modifier)
```

---

---

---

## 9.4 StatsComponent

### 概念说明

- 是什么：实体属性的计算组件。
- 负责什么：保存基础属性、运行时 modifier，并计算最终属性值。
- 为什么需要：移动、战斗、技能、UI 和 AI 都要读最终属性，必须有一个权威计算入口。

`res://addons/mkit/modules/stats/stats_component.gd`

```gdscript
class_name StatsComponent
extends Node

signal stat_changed(stat_id: String, old_value: float, new_value: float)

@export var base_stats: Dictionary = {
    "max_hp": 100.0,
    "attack_power": 10.0,
    "defense": 0.0,
    "move_speed": 160.0,
    "max_mana": 0.0,
    "max_stamina": 100.0,
    "attack_speed": 1.0,
    "crit_chance": 0.05,
    "crit_damage": 1.5,
    "cooldown_reduction": 0.0,
    "luck": 0.0,
    "damage_multiplier": 1.0,
    "healing_multiplier": 1.0
}

var modifiers_by_stat: Dictionary = {}
var cached_values: Dictionary = {}
var dirty_stats: Dictionary = {}

func _ready() -> void:
    mark_all_dirty()

func get_stat_value(stat_id: String, default_value: float = 0.0) -> float:
    if not base_stats.has(stat_id) and not modifiers_by_stat.has(stat_id):
        return default_value

    if dirty_stats.get(stat_id, true):
        cached_values[stat_id] = _calculate_stat(stat_id)
        dirty_stats[stat_id] = false

    return cached_values[stat_id]

func set_base_stat(stat_id: String, value: float) -> void:
    var old := get_stat_value(stat_id, value)
    base_stats[stat_id] = value
    mark_dirty(stat_id)
    var new_value := get_stat_value(stat_id)
    stat_changed.emit(stat_id, old, new_value)

func add_modifier(modifier: StatModifier) -> void:
    if modifier == null or modifier.stat_id == "":
        return

    if not modifiers_by_stat.has(modifier.stat_id):
        modifiers_by_stat[modifier.stat_id] = []

    var list: Array = modifiers_by_stat[modifier.stat_id]
    _apply_stacking_rule(list, modifier)
    list.append(modifier)
    mark_dirty(modifier.stat_id)
    _emit_stat_changed(modifier.stat_id)

func remove_modifier(modifier_id: String, source_id: String = "") -> void:
    for stat_id in modifiers_by_stat.keys():
        var list: Array = modifiers_by_stat[stat_id]
        var removed := false
        for modifier in list.duplicate():
            if modifier.modifier_id == modifier_id and (source_id == "" or modifier.source_id == source_id):
                list.erase(modifier)
                removed = true
        if removed:
            mark_dirty(stat_id)
            _emit_stat_changed(stat_id)

func remove_modifiers_from_source(source_id: String) -> void:
    for stat_id in modifiers_by_stat.keys():
        var list: Array = modifiers_by_stat[stat_id]
        var removed := false
        for modifier in list.duplicate():
            if modifier.source_id == source_id:
                list.erase(modifier)
                removed = true
        if removed:
            mark_dirty(stat_id)
            _emit_stat_changed(stat_id)

func tick_modifiers(delta: float) -> void:
    for stat_id in modifiers_by_stat.keys():
        var list: Array = modifiers_by_stat[stat_id]
        var removed := false
        for modifier in list.duplicate():
            if modifier.remaining_duration > 0:
                modifier.remaining_duration -= delta
                if modifier.remaining_duration <= 0:
                    list.erase(modifier)
                    removed = true
        if removed:
            mark_dirty(stat_id)
            _emit_stat_changed(stat_id)

func mark_dirty(stat_id: String) -> void:
    dirty_stats[stat_id] = true

func mark_all_dirty() -> void:
    for stat_id in base_stats.keys():
        dirty_stats[stat_id] = true
    for stat_id in modifiers_by_stat.keys():
        dirty_stats[stat_id] = true

func _calculate_stat(stat_id: String) -> float:
    var base_value := float(base_stats.get(stat_id, 0.0))
    var value := base_value
    var modifiers: Array = modifiers_by_stat.get(stat_id, [])

    var flat_add := 0.0
    var percent_add := 0.0
    var percent_multiply := 1.0
    var override_values: Array[float] = []
    var clamp_min := -INF
    var clamp_max := INF

    modifiers.sort_custom(func(a, b): return a.priority < b.priority)

    for m: StatModifier in modifiers:
        match m.operation:
            StatModifierDefinition.Operation.FLAT_ADD:
                flat_add += m.value
            StatModifierDefinition.Operation.PERCENT_ADD:
                percent_add += m.value
            StatModifierDefinition.Operation.PERCENT_MULTIPLY:
                percent_multiply *= m.value
            StatModifierDefinition.Operation.OVERRIDE:
                override_values.append(m.value)
            StatModifierDefinition.Operation.CLAMP_MIN:
                clamp_min = max(clamp_min, m.value)
            StatModifierDefinition.Operation.CLAMP_MAX:
                clamp_max = min(clamp_max, m.value)

    value = base_value + flat_add
    value *= 1.0 + percent_add
    value *= percent_multiply

    if override_values.size() > 0:
        value = override_values[-1]

    value = clamp(value, clamp_min, clamp_max)
    return value

func _apply_stacking_rule(list: Array, modifier: StatModifier) -> void:
    match modifier.stacking_rule:
        StatModifierDefinition.StackingRule.REPLACE_SAME_SOURCE:
            for existing in list.duplicate():
                if existing.source_id == modifier.source_id and existing.modifier_id == modifier.modifier_id:
                    list.erase(existing)
        StatModifierDefinition.StackingRule.UNIQUE:
            for existing in list.duplicate():
                if existing.modifier_id == modifier.modifier_id:
                    list.erase(existing)
        _:
            pass

func _emit_stat_changed(stat_id: String) -> void:
    var new_value := get_stat_value(stat_id)
    stat_changed.emit(stat_id, cached_values.get(stat_id, new_value), new_value)
```

#### 字段说明
- **modifiers_by_stat**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
#### 信号说明
- **stat_changed**：当 **StatsComponent** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**StatsComponent** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **get_stat_value()**：读取数据入口。实际例子：CombatResolver 通过 get_stat_value 获取最终攻击力，而不是直接读内部变量。
- **set_base_stat()**：写入或配置入口。实际例子：测试场景通过 set_base_stat 设置黑板值或初始化运行时状态。
- **add_modifier()**：添加操作。实际例子：玩家拾取药水时 add_item 把 ItemInstance 放入背包。
- **remove_modifier()**：移除操作。实际例子：使用药水后 remove_item 减少堆叠数量。
- **remove_modifiers_from_source()**：移除操作。实际例子：使用药水后 remove_item 减少堆叠数量。
- **tick_modifiers()**：公开 API。实际例子：外部系统通过它请求 **StatsComponent** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **mark_dirty()**：公开 API。实际例子：外部系统通过它请求 **StatsComponent** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **mark_all_dirty()**：公开 API。实际例子：外部系统通过它请求 **StatsComponent** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_calculate_stat()**：内部辅助函数。实际例子：由 **StatsComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_apply_stacking_rule()**：内部辅助函数。实际例子：由 **StatsComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_emit_stat_changed()**：内部辅助函数。实际例子：由 **StatsComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.36 StatsComponent 使用示例

#### 详细实际用例

- 真实场景：玩家基础 attack_power=10，铁剑 +5，奖励 +20%。StatsComponent 计算最终攻击力供 CombatResolver 使用。
- 怎么使用：任何系统需要属性值都调用 `get_stat_value()`，不要直接读基础值或自己手算 modifier。
- 验证重点：添加/移除 modifier 后发出 stat changed，HUD 和 DebugOverlay 能看到最终值变化。
### 读取属性

```gdscript
var stats := player.get_node("Components/StatsComponent") as StatsComponent
var attack := stats.get_stat_value("attack_power", 10.0)
var move_speed := stats.get_stat_value("move_speed", 160.0)
```

### 添加 buff

```gdscript
var buff_def := StatModifierDefinition.new()
buff_def.modifier_id = "mod.buff.attack_20_percent"
buff_def.stat_id = "attack_power"
buff_def.operation = StatModifierDefinition.Operation.PERCENT_ADD
buff_def.value = 0.20

var buff := StatModifier.from_definition(buff_def, "status.berserk", 5.0)
stats.add_modifier(buff)
```

### 每帧 tick 临时 modifier

```gdscript
func _process(delta: float) -> void:
    $Components/StatsComponent.tick_modifiers(delta)
```

---

---

---

# 10. Health 模块接口设计

---

## 10.1 HealthComponent

### 概念说明

- 是什么：实体生命值状态的拥有者。
- 负责什么：追踪 current/max HP、应用伤害和治疗、发出 damaged/healed/died 信号。
- 为什么需要：伤害公式、死亡流程和 UI 显示都依赖 HP，但扣血本身应该只有一个明确入口。

`res://addons/mkit/modules/health/health_component.gd`

```gdscript
class_name HealthComponent
extends Node

signal health_changed(current: float, max_value: float)
signal damaged(result: DamageResult)
signal healed(amount: float, source: Node)
signal died(owner_entity: Node)

@export var current_hp: float = 100.0
@export var destroy_on_death: bool = false

var dead: bool = false
var stats: StatsComponent = null

func _ready() -> void:
    stats = owner.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats != null:
        stats.stat_changed.connect(_on_stat_changed)
    current_hp = min(current_hp, get_max_hp())

func get_max_hp() -> float:
    if stats != null:
        return stats.get_stat_value("max_hp", 100.0)
    return 100.0

func apply_damage(result: DamageResult) -> void:
    if dead:
        return
    if result == null or result.was_evaded:
        return

    var old_hp := current_hp
    current_hp = max(0.0, current_hp - result.final_amount)
    result.was_lethal = current_hp <= 0.0

    # 施加 CombatResolver 已掷定的 on-hit 状态（如命中触发的 burn）。
    # 这里是伤害落地的唯一汇聚点：Hitbox 路径和 DealDamageEffect 路径都经过它，
    # 所以状态附加只写一处即可对两条路径生效。
    _apply_on_hit_statuses(result)

    damaged.emit(result)
    health_changed.emit(current_hp, get_max_hp())

    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_damage_applied(result)

    if current_hp <= 0.0:
        die(result.source)

func _apply_on_hit_statuses(result: DamageResult) -> void:
    if result.status_applications.is_empty():
        return
    var controller := owner.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
    if controller == null:
        return
    for entry in result.status_applications:
        controller.apply_status(
            str(entry.get("status_id", "")),
            result.source,
            int(entry.get("stacks", 1)),
            float(entry.get("duration", -1.0))
        )

func heal(amount: float, source: Node = null) -> void:
    if dead:
        return
    if amount <= 0:
        return

    current_hp = min(get_max_hp(), current_hp + amount)
    healed.emit(amount, source)
    health_changed.emit(current_hp, get_max_hp())

func die(killer: Node = null) -> void:
    if dead:
        return
    dead = true
    current_hp = 0.0
    died.emit(owner)

    var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
    var entity_id := identity.entity_id if identity != null else owner.name

    var events := ServiceRegistry.get_service("events") as EventRouter
    if events != null:
        events.emit_entity_died(entity_id, owner)

    if destroy_on_death:
        owner.queue_free()

func revive(percent: float = 1.0) -> void:
    dead = false
    current_hp = get_max_hp() * clamp(percent, 0.0, 1.0)
    health_changed.emit(current_hp, get_max_hp())

func _on_stat_changed(stat_id: String, old_value: float, new_value: float) -> void:
    if stat_id == "max_hp":
        current_hp = min(current_hp, new_value)
        health_changed.emit(current_hp, new_value)
```

#### 字段说明
- **current_hp**：当前生命值。例：敌人从 30 HP 被打到 0 HP 后触发 died。
#### 信号说明
- **health_changed**：当 **HealthComponent** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **damaged**：当 **HealthComponent** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **healed**：当 **HealthComponent** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **died**：当 **HealthComponent** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**HealthComponent** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **get_max_hp()**：读取数据入口。实际例子：CombatResolver 通过 get_max_hp 获取最终攻击力，而不是直接读内部变量。
- **apply_damage()**：应用伤害结果。实际例子：扣除 final_amount、施加 on-hit 状态、发出 damaged/damage_applied，并在归零时触发死亡。
- **_apply_on_hit_statuses()**：把 DamageResult.status_applications 交给目标 StatusEffectController.apply_status。实际例子：火球命中且燃烧判定通过后，敌人挂上 burn。
- **heal()**：公开 API。实际例子：外部系统通过它请求 **HealthComponent** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **die()**：公开 API。实际例子：外部系统通过它请求 **HealthComponent** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **revive()**：公开 API。实际例子：外部系统通过它请求 **HealthComponent** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_on_stat_changed()**：内部辅助函数。实际例子：由 **HealthComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.37 HealthComponent 使用示例

#### 详细实际用例

- 真实场景：DamageResult 造成 13 点伤害，HealthComponent 把敌人 HP 从 10 扣到 0，发出 damaged 和 died。
- 怎么使用：CombatResolver 只算结果，HealthComponent 才真正修改 HP；UI、RoomController、FeedbackSystem 监听信号。
- 验证重点：致命伤只触发一次死亡；治疗不能超过 max_hp；死亡后是否还能治疗要有明确规则。
### 受到伤害

```gdscript
var damage := DamageResult.new()
damage.source = enemy
damage.target = player
damage.final_amount = 15.0

var health := player.get_node("Components/HealthComponent") as HealthComponent
health.apply_damage(damage)
```

### 治疗

```gdscript
health.heal(25.0, player)
```

### 监听死亡

```gdscript
func _ready() -> void:
    $Components/HealthComponent.died.connect(_on_died)

func _on_died(owner_entity: Node) -> void:
    print(owner_entity.name, " died")
```

---

---

---

## 10.2 ResourcePoolComponent

### 概念说明

- 是什么：实体的可消耗资源池，例如 mana、stamina、energy、rage。
- 负责什么：保存当前资源值，读取 StatsComponent 中的最大值，执行消耗、恢复和变化通知。
- 为什么需要：AbilityController 已经有 cost_type/cost_amount；如果没有统一资源池，技能消耗会被写死在具体玩家脚本里。

`res://addons/mkit/modules/health/resource_pool_component.gd`

```gdscript
class_name ResourcePoolComponent
extends Node

signal resource_changed(resource_id: String, current: float, max_value: float)
signal resource_spent(resource_id: String, amount: float)
signal resource_restored(resource_id: String, amount: float)

@export var starting_values: Dictionary = {} # resource_id -> current value

var current_values: Dictionary = {}
var stats: StatsComponent = null

func _ready() -> void:
    stats = owner.get_node_or_null("Components/StatsComponent") as StatsComponent
    current_values = starting_values.duplicate(true)
    for resource_id in current_values.keys():
        set_current(str(resource_id), float(current_values[resource_id]))

func get_current(resource_id: String) -> float:
    return float(current_values.get(resource_id, get_max_resource(resource_id)))

func get_max_resource(resource_id: String) -> float:
    if stats == null:
        return 0.0
    return stats.get_stat_value("max_%s" % resource_id, 0.0)

func has_resource(resource_id: String, amount: float) -> bool:
    if amount <= 0.0:
        return true
    return get_current(resource_id) >= amount

func spend(resource_id: String, amount: float) -> bool:
    if not has_resource(resource_id, amount):
        return false
    set_current(resource_id, get_current(resource_id) - amount)
    resource_spent.emit(resource_id, amount)
    return true

func restore(resource_id: String, amount: float) -> void:
    if amount <= 0.0:
        return
    set_current(resource_id, get_current(resource_id) + amount)
    resource_restored.emit(resource_id, amount)

func set_current(resource_id: String, value: float) -> void:
    var max_value := get_max_resource(resource_id)
    current_values[resource_id] = clamp(value, 0.0, max_value)
    resource_changed.emit(resource_id, current_values[resource_id], max_value)

func to_save_data() -> Dictionary:
    return current_values.duplicate(true)

func from_save_data(data: Dictionary) -> void:
    current_values = data.duplicate(true)
    for resource_id in current_values.keys():
        set_current(str(resource_id), float(current_values[resource_id]))
```

#### 字段说明
- **starting_values**：初始资源值。例：玩家开局 mana=50、stamina=100。
- **current_values**：当前资源表。例：释放火球后 mana 从 50 变成 35。
#### 信号说明
- **resource_changed**：资源变化后发出。实际例子：HUD 更新 mana/stamina 条。
- **resource_spent**：资源消耗后发出。实际例子：释放技能成功后播放消耗反馈。
- **resource_restored**：资源恢复后发出。实际例子：拾取能量球后显示恢复数字。
#### 函数使用场景
- **_ready()**：进入场景树后缓存 StatsComponent 并 clamp 初始值。
- **get_current()**：读取当前资源。实际例子：UI 显示当前 mana。
- **get_max_resource()**：读取最大资源。实际例子：max_mana 来自 StatsComponent。
- **has_resource()**：消耗前检查。实际例子：AbilityController 判断是否有足够 stamina。
- **spend()**：消耗资源。实际例子：Dash 技能消耗 25 stamina。
- **restore()**：恢复资源。实际例子：药水恢复 30 mana。
- **set_current()**：直接设置当前值。实际例子：读档时恢复 mana。
- **to_save_data()**：序列化。实际例子：保存玩家当前 mana/stamina。
- **from_save_data()**：反序列化。实际例子：读档后恢复资源池。

---

### 27.89 ResourcePoolComponent 使用示例

#### 详细实际用例

- 真实场景：火球 cost_type=mana、cost_amount=15。AbilityController 释放前调用 ResourcePoolComponent.has_resource("mana", 15)，成功后 spend。
- 怎么使用：最大值仍放 StatsComponent，例如 max_mana；当前值放 ResourcePoolComponent，避免把可变资源写进静态属性定义。
- 验证重点：资源不足时技能失败且不进冷却；max_mana 改变后当前 mana 会被 clamp 到新上限。

```gdscript
var resources := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent
if resources.spend("mana", 15.0):
    print("Cast fireball")
else:
    print("Not enough mana")
```

---

---

---

# 11. Combat 模块接口设计

---

## 11.1 DamageRequest

### 概念说明

- 是什么：一次伤害结算的输入单。
- 负责什么：携带攻击者、目标、基础伤害、伤害类型、元素类型、是否可暴击和标签。
- 为什么需要：Hitbox、Projectile、Trap、技能都可以产生伤害，但它们不应该自己算最终伤害；统一请求交给 CombatResolver。
`res://addons/mkit/modules/combat/damage_request.gd`

```gdscript
class_name DamageRequest
extends RefCounted

var source: Node = null
var target: Node = null
var base_amount: float = 0.0
var damage_type: String = "physical"
var element_type: String = "none"
var can_crit: bool = true
var can_evade: bool = true
var can_block: bool = true
var tags: Array[String] = []
var on_hit_statuses: Array[Dictionary] = [] # 每项: {status_id, chance, stacks, duration}
var payload: Dictionary = {}
```

#### 字段说明
- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **base_amount**：基础伤害/治疗数值。例：火球基础伤害 20，最终伤害还要经过攻击力、暴击和防御计算。
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **can_crit**：是否允许暴击。例：普通攻击可以暴击，持续毒伤通常不暴击。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **on_hit_statuses**：命中时尝试附加的状态列表。例：火球命中有 30% 概率挂 burn，可写 `[{"status_id":"status.burn","chance":0.3,"stacks":1,"duration":4.0}]`。CombatResolver 会用 RandomService 掷概率，命中的状态记录到 DamageResult.applied_status_effects，由 HealthComponent 统一施加。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。

---

### 27.38 DamageRequest 使用示例

#### 详细实际用例

- 真实场景：剑的 Hitbox 命中 Hurtbox 后创建 DamageRequest：source=玩家、target=goblin、base_amount=10、damage_type=physical。
- 怎么使用：任何伤害来源都先生成 request，再交给 CombatResolver。不要在 Hitbox 或 Projectile 中计算最终伤害。
- 验证重点：request 的 source/target/tag 正确，否则仇恨、掉落归属和 Analytics 会错。
```gdscript
var request := DamageRequest.new()
request.source = player
request.target = enemy
request.base_amount = 20.0
request.damage_type = "physical"
request.element_type = "none"
request.can_crit = true
request.tags = ["melee", "basic_attack"]
```

---

---

---

## 11.2 DamageResult

### 概念说明

- 是什么：一次伤害结算的结果单。
- 负责什么：记录最终伤害、是否暴击、是否被闪避/格挡、是否致命，以及可能附加的状态效果。
- 为什么需要：HealthComponent、伤害数字 UI、音效、死亡流程和 Analytics 都应该读取同一个结果，而不是各自猜测发生了什么。
`res://addons/mkit/modules/combat/damage_result.gd`

```gdscript
class_name DamageResult
extends RefCounted

var source: Node = null
var target: Node = null
var base_amount: float = 0.0
var final_amount: float = 0.0
var damage_type: String = "physical"
var element_type: String = "none"
var was_critical: bool = false
var was_evaded: bool = false
var was_blocked: bool = false
var was_lethal: bool = false
var applied_status_effects: Array[String] = [] # 命中并通过概率判定的 status_id 列表
var status_applications: Array[Dictionary] = [] # 待施加的完整条目: {status_id, stacks, duration}
var trace: Dictionary = {}

func to_debug_dict() -> Dictionary:
    return {
        "base_amount": base_amount,
        "final_amount": final_amount,
        "damage_type": damage_type,
        "element_type": element_type,
        "critical": was_critical,
        "evaded": was_evaded,
        "blocked": was_blocked,
        "lethal": was_lethal,
        "applied_status_effects": applied_status_effects,
        "trace": trace
    }
```

#### 字段说明
- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **base_amount**：基础伤害/治疗数值。例：火球基础伤害 20，最终伤害还要经过攻击力、暴击和防御计算。
- **final_amount**：结算后的最终数值。例：base 20 加攻击加成后被防御抵消，最终造成 27 点伤害。
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **was_critical**：本次是否暴击。例：UI 根据它显示更大的黄色伤害数字。
- **was_lethal**：本次是否致命。例：HealthComponent 根据它触发死亡流程和掉落。
- **applied_status_effects**：本次命中实际附加的 status_id 列表。例：火球命中且燃烧判定通过时为 `["status.burn"]`；UI、Analytics 和 DebugOverlay 据此显示"造成燃烧"。
- **status_applications**：与上一字段配套的完整施加条目（含 stacks/duration），供 HealthComponent 真正调用 StatusEffectController.apply_status。
#### 函数使用场景
- **to_debug_dict()**：公开 API。实际例子：外部系统通过它请求 **DamageResult** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.39 DamageResult 使用示例

#### 详细实际用例

- 真实场景：CombatResolver 算出 base 10 + attack 5 - defense 2 = final 13，并标记 was_critical=false、was_lethal=true。
- 怎么使用：HealthComponent 根据 DamageResult 扣 HP，FeedbackSystem 根据 was_critical 显示不同伤害数字。
- 验证重点：同一次攻击的 UI、事件、HP 变化都读取同一个 result。
```gdscript
var result := CombatResolver.get_default().resolve(request)
print("Final damage: ", result.final_amount)
print("Was critical: ", result.was_critical)
print("Trace: ", result.trace)
```

---

---

---

## 11.3 CombatResolver

### 概念说明

- 是什么：伤害结算规则引擎。
- 负责什么：读取攻击、防御、暴击、元素、格挡、闪避等信息并产出 DamageResult。
- 为什么需要：伤害公式经常会调整，集中在一个 resolver 中才容易测试和调平衡。

`res://addons/mkit/modules/combat/combat_resolver.gd`

```gdscript
class_name CombatResolver
extends RefCounted

static var _default: CombatResolver = null

static func get_default() -> CombatResolver:
    if _default == null:
        _default = CombatResolver.new()
    return _default

func resolve(request: DamageRequest) -> DamageResult:
    var result := DamageResult.new()
    result.source = request.source
    result.target = request.target
    result.base_amount = request.base_amount
    result.damage_type = request.damage_type
    result.element_type = request.element_type

    if request.source == null or request.target == null:
        result.final_amount = 0.0
        result.trace["failure"] = "missing source or target"
        return result

    var source_stats := _get_stats(request.source)
    var target_stats := _get_stats(request.target)

    var attack_power := _stat(source_stats, "attack_power", 0.0)
    var damage_multiplier := _stat(source_stats, "damage_multiplier", 1.0)
    var defense := _stat(target_stats, "defense", 0.0)
    var crit_chance := _stat(source_stats, "crit_chance", 0.0)
    var crit_damage := _stat(source_stats, "crit_damage", 1.5)

    var amount := request.base_amount
    result.trace["base"] = amount

    amount += attack_power
    result.trace["after_attack_power"] = amount

    amount *= damage_multiplier
    result.trace["after_damage_multiplier"] = amount

    if request.can_crit and _roll_chance(crit_chance):
        result.was_critical = true
        amount *= crit_damage
    result.trace["after_crit"] = amount

    amount = max(0.0, amount - defense)
    result.trace["after_defense"] = amount

    # 后续可扩展：元素抗性、护盾、格挡、闪避、伤害上下限。
    result.final_amount = max(0.0, amount)

    _roll_on_hit_statuses(request, result)
    return result

func _roll_on_hit_statuses(request: DamageRequest, result: DamageResult) -> void:
    # 命中被闪避/格挡时不附加 on-hit 状态。
    if result.was_evaded or result.was_blocked:
        return
    for entry in request.on_hit_statuses:
        var status_id := str(entry.get("status_id", ""))
        if status_id == "":
            continue
        var chance := float(entry.get("chance", 1.0))
        if not _roll_chance(chance):
            continue
        result.applied_status_effects.append(status_id)
        result.status_applications.append({
            "status_id": status_id,
            "stacks": int(entry.get("stacks", 1)),
            "duration": float(entry.get("duration", -1.0))
        })
    if not result.applied_status_effects.is_empty():
        result.trace["applied_status_effects"] = result.applied_status_effects

func _get_stats(entity: Node) -> StatsComponent:
    if entity == null:
        return null
    return entity.get_node_or_null("Components/StatsComponent") as StatsComponent

func _stat(stats: StatsComponent, stat_id: String, default_value: float) -> float:
    if stats == null:
        return default_value
    return stats.get_stat_value(stat_id, default_value)

func _roll_chance(chance: float) -> bool:
    var random := ServiceRegistry.get_service("random") as RandomService
    if random != null:
        return random.randf() < chance
    return randf() < chance
```

#### 函数使用场景
- **get_default()**：读取数据入口。实际例子：CombatResolver 通过 get_default 获取最终攻击力，而不是直接读内部变量。
- **resolve()**：公开 API。实际例子：外部系统通过它请求 **CombatResolver** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **_roll_on_hit_statuses()**：用 RandomService 对 request.on_hit_statuses 逐条掷概率，把命中的状态写入 result.applied_status_effects 和 result.status_applications；闪避/格挡时不附加。固定 seed 下结果可复现。
- **_get_stats()**：内部辅助函数。实际例子：由 **CombatResolver** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_stat()**：内部辅助函数。实际例子：由 **CombatResolver** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_roll_chance()**：内部辅助函数。实际例子：由 **CombatResolver** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.40 CombatResolver 使用示例

#### 详细实际用例

- 真实场景：玩家攻击 goblin，CombatResolver 读取玩家 attack_power、goblin defense、暴击率和元素抗性，产出 DamageResult。
- 怎么使用：所有伤害公式集中在 resolver；以后平衡防御公式或暴击公式时只改这里。
- 验证重点：给定固定 Random seed 和固定 stats，同一个 DamageRequest 应产生可预测结果。
```gdscript
func deal_direct_damage(source: Node, target: Node, amount: float) -> void:
    var request := DamageRequest.new()
    request.source = source
    request.target = target
    request.base_amount = amount

    var result := CombatResolver.get_default().resolve(request)
    var health := target.get_node("Components/HealthComponent") as HealthComponent
    health.apply_damage(result)
```

---

---

---

## 11.4 HitboxComponent

### 概念说明

- 是什么：实体或投射物“能打到别人”的攻击判定区域。
- 负责什么：在攻击生效帧检测进入范围的 Hurtbox，并把命中信息转成 DamageRequest 或 Effect 执行上下文。
- 为什么需要：攻击范围和伤害公式要分开；剑挥到哪里由 Hitbox 负责，打多少血由 CombatResolver 负责。
`res://addons/mkit/modules/combat/hitbox_component.gd`

```gdscript
class_name HitboxComponent
extends Area2D

@export var active: bool = false
@export var base_damage: float = 1.0
@export var damage_type: String = "physical"
@export var element_type: String = "none"
@export var hit_once_per_activation: bool = true
@export var target_factions: Array[String] = ["enemy"]
@export var hit_tags: Array[String] = []
@export var on_hit_statuses: Array[Dictionary] = [] # 每项: {status_id, chance, stacks, duration}

var source_entity: Node = null
var already_hit: Dictionary = {}

func _ready() -> void:
    source_entity = owner
    area_entered.connect(_on_area_entered)
    monitoring = active

func set_active(value: bool) -> void:
    active = value
    monitoring = value
    if value:
        already_hit.clear()

func _on_area_entered(area: Area2D) -> void:
    if not active:
        return
    var hurtbox := area as HurtboxComponent
    if hurtbox == null:
        return
    if not hurtbox.can_receive_damage:
        return
    var target := hurtbox.get_owner_entity()
    if target == null:
        return

    var target_id := _get_entity_id(target)
    if hit_once_per_activation and already_hit.has(target_id):
        return

    if not _is_valid_target(target):
        return

    already_hit[target_id] = true

    var request := DamageRequest.new()
    request.source = source_entity
    request.target = target
    request.base_amount = base_damage * hurtbox.damage_multiplier
    request.damage_type = damage_type
    request.element_type = element_type
    request.tags = hit_tags.duplicate()
    request.tags.append_array(hurtbox.damage_tags)
    request.on_hit_statuses = on_hit_statuses.duplicate()

    var result := CombatResolver.get_default().resolve(request)
    var health := target.get_node_or_null("Components/HealthComponent") as HealthComponent
    if health != null:
        health.apply_damage(result)

func _is_valid_target(target: Node) -> bool:
    var identity := target.get_node_or_null("EntityIdentity") as EntityIdentity
    if identity == null:
        return true
    return target_factions.has(identity.faction)

func _get_entity_id(entity: Node) -> String:
    var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
    if identity != null:
        return identity.entity_id
    return entity.name
```

#### 字段说明
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **hit_tags**：命中标签。例：melee、projectile、heavy_attack，可传给 CombatResolver 或状态触发逻辑。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**HitboxComponent** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **set_active()**：写入或配置入口。实际例子：测试场景通过 set_active 设置黑板值或初始化运行时状态。
- **_on_area_entered()**：内部辅助函数。实际例子：由 **HitboxComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_is_valid_target()**：内部辅助函数。实际例子：由 **HitboxComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_get_entity_id()**：内部辅助函数。实际例子：由 **HitboxComponent** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

### 27.41 HitboxComponent 使用示例

#### 详细实际用例

- 真实场景：玩家挥剑 active 帧时，剑前方矩形 Hitbox 打开；如果 goblin 的 Hurtbox 进入这个区域，就触发一次命中。
- 怎么使用：Hitbox 负责“有没有打到”和“打到谁”，不负责最终伤害。命中后创建 DamageRequest 或触发 EffectExecutor。
- 验证重点：Hitbox 只在攻击有效帧启用；同一挥剑是否允许多次命中同一目标要有规则。
### 攻击 active frame 打开 hitbox

```gdscript
func enable_sword_hitbox() -> void:
    var hitbox := $Components/HitboxComponent as HitboxComponent
    hitbox.base_damage = 12.0
    hitbox.target_factions = ["enemy"]
    hitbox.set_active(true)
```

### 攻击结束关闭 hitbox

```gdscript
func disable_sword_hitbox() -> void:
    $Components/HitboxComponent.set_active(false)
```

---

---

---

## 11.5 HurtboxComponent

### 概念说明

- 是什么：实体“可以被打中”的受击区域。
- 负责什么：表示角色身体、弱点、护盾范围等可被 Hitbox 命中的区域，并把命中事件转交给战斗系统。
- 为什么需要：一个敌人可以有身体和头部两个 Hurtbox，也可以短暂无敌；这些受击规则不应该写进伤害公式里。
```gdscript
class_name HurtboxComponent
extends Area2D

@export var owner_path: NodePath = NodePath("../..")
@export var can_receive_damage: bool = true
@export var damage_multiplier: float = 1.0
@export var damage_tags: Array[String] = []

func get_owner_entity() -> Node:
    return get_node_or_null(owner_path)
```

#### 字段说明
- **owner_path**：资源或节点路径。例：用 owner_path 指向场景或节点，方便在 Inspector 中配置。
- **can_receive_damage**：是否接收命中。例：Dash 无敌帧期间设为 false。
- **damage_multiplier**：受击倍率。例：Boss 头部弱点设为 1.5，护盾区域设为 0.5。
- **damage_tags**：受击区域标签。例：weak_point、shield、armor，可进入 DamageRequest.tags。
#### 函数使用场景
- **get_owner_entity()**：读取数据入口。实际例子：CombatResolver 通过 get_owner_entity 获取最终攻击力，而不是直接读内部变量。

---

---

### 27.42 HurtboxComponent 使用示例

#### 详细实际用例

- 真实场景：goblin 身上挂一个身体 Hurtbox，Boss 额外挂一个头部弱点 Hurtbox。玩家剑的 Hitbox 只要碰到这些区域，敌人才会被判定命中。
- 怎么使用：Hurtbox 表示“哪里能被打中”，可以临时关闭来实现无敌帧，也可以带 tags 表示 weak_point、shield、armor。
- 验证重点：Dash 无敌时 Hurtbox 不接收命中；打到 Boss 头部和身体可以产生不同 DamageRequest 标签。
### Enemy 场景结构

```text
Enemy.tscn
  CharacterBody2D
    EntityIdentity
    Components
      HealthComponent
      StatsComponent
      HurtboxComponent
```

### Inspector 配置

```text
HurtboxComponent.owner_path = "../.."
HurtboxComponent.can_receive_damage = true
HurtboxComponent.damage_tags = ["body"]
```

---

