# StatusEffectDefinition

## 概念说明

StatusEffectDefinition 是状态效果的静态配置，例如燃烧、中毒、减速、眩晕、护盾、狂暴。它定义持续时间、tick 间隔、叠加规则、周期效果、属性修改和移除规则。状态效果会来自技能、装备、陷阱和房间规则；统一定义可以让它们共享叠加和过期逻辑。

## 设计目的

把状态效果的静态属性集中到一个 Resource 文件，使燃烧、减速、眩晕等所有状态都通过同一套叠加规则、tick 逻辑和属性 modifier 管线执行，避免在各个技能脚本中散落独立的 Timer 和状态管理代码。

## 文件

`res://addons/mkit/modules/status_effects/status_effect_definition.gd`

## 字段说明

- **status_id**：状态定义 ID。例：status.burn 用于创建燃烧状态实例。
- **display_name**：代码字段。显示名称。
- **duration**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **tick_interval**：时间相关字段。例：控制持续时间、tick 间隔或动作阶段，便于暂停、调试和调参。
- **max_stacks**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **stack_rule**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **effects_on_apply**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **effects_on_tick**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **effects_on_remove**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。
- **stat_modifiers**：集合字段。例：保存多个配置或运行时对象，让系统可以逐个处理。

## 接口

```gdscript
class_name StatusEffectDefinition
extends Resource
enum StackRule { REFRESH_DURATION, ADD_STACK, REPLACE, IGNORE, EXTEND_DURATION, INDEPENDENT_STACKS }
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

## 函数使用场景

StatusEffectDefinition 是纯数据 Resource，无公开方法。字段由 Inspector 配置后注册到 ContentRegistry，由 StatusEffectController 读取执行。

- **`stack_rule`**：决定同一状态重复施加时的行为——`REFRESH_DURATION` 刷新持续时间，`ADD_STACK` 叠加层数（不超过 max_stacks），`REPLACE` 完全替换，`IGNORE` 忽略重复施加，`EXTEND_DURATION` 叠加时长。
- **`effects_on_apply`**：状态第一次施加时由 StatusEffectController 通过 EffectExecutor 执行，例如立即造成一次伤害或播放 VFX。
- **`effects_on_tick`**：每经过 `tick_interval` 秒执行一次，例如燃烧每秒造成火焰伤害。
- **`effects_on_remove`**：状态过期或被驱散时执行，例如冰冻结束后可以给一个短暂减速。
- **`stat_modifiers`**：状态活跃期间通过 StatsComponent.add_modifier 施加的属性修改（如减速 -30% move_speed），状态移除时一并撤销。

## 使用示例

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
