# DealDamageEffect

## 概念说明

DealDamageEffect 是把效果转换成伤害请求的内置 Effect。它用配置和 GameplayContext 创建 DamageRequest 并交给 CombatResolver 结算，再由目标 HealthComponent 应用。技能和攻击不应该直接扣血，而应该走统一战斗公式。

## 设计目的

成为所有通过技能或效果链造成伤害的统一路径，确保所有伤害都经过 CombatResolver 的公式（攻击力、暴击、防御）处理，并支持 on-hit 状态附加的配置化管理。

## 文件

`res://addons/mkit/kernel/effects/builtin/deal_damage_effect.gd`

## 字段说明

- **base_amount**：基础伤害/治疗数值。例：火球基础伤害 20，最终伤害还要经过攻击力、暴击和防御计算。
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **can_crit**：是否允许暴击。例：普通攻击可以暴击，持续毒伤通常不暴击。
- **hit_tags**：代码字段。写入 DamageRequest.tags 的命中标签列表。
- **on_hit_statuses**：命中时尝试附加的状态（含概率/层数/时长），交给 CombatResolver 掷定、HealthComponent 施加。例：燃烧火球可不再单独配 ApplyStatusEffect，直接写 `[{"status_id":"status.burn","chance":0.3}]`，让伤害和上状态共享同一次命中判定。

## 接口

```gdscript
class_name DealDamageEffect
extends GameEffect
@export var base_amount: float = 10.0
@export var damage_type: String = "physical"
@export var element_type: String = "none"
@export var can_crit: bool = true
@export var hit_tags: Array[String] = []
@export var on_hit_statuses: Array[Dictionary] = []
```

## 函数使用场景

- **`_apply_impl(context)`**：内部实现方法。创建 DamageRequest（base_amount、damage_type、element_type、can_crit、on_hit_statuses 来自字段配置，source/target 来自 context），交给 CombatResolver.get_default().resolve()，再把 DamageResult 传给 target 的 HealthComponent.apply_damage()。失败时（缺少 source/target/HealthComponent）返回 EffectResult.fail。

字段说明：
- **`on_hit_statuses`**：命中时尝试附加的状态列表，由 CombatResolver 掷概率，命中的状态写入 DamageResult，由 HealthComponent 统一施加。可替代单独配置 ApplyStatusEffect。

## 使用示例

```gdscript
var effect := DealDamageEffect.new()
effect.effect_id = "effect.fireball_damage"
effect.base_amount = 25.0
effect.damage_type = "magic"
effect.element_type = "fire"
effect.can_crit = true
effect.on_hit_statuses = [
    {"status_id": "status.burn", "chance": 0.3, "stacks": 1, "duration": 4.0}
]

var ctx := GameplayContext.new()
ctx.source = player
ctx.target = enemy

var result := effect.apply(ctx)
print(result.payload) # {"final_amount": ..., "critical": ..., "lethal": ...}
```
