# DamageRequest

## 概念说明

DamageRequest 是一次伤害结算的输入单。它携带攻击者、目标、基础伤害、伤害类型、元素类型、是否可暴击、标签和 on-hit 状态列表。Hitbox、Projectile、Trap、技能都可以产生伤害，但它们不应该自己算最终伤害；统一请求交给 CombatResolver 处理。

## 设计目的

把"发起一次伤害"所需的全部输入收拢到一个数据对象，让所有伤害来源（近战攻击、投射物、陷阱、技能效果）都走同一套结算管线，确保伤害公式、暴击、防御和状态附加逻辑集中在 CombatResolver 中，而非散落在各处。

## 文件

`res://addons/mkit/modules/combat/damage_request.gd`

## 字段说明

- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **base_amount**：基础伤害/治疗数值。例：火球基础伤害 20，最终伤害还要经过攻击力、暴击和防御计算。
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **can_crit**：是否允许暴击。例：普通攻击可以暴击，持续毒伤通常不暴击。
- **can_evade**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **can_block**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **tags**：标签集合。例：enemy、boss、projectile、fire，条件和效果可以通过标签判断适用性。
- **on_hit_statuses**：命中时尝试附加的状态列表。例：火球命中有 30% 概率挂 burn，可写 `[{"status_id":"status.burn","chance":0.3,"stacks":1,"duration":4.0}]`。CombatResolver 会用 RandomService 掷概率，命中的状态记录到 DamageResult.applied_status_effects，由 HealthComponent 统一施加。
- **payload**：扩展数据包。例：attack 命令可以放 direction，cast_ability 可以放 ability_id；MVP 阶段允许用它承载少量灵活数据。

## 接口

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
var on_hit_statuses: Array[Dictionary] = []
var payload: Dictionary = {}
```

## 函数使用场景

DamageRequest 是纯数据对象，无公开方法。填充后传入 `CombatResolver.resolve()` 进行结算。

- **`source` / `target`**：攻击来源和受击目标节点，CombatResolver 从中读取各自的 StatsComponent，EventRouter 从中提取 entity_id 写入事件日志。
- **`base_amount`**：伤害的起点数值，CombatResolver 在此基础上叠加 attack_power、damage_multiplier、暴击和防御。
- **`damage_type`**：决定使用哪套防御规则（physical 扣 defense，magic 忽略物防等）。
- **`on_hit_statuses`**：命中时尝试附加的状态列表。CombatResolver 用 RandomService 对每项掷概率，命中的状态写入 DamageResult，由 HealthComponent 施加到目标。

## 使用示例

```gdscript
var request := DamageRequest.new()
request.source = player
request.target = enemy
request.base_amount = 20.0
request.damage_type = "physical"
request.element_type = "none"
request.can_crit = true
request.tags = ["melee", "basic_attack"]
# 30% 概率附加燃烧
request.on_hit_statuses = [
    {"status_id": "status.burn", "chance": 0.3, "stacks": 1, "duration": 4.0}
]

var result := CombatResolver.get_default().resolve(request)
var health := enemy.get_node("Components/HealthComponent") as HealthComponent
health.apply_damage(result)
```
