# Ability and Status Effects

---

# 12. Ability 模块接口设计

---

## 12.1 AbilityDefinition

### 概念说明

- 是什么：一个技能的静态配置，例如基础火球、翻滚、旋风斩、治疗术。
- 负责什么：定义技能 ID、显示文本、冷却、消耗、施法时间、范围、条件、Action 和 Effect 列表。
- 为什么需要：技能应该是数据资源；新增一个冰锥术时应主要配置 Resource，而不是复制一份 Player 脚本。
`res://addons/mkit/modules/abilities/ability_definition.gd`

```gdscript
class_name AbilityDefinition
extends Resource

@export var ability_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var cooldown: float = 1.0
@export var charges: int = 1
@export var cost_type: String = "none" # mana, stamina, hp, currency, none
@export var cost_amount: float = 0.0
@export var cast_time: float = 0.0
@export var range: float = 0.0
@export var tags: Array[String] = []
@export var conditions: Array[Condition] = []
@export var effects: Array[GameEffect] = []
```

#### 字段说明
- **ability_id**：技能定义 ID。例：ability.fireball_basic 让 AbilityController 找到火球定义并读取冷却、消耗和效果。
- **cooldown**：基础冷却时间。例：火球 cooldown=3.0，释放后 3 秒不能再次释放。
- **charges**：可储存次数。例：翻滚技能有 2 层 charges，可以连续使用两次。
- **cost_type**：消耗类型。例：mana、stamina、rage，不同角色可以用不同资源。
- **cost_amount**：消耗数量。例：火球消耗 15 mana。
- **cast_time**：施法时间。例：大招 cast_time=1.2 秒，期间可以播放蓄力动画或被打断。
- **range**：作用范围。例：近战技能 range=48，火球 range=600。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **conditions**：释放或生效条件。例：HasEnoughMana、CooldownReady、TargetInRange。
- **effects**：玩法结果列表。例：DealDamageEffect 后接 ApplyStatusEffect(status.burn)。

---

### 27.43 AbilityDefinition 使用示例

#### 详细实际用例

- 真实场景：`ability.fireball_basic` 定义 cooldown=3、cost=15 mana、cast_time=0.4、effects=[DealDamage, ApplyBurn]。
- 怎么使用：把技能配置成 Resource，AbilityController 读取定义执行；不要为每个技能复制一份控制器脚本。
- 验证重点：换一个 AbilityDefinition 就能得到新技能行为，而不改玩家输入和状态机。
### 创建 Fireball Ability Resource

```gdscript
var fireball := AbilityDefinition.new()
fireball.ability_id = "ability.fireball_basic"
fireball.display_name = "Fireball"
fireball.description = "Launch a fireball that deals fire damage."
fireball.cooldown = 2.5
fireball.cost_type = "mana"
fireball.cost_amount = 10.0
fireball.cast_time = 0.2
fireball.range = 320.0
fireball.tags = ["spell", "fire", "projectile"]

var damage := DealDamageEffect.new()
damage.effect_id = "effect.fireball_damage"
damage.base_amount = 30.0
damage.damage_type = "magic"
damage.element_type = "fire"

fireball.effects = [damage]
```

---

---

---

## 12.2 AbilityInstance

### 概念说明

- 是什么：某个实体身上正在使用的技能运行时实例。
- 负责什么：记录技能拥有者、剩余冷却、当前 charges、技能等级、临时修改和是否启用。
- 为什么需要：玩家和敌人都可能拥有 ability.fireball_basic，但它们的冷却、等级和 charges 是各自独立的。
`res://addons/mkit/modules/abilities/ability_instance.gd`

```gdscript
class_name AbilityInstance
extends RefCounted

var definition_id: String = ""
var owner: Node = null
var cooldown_remaining: float = 0.0
var current_charges: int = 1
var runtime_level: int = 1
var enabled: bool = true
var temporary_modifiers: Dictionary = {}

func setup(definition: AbilityDefinition, owner_entity: Node) -> void:
    definition_id = definition.ability_id
    owner = owner_entity
    current_charges = definition.charges

func tick(delta: float) -> void:
    if cooldown_remaining > 0.0:
        cooldown_remaining = max(0.0, cooldown_remaining - delta)

func is_cooldown_ready() -> bool:
    return cooldown_remaining <= 0.0 and current_charges > 0

func start_cooldown(definition: AbilityDefinition, cooldown_reduction: float = 0.0) -> void:
    var final_cd := max(0.0, definition.cooldown * (1.0 - cooldown_reduction))
    cooldown_remaining = final_cd
    if definition.charges > 0:
        current_charges = max(0, current_charges - 1)

func restore_charge(definition: AbilityDefinition) -> void:
    current_charges = min(definition.charges, current_charges + 1)
```

#### 字段说明
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **runtime_level**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **enabled**：状态标记。例：用它判断当前对象是否已经处理过，避免重复触发。
- **temporary_modifiers**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
#### 函数使用场景
- **setup()**：公开 API。实际例子：外部系统通过它请求 **AbilityInstance** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **tick()**：公开 API。实际例子：外部系统通过它请求 **AbilityInstance** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **is_cooldown_ready()**：状态查询。实际例子：AI 调用 is_cooldown_ready 判断目标是不是敌对阵营或 Action 是否结束。
- **start_cooldown()**：启动流程。实际例子：RunDirector.start_run 创建 RunState 并进入第一个房间。
- **restore_charge()**：公开 API。实际例子：外部系统通过它请求 **AbilityInstance** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.44 AbilityInstance 使用示例

#### 详细实际用例

- 真实场景：玩家和法师敌人都拥有 fireball 定义，但玩家火球等级 2、冷却剩 1 秒，敌人火球等级 1、冷却已完成。
- 怎么使用：Definition 放静态数据，Instance 放 owner、cooldown、charges、level 等运行时状态。
- 验证重点：多个拥有者的同一技能互不影响；读档后冷却和等级恢复正确。
```gdscript
var instance := AbilityInstance.new()
instance.setup(fireball_definition, player)

if instance.is_cooldown_ready():
    instance.start_cooldown(fireball_definition, 0.10)
```

---

---

---

## 12.3 AbilityController

### 概念说明

- 是什么：实体释放技能的控制器。
- 负责什么：管理技能实例、检查条件/消耗/冷却、启动施法、执行效果并发事件。
- 为什么需要：玩家和敌人都可以放技能，应该共享同一条释放链路。

`res://addons/mkit/modules/abilities/ability_controller.gd`

```gdscript
class_name AbilityController
extends Node

signal ability_registered(ability_id: String)
signal ability_cast_started(ability_id: String)
signal ability_cast_finished(ability_id: String)
signal ability_failed(ability_id: String, reason: String)
signal cooldown_started(ability_id: String, duration: float)

@export var starting_ability_ids: Array[String] = []

var abilities: Dictionary = {} # ability_id -> AbilityInstance
var content: ContentRegistry = null

func _ready() -> void:
    content = ServiceRegistry.get_service("content") as ContentRegistry
    for id in starting_ability_ids:
        register_ability(id)

func _process(delta: float) -> void:
    for instance: AbilityInstance in abilities.values():
        instance.tick(delta)

func register_ability(ability_id: String) -> bool:
    if abilities.has(ability_id):
        return true
    var definition := get_definition(ability_id)
    if definition == null:
        push_error("Ability definition not found: %s" % ability_id)
        return false
    var instance := AbilityInstance.new()
    instance.setup(definition, owner)
    abilities[ability_id] = instance
    ability_registered.emit(ability_id)
    return true

func has_ability(ability_id: String) -> bool:
    return abilities.has(ability_id)

func can_cast(ability_id: String, context: GameplayContext) -> bool:
    var failure := get_cast_failure_reason(ability_id, context)
    return failure == ""

func get_cast_failure_reason(ability_id: String, context: GameplayContext) -> String:
    if not abilities.has(ability_id):
        return "Ability is not registered: %s" % ability_id

    var instance := abilities[ability_id] as AbilityInstance
    if not instance.enabled:
        return "Ability is disabled: %s" % ability_id

    var definition := get_definition(ability_id)
    if definition == null:
        return "Missing definition: %s" % ability_id

    if not instance.is_cooldown_ready():
        return "Cooldown not ready: %s" % ability_id

    if not _has_enough_cost(definition):
        return "Not enough resource: %s" % definition.cost_type

    context.ability_id = ability_id
    if not ConditionEvaluator.evaluate_all(definition.conditions, context):
        return ", ".join(ConditionEvaluator.collect_failures(definition.conditions, context))

    return ""

func cast(ability_id: String, context: GameplayContext) -> bool:
    var failure := get_cast_failure_reason(ability_id, context)
    if failure != "":
        ability_failed.emit(ability_id, failure)
        return false

    var definition := get_definition(ability_id)
    var instance := abilities[ability_id] as AbilityInstance

    _pay_cost(definition)
    ability_cast_started.emit(ability_id)

    if definition.cast_time > 0.0:
        _start_cast_action(definition, context)
    else:
        _execute_ability_effects(definition, context)
        _start_cooldown(instance, definition)
        ability_cast_finished.emit(ability_id)

    return true

func is_cooldown_ready(ability_id: String) -> bool:
    if not abilities.has(ability_id):
        return false
    return (abilities[ability_id] as AbilityInstance).is_cooldown_ready()

func get_cooldown_remaining(ability_id: String) -> float:
    if not abilities.has(ability_id):
        return 0.0
    return (abilities[ability_id] as AbilityInstance).cooldown_remaining

func get_definition(ability_id: String) -> AbilityDefinition:
    if content == null:
        content = ServiceRegistry.get_service("content") as ContentRegistry
    if content == null:
        return null
    return content.get_resource(ability_id) as AbilityDefinition

func _execute_ability_effects(definition: AbilityDefinition, context: GameplayContext) -> void:
    var executor := ServiceRegistry.get_service("effects") as EffectExecutor
    if executor == null:
        executor = EffectExecutor.new()
    executor.execute_many(definition.effects, context)

func _start_cooldown(instance: AbilityInstance, definition: AbilityDefinition) -> void:
    var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
    var cdr := 0.0
    if stats != null:
        cdr = stats.get_stat_value("cooldown_reduction", 0.0)
    instance.start_cooldown(definition, cdr)
    cooldown_started.emit(definition.ability_id, instance.cooldown_remaining)

func _start_cast_action(definition: AbilityDefinition, context: GameplayContext) -> void:
    var action := CastAction.new()
    action.duration = definition.cast_time
    action.completed.connect(func(_a):
        _execute_ability_effects(definition, context)
        _start_cooldown(abilities[definition.ability_id] as AbilityInstance, definition)
        ability_cast_finished.emit(definition.ability_id)
    )
    action.cancelled.connect(func(_a, reason):
        ability_failed.emit(definition.ability_id, "cast_cancelled:%s" % reason)
    )
    var action_context := ActionContext.new()
    action_context.source = context.source
    action_context.target = context.target
    action_context.ability_id = definition.ability_id
    action_context.payload = context.payload.duplicate(true)
    var runner := ServiceRegistry.get_service("actions") as ActionRunner
    runner.start_action(action, action_context)

func _has_enough_cost(definition: AbilityDefinition) -> bool:
    if definition.cost_type == "none" or definition.cost_amount <= 0:
        return true
    var resources := owner.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
    if resources == null:
        return false
    return resources.has_resource(definition.cost_type, definition.cost_amount)

func _pay_cost(definition: AbilityDefinition) -> void:
    if definition.cost_type == "none" or definition.cost_amount <= 0:
        return
    var resources := owner.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
    if resources != null:
        resources.spend(definition.cost_type, definition.cost_amount)
```

#### 信号说明
- **ability_registered**：当 **AbilityController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **ability_cast_started**：当 **AbilityController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **ability_cast_finished**：当 **AbilityController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **ability_failed**：当 **AbilityController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **cooldown_started**：当 **AbilityController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**AbilityController** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **_process()**：内部辅助函数。实际例子：由 **AbilityController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **register_ability()**：注册入口。实际例子：GameBootstrap 启动时把 EventRouter 注册为 events 服务。
- **has_ability()**：存在性查询。实际例子：奖励生成前检查玩家是否已经拥有某个标签、物品或服务。
- **can_cast()**：合法性检查。实际例子：释放技能前先调用 can_cast，失败时 UI 显示冷却中或目标太远。
- **get_cast_failure_reason()**：读取数据入口。实际例子：CombatResolver 通过 get_cast_failure_reason 获取最终攻击力，而不是直接读内部变量。
- **cast()**：公开 API。实际例子：外部系统通过它请求 **AbilityController** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。
- **is_cooldown_ready()**：状态查询。实际例子：AI 调用 is_cooldown_ready 判断目标是不是敌对阵营或 Action 是否结束。
- **get_cooldown_remaining()**：读取数据入口。实际例子：CombatResolver 通过 get_cooldown_remaining 获取最终攻击力，而不是直接读内部变量。
- **get_definition()**：读取数据入口。实际例子：CombatResolver 通过 get_definition 获取最终攻击力，而不是直接读内部变量。
- **_execute_ability_effects()**：内部辅助函数。实际例子：由 **AbilityController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_start_cooldown()**：内部辅助函数。实际例子：由 **AbilityController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_start_cast_action()**：内部辅助函数。实际例子：由 **AbilityController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_has_enough_cost()**：内部辅助函数。实际例子：释放 fireball 前检查 ResourcePoolComponent 是否有足够 mana。
- **_pay_cost()**：内部辅助函数。实际例子：技能确认释放后从 ResourcePoolComponent 扣除 mana/stamina。

---

---

### 27.45 AbilityController 使用示例

#### 详细实际用例

- 真实场景：玩家按 1 键释放火球，AbilityController 检查冷却、mana、距离，通过后启动 CastAction，施法完成执行火球效果。
- 怎么使用：状态机只决定当前能不能进入 CastAbilityState，具体技能验证和执行交给 AbilityController。
- 验证重点：冷却中、mana 不足、目标太远、被眩晕打断时都有明确失败原因。
### 注册技能

```gdscript
var controller := player.get_node("Controllers/AbilityController") as AbilityController
controller.register_ability("ability.fireball_basic")
```

### 释放技能

```gdscript
var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy
ctx.ability_id = "ability.fireball_basic"
ctx.direction = (enemy.global_position - player.global_position).normalized()

if controller.can_cast("ability.fireball_basic", ctx):
    controller.cast("ability.fireball_basic", ctx)
else:
    print(controller.get_cast_failure_reason("ability.fireball_basic", ctx))
```

### HUD 监听冷却

```gdscript
func _ready() -> void:
    controller.cooldown_started.connect(_on_cooldown_started)

func _on_cooldown_started(ability_id: String, duration: float) -> void:
    $HUD.start_cooldown_icon(ability_id, duration)
```

---

---

---

# 13. Status Effect 模块接口设计

---

## 13.1 StatusEffectDefinition

### 概念说明

- 是什么：状态效果的静态配置，例如燃烧、中毒、减速、眩晕、护盾、狂暴。
- 负责什么：定义持续时间、tick 间隔、叠加规则、周期效果、属性修改和移除规则。
- 为什么需要：状态效果会来自技能、装备、陷阱和房间规则；统一定义可以让它们共享叠加和过期逻辑。
`res://addons/mkit/modules/status_effects/status_effect_definition.gd`

```gdscript
class_name StatusEffectDefinition
extends Resource

enum StackRule {
    REFRESH_DURATION,
    ADD_STACK,
    REPLACE,
    IGNORE,
    EXTEND_DURATION,
    INDEPENDENT_STACKS
}

@export var status_id: String = ""
@export var display_name: String = ""
@export var duration: float = 5.0
@export var tick_interval: float = 1.0
@export var max_stacks: int = 1
@export var stack_rule: StackRule = StackRule.REFRESH_DURATION
@export var tags: Array[String] = []
@export var effects_on_apply: Array[GameEffect] = []
@export var effects_on_tick: Array[GameEffect] = []
@export var effects_on_remove: Array[GameEffect] = []
@export var stat_modifiers: Array[StatModifierDefinition] = []
```

#### 字段说明
- **status_id**：状态定义 ID。例：status.burn 用于创建燃烧状态实例。
- **duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **tick_interval**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **effects_on_apply**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **effects_on_tick**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **effects_on_remove**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **stat_modifiers**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

---

### 27.46 StatusEffectDefinition 使用示例

#### 详细实际用例

- 真实场景：`status.burn` 定义持续 4 秒，每 1 秒 tick 一次，tick 时执行 DealDamageEffect(fire, 5)。
- 怎么使用：把持续时间、叠加规则、周期效果和属性 modifier 写进定义。
- 验证重点：同一个 Burn 可以被火球、火焰陷阱和燃烧地板复用。
### 创建 Burn 状态

```gdscript
var burn := StatusEffectDefinition.new()
burn.status_id = "status.burn"
burn.display_name = "Burn"
burn.duration = 4.0
burn.tick_interval = 1.0
burn.max_stacks = 3
burn.stack_rule = StatusEffectDefinition.StackRule.ADD_STACK
burn.tags = ["debuff", "fire", "damage_over_time"]

var tick_damage := DealDamageEffect.new()
tick_damage.effect_id = "effect.burn_tick"
tick_damage.base_amount = 5.0
tick_damage.damage_type = "magic"
tick_damage.element_type = "fire"

burn.effects_on_tick = [tick_damage]
```

---

---

---

## 13.2 StatusEffectInstance

### 概念说明

- 是什么：已经挂在某个实体身上的状态运行时实例。
- 负责什么：记录来源、目标、剩余时间、当前层数、tick 计时器和运行时元数据。
- 为什么需要：两个敌人都被燃烧时，它们共享 status.burn 定义，但剩余时间和层数必须各自独立。
```gdscript
class_name StatusEffectInstance
extends RefCounted

var instance_id: String = ""
var definition_id: String = ""
var source: Node = null
var target: Node = null
var remaining_duration: float = 0.0
var tick_timer: float = 0.0
var stacks: int = 1
var applied_modifier_ids: Array[String] = []

func setup(definition: StatusEffectDefinition, source_entity: Node, target_entity: Node, initial_stacks: int, duration_override: float = -1.0) -> void:
    instance_id = "%s_%d" % [definition.status_id, Time.get_ticks_usec()]
    definition_id = definition.status_id
    source = source_entity
    target = target_entity
    stacks = initial_stacks
    remaining_duration = duration_override if duration_override > 0 else definition.duration
    tick_timer = definition.tick_interval
```

#### 字段说明
- **instance_id**：运行时物品/对象实例 ID。例：两把 Iron Sword 都来自 item.sword_iron，但一把有暴击词缀、一把有耐久损耗，所以必须有不同 instance_id。
- **definition_id**：静态定义 ID。例：goblin_001 的 definition_id 是 enemy.goblin_basic；存档或刷怪系统可以通过这个 ID 重新找到敌人定义，而不是保存具体节点。
- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **remaining_duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **tick_timer**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
#### 函数使用场景
- **setup()**：公开 API。实际例子：外部系统通过它请求 **StatusEffectInstance** 执行一个明确操作，并通过返回值、信号或状态变化确认结果。

---

### 27.47 StatusEffectInstance 使用示例

#### 详细实际用例

- 真实场景：goblin_001 的 burn 剩 3 秒、2 层；goblin_002 的 burn 剩 1 秒、1 层。它们共享定义但运行时状态不同。
- 怎么使用：每次应用状态时创建或刷新 instance，记录 source、target、remaining_time、stack_count。
- 验证重点：状态 tick 和过期只影响所属目标，不会污染其他敌人。
```gdscript
var instance := StatusEffectInstance.new()
instance.setup(burn_definition, player, enemy, 1)
print(instance.remaining_duration)
```

---

---

---

## 13.3 StatusEffectController

### 概念说明

- 是什么：实体身上状态效果的管理器。
- 负责什么：应用、刷新、叠加、tick、过期和移除状态。
- 为什么需要：持续伤害、Buff、Debuff 如果散落在各个技能脚本里，会很快失控。

```gdscript
class_name StatusEffectController
extends Node

signal status_applied(status_id: String, stacks: int)
signal status_removed(status_id: String)
signal status_ticked(status_id: String)

var active_statuses: Dictionary = {} # status_id -> StatusEffectInstance
var content: ContentRegistry = null

func _ready() -> void:
    content = ServiceRegistry.get_service("content") as ContentRegistry

func _process(delta: float) -> void:
    for status_id in active_statuses.keys().duplicate():
        var instance := active_statuses[status_id] as StatusEffectInstance
        var definition := get_definition(status_id)
        if definition == null:
            continue

        instance.remaining_duration -= delta
        instance.tick_timer -= delta

        if definition.tick_interval > 0 and instance.tick_timer <= 0:
            _tick_status(instance, definition)
            instance.tick_timer = definition.tick_interval

        if instance.remaining_duration <= 0:
            remove_status(status_id)

func apply_status(status_id: String, source: Node, stacks: int = 1, duration_override: float = -1.0) -> bool:
    var definition := get_definition(status_id)
    if definition == null:
        return false

    if active_statuses.has(status_id):
        var existing := active_statuses[status_id] as StatusEffectInstance
        _apply_stack_rule(existing, definition, stacks, duration_override)
        status_applied.emit(status_id, existing.stacks)
        return true

    var instance := StatusEffectInstance.new()
    instance.setup(definition, source, owner, stacks, duration_override)
    active_statuses[status_id] = instance

    _apply_stat_modifiers(instance, definition)
    _execute_effects(definition.effects_on_apply, instance)
    status_applied.emit(status_id, instance.stacks)
    return true

func remove_status(status_id: String) -> void:
    if not active_statuses.has(status_id):
        return
    var instance := active_statuses[status_id] as StatusEffectInstance
    var definition := get_definition(status_id)
    if definition != null:
        _execute_effects(definition.effects_on_remove, instance)
        _remove_stat_modifiers(instance)
    active_statuses.erase(status_id)
    status_removed.emit(status_id)

func has_status(status_id: String) -> bool:
    return active_statuses.has(status_id)

func get_definition(status_id: String) -> StatusEffectDefinition:
    if content == null:
        content = ServiceRegistry.get_service("content") as ContentRegistry
    return content.get_resource(status_id) as StatusEffectDefinition

func _tick_status(instance: StatusEffectInstance, definition: StatusEffectDefinition) -> void:
    _execute_effects(definition.effects_on_tick, instance)
    status_ticked.emit(definition.status_id)

func _execute_effects(effects: Array[GameEffect], instance: StatusEffectInstance) -> void:
    var context := GameplayContext.new()
    context.source = instance.source
    context.target = instance.target
    context.status_id = instance.definition_id
    context.payload["stacks"] = instance.stacks

    var executor := ServiceRegistry.get_service("effects") as EffectExecutor
    if executor != null:
        executor.execute_many(effects, context)

func _apply_stack_rule(instance: StatusEffectInstance, definition: StatusEffectDefinition, stacks: int, duration_override: float) -> void:
    var duration := duration_override if duration_override > 0 else definition.duration
    match definition.stack_rule:
        StatusEffectDefinition.StackRule.REFRESH_DURATION:
            instance.remaining_duration = duration
        StatusEffectDefinition.StackRule.ADD_STACK:
            instance.stacks = min(definition.max_stacks, instance.stacks + stacks)
            instance.remaining_duration = duration
        StatusEffectDefinition.StackRule.REPLACE:
            instance.stacks = stacks
            instance.remaining_duration = duration
        StatusEffectDefinition.StackRule.IGNORE:
            pass
        StatusEffectDefinition.StackRule.EXTEND_DURATION:
            instance.remaining_duration += duration
        _:
            pass

func _apply_stat_modifiers(instance: StatusEffectInstance, definition: StatusEffectDefinition) -> void:
    var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats == null:
        return
    for mod_def in definition.stat_modifiers:
        var modifier := StatModifier.from_definition(mod_def, instance.instance_id, instance.remaining_duration)
        stats.add_modifier(modifier)
        instance.applied_modifier_ids.append(modifier.modifier_id)

func _remove_stat_modifiers(instance: StatusEffectInstance) -> void:
    var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
    if stats != null:
        stats.remove_modifiers_from_source(instance.instance_id)
```

#### 信号说明
- **status_applied**：当 **StatusEffectController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **status_removed**：当 **StatusEffectController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
- **status_ticked**：当 **StatusEffectController** 发生对应玩法事实时发出。实际例子：UI 或 FeedbackSystem 连接这个信号后刷新界面、播放音效或记录 Debug trace。
#### 函数使用场景
- **_ready()**：Godot ready 生命周期回调。实际例子：**StatusEffectController** 在进入场景树后缓存子节点、生成默认 ID、连接需要的信号或执行自动注册；具体行为以代码为准，不等于所有组件都注册服务。
- **_process()**：内部辅助函数。实际例子：由 **StatusEffectController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **apply_status()**：应用玩法结果。实际例子：RewardSystem 应用 +20% attack 的奖励 Effect。
- **remove_status()**：移除操作。实际例子：使用药水后 remove_item 减少堆叠数量。
- **has_status()**：存在性查询。实际例子：奖励生成前检查玩家是否已经拥有某个标签、物品或服务。
- **get_definition()**：读取数据入口。实际例子：CombatResolver 通过 get_definition 获取最终攻击力，而不是直接读内部变量。
- **_tick_status()**：内部辅助函数。实际例子：由 **StatusEffectController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_execute_effects()**：内部辅助函数。实际例子：由 **StatusEffectController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_apply_stack_rule()**：内部辅助函数。实际例子：由 **StatusEffectController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_apply_stat_modifiers()**：内部辅助函数。实际例子：由 **StatusEffectController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。
- **_remove_stat_modifiers()**：内部辅助函数。实际例子：由 **StatusEffectController** 的公开流程调用，用来完成 $fn 对应的子步骤；外部系统通常不应该直接调用它。

---

---

### 27.48 StatusEffectController 使用示例

#### 详细实际用例

- 真实场景：敌人被火球命中后，StatusEffectController 添加 Burn；每秒 tick 时造成火伤；时间结束后自动移除。
- 怎么使用：所有状态都通过 controller 管理，技能和陷阱只请求 apply，不自己开 Timer。
- 验证重点：叠层、刷新、免疫、驱散、死亡清理都在 controller 中有一致行为。
```gdscript
var status_controller := enemy.get_node("Controllers/StatusEffectController") as StatusEffectController
status_controller.apply_status("status.burn", player, 1)
```

### 判断是否已有状态

```gdscript
if status_controller.has_status("status.burn"):
    print("Enemy is burning")
```

### 移除状态

```gdscript
status_controller.remove_status("status.burn")
```

---

