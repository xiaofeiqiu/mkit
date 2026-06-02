# StatsComponent

## 概念说明

StatsComponent 是实体属性的计算组件。它保存基础属性、运行时 modifier，并计算最终属性值。移动、战斗、技能、UI 和 AI 都要读最终属性，必须有一个权威计算入口。

## 设计目的

集中管理实体的属性系统，支持基础值 + 多层 modifier 的叠加计算，提供惰性求值缓存和脏标记机制，保证任何属性读取都能获取到最新且正确的最终值，同时通过 `stat_changed` 信号通知 UI 和其他关注方。

## 文件

`res://addons/mkit/modules/stats/stats_component.gd`

## 字段说明

- **base_stats**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **modifiers_by_stat**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **cached_values**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **dirty_stats**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name StatsComponent
extends Node
signal stat_changed(stat_id: String, old_value: float, new_value: float)
@export var base_stats: Dictionary = {
var modifiers_by_stat: Dictionary = {}
var cached_values: Dictionary = {}
var dirty_stats: Dictionary = {}
func get_stat_value(stat_id: String, default_value: float = 0.0) -> float
func set_base_stat(stat_id: String, value: float) -> void
func add_modifier(modifier: StatModifier) -> void
func remove_modifier(modifier_id: String, source_id: String = "") -> void
func remove_modifiers_from_source(source_id: String) -> void
func tick_modifiers(delta: float) -> void
func mark_dirty(stat_id: String) -> void
func mark_all_dirty() -> void
```

## 函数使用场景

- **`get_stat_value(stat_id, default_value)`**：读取属性最终值的唯一入口。CombatResolver 读取攻击力，MoveState 读取移动速度，AbilityController 读取冷却缩减。内部使用脏标记缓存，只在属性被修改后重新计算。
- **`set_base_stat(stat_id, value)`**：修改基础属性值，通常在 EntitySpawner 初始化时调用，将 EntityDefinition.base_stats 写入组件。修改后触发 `stat_changed`。
- **`add_modifier(modifier)`**：添加一个运行时 StatModifier。遵循 modifier 的 stacking_rule 处理叠加或替换逻辑，并将对应 stat 标记为脏。装备武器、应用 Buff、激活奖励时调用。
- **`remove_modifier(modifier_id, source_id)`**：按 modifier_id（可选 source_id）移除 modifier，适用于精确移除某个具体修改。
- **`remove_modifiers_from_source(source_id)`**：移除所有来源为 source_id 的 modifier，适用于装备卸下（按 instance_id）或状态效果过期（按 instance_id）。
- **`tick_modifiers(delta)`**：每帧推进有时限 modifier 的剩余时间，过期的 modifier 自动移除并触发 stat_changed。通常在实体的 `_process` 或状态的 `update` 中调用。
- **`mark_dirty(stat_id)` / `mark_all_dirty()`**：标记属性需要重新计算，在外部直接修改 base_stats 后手动调用。

## 使用示例

### 读取属性

```gdscript
var stats := player.get_node("Components/StatsComponent") as StatsComponent
var attack := stats.get_stat_value("attack_power", 10.0)
var move_speed := stats.get_stat_value("move_speed", 160.0)
```

### 添加临时 buff

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
