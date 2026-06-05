# AbilityController

## 概念说明

AbilityController 是实体释放技能的控制器。它管理技能实例、检查条件/消耗/冷却、启动施法、执行效果并发出事件。即时技能直接执行效果，读条技能通过 ActionRunner 推进 CastAction。玩家和敌人都可以放技能，应该共享同一条释放链路。

## 设计目的

成为技能释放的单一协调者，把"能否施放"的所有检查（冷却、资源、条件）和"如何施放"的流程（即时 vs 施法读条、效果执行、冷却启动）集中管理。状态机只需决定进入 CastAbilityState，AbilityController 负责创建 CastAction，ActionRunner 负责统一推进耗时 Action。

## 文件

`res://addons/mkit/modules/abilities/ability_controller.gd`

## 字段说明

- **starting_ability_ids**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **abilities**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **active_cast_actions**：代码字段。记录当前由 AbilityController 发起但尚未完成或取消的 CastAction，Action 本身由 ActionRunner 推进。
- **content**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name AbilityController
extends SaveableComponent
signal ability_registered(ability_id: String)
signal ability_cast_started(ability_id: String)
signal ability_cast_finished(ability_id: String)
signal ability_failed(ability_id: String, reason: String)
signal cooldown_started(ability_id: String, duration: float)
@export var starting_ability_ids: Array[String] = []
var abilities: Dictionary = {}
var active_cast_actions: Array[GameAction] = []
var content: ContentRegistry = null
func register_ability(ability_id: String) -> bool
func has_ability(ability_id: String) -> bool
func can_cast(ability_id: String, context: GameplayContext) -> bool
func get_cast_failure_reason(ability_id: String, context: GameplayContext) -> String
func cast(ability_id: String, context: GameplayContext) -> bool
func is_cooldown_ready(ability_id: String) -> bool
func get_cooldown_remaining(ability_id: String) -> float
func get_definition(ability_id: String) -> AbilityDefinition
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`register_ability(ability_id)`**：从 ContentRegistry 查找 AbilityDefinition，创建 AbilityInstance 并存入 `abilities` 字典。`starting_ability_ids` 在 `_ready()` 时自动注册，EntitySpawner 也可在运行时调用。
- **`has_ability(ability_id)`**：检查是否已注册该技能，UI 和奖励系统据此决定是否显示或赠送技能。
- **`can_cast(ability_id, context)`**：一键检查所有释放前提（已注册、已启用、冷却完成、资源足够、所有 Condition 通过）。UI 可调用此方法决定是否高亮技能按钮。
- **`get_cast_failure_reason(ability_id, context)`**：返回第一个失败原因的字符串，供 UI 显示冷却提示、资源不足等信息，或 AI 决策跳过该技能。
- **`cast(ability_id, context)`**：主要执行入口。通过全部检查后：扣除资源、发出 `ability_cast_started`，若 `cast_time > 0` 创建 CastAction 并交给 `ServiceRegistry` 中的 `actions` / `ActionRunner` 推进，否则立即执行效果并启动冷却。
- **`is_cooldown_ready(ability_id)`**：快速查询冷却状态，供 CooldownReadyCondition 调用。
- **`get_cooldown_remaining(ability_id)`**：返回剩余冷却秒数，供 HUD 冷却条显示。
- **`get_definition(ability_id)`**：从 ContentRegistry 读取 AbilityDefinition，内部各子方法调用，外部也可读取技能描述信息。
- **`to_save_data()` / `from_save_data(data)`**：作为 SaveableComponent 序列化 `{ learned, cooldowns, charges, recharge_durations }`。`learned` 保存已注册 ability id，`cooldowns` 保存仍有剩余时间的 cooldown，`charges` 保存当前可用充能数，`recharge_durations` 保存多充能技能继续恢复所需的完整 recharge 时长。

## 使用示例

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
