# AbilityDefinition

## 概念说明

AbilityDefinition 是一个技能的静态配置，例如基础火球、翻滚、旋风斩、治疗术。它定义技能 ID、显示文本、冷却、消耗、施法时间、范围、条件、Action 和 Effect 列表。技能应该是数据资源；新增一个冰锥术时应主要配置 Resource，而不是复制一份 Player 脚本。

## 设计目的

把技能的全部静态配置集中到一个 Resource 文件，使 AbilityController 可以通过稳定 ID 查找并执行任意技能，而不需要为每个技能写专用逻辑；所有技能共享同一套冷却、消耗、条件和效果执行管线。

## 文件

`res://addons/mkit/modules/abilities/ability_definition.gd`

## 接口

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

## 函数使用场景

AbilityDefinition 是纯数据 Resource，无公开方法。字段由 Inspector 配置后注册到 ContentRegistry，由 AbilityController 读取执行。

- **`cooldown`**：AbilityController 在技能释放成功后调用 AbilityInstance.start_cooldown()，使用此值（经 cooldown_reduction modifier 修正后）设置冷却计时。
- **`cost_type` / `cost_amount`**：AbilityController 在释放前检查 ResourcePoolComponent 是否有足够资源，成功释放后调用 spend()。
- **`cast_time`**：大于 0 时 AbilityController 创建 CastAction，施法完成后才执行 effects；等于 0 则立即执行。
- **`conditions`**：AbilityController 通过 ConditionEvaluator 逐一评估，任意失败则拒绝释放并发出 ability_failed 信号。
- **`effects`**：技能释放成功（即时）或施法完成后，由 EffectExecutor 顺序执行。

## 使用示例

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
