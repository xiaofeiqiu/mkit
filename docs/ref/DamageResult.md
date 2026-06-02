# DamageResult

## 概念说明

DamageResult 是一次伤害结算的结果单。它记录最终伤害、是否暴击、是否被闪避/格挡、是否致命，以及命中时实际附加的状态效果列表。HealthComponent、伤害数字 UI、音效、死亡流程和 Analytics 都应该读取同一个结果，而不是各自猜测发生了什么。

## 设计目的

提供伤害结算后的完整结构化输出，让所有下游系统（HP 扣除、UI 显示、事件发送、状态附加）都基于同一份数据运作，避免重复计算和数据不一致。

## 文件

`res://addons/mkit/modules/combat/damage_result.gd`

## 字段说明

- **source**：玩法来源节点。例：火球的 source 是玩家，后续伤害、仇恨、经验归属都可以追踪到玩家。
- **target**：玩法目标节点。例：HealEffect 的 target 是玩家，DealDamageEffect 的 target 是被命中的敌人。
- **base_amount**：基础伤害/治疗数值。例：火球基础伤害 20，最终伤害还要经过攻击力、暴击和防御计算。
- **final_amount**：结算后的最终数值。例：base 20 加攻击加成后被防御抵消，最终造成 27 点伤害。
- **damage_type**：伤害类型。例：physical、magic、true，用于不同防御规则。
- **element_type**：元素类型。例：fire、ice、poison，用于抗性、弱点或状态联动。
- **was_critical**：本次是否暴击。例：UI 根据它显示更大的黄色伤害数字。
- **was_evaded**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **was_blocked**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **was_lethal**：本次是否致命。例：HealthComponent 根据它触发死亡流程和掉落。
- **applied_status_effects**：本次命中实际附加的 status_id 列表。例：火球命中且燃烧判定通过时为 `["status.burn"]`；UI、Analytics 和 DebugOverlay 据此显示"造成燃烧"。
- **status_applications**：与上一字段配套的完整施加条目（含 stacks/duration），供 HealthComponent 真正调用 StatusEffectController.apply_status。
- **trace**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

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
var applied_status_effects: Array[String] = []
var status_applications: Array[Dictionary] = []
var trace: Dictionary = {}
func to_debug_dict() -> Dictionary
```

## 函数使用场景

- **`to_debug_dict()`**：将结算结果转为 Dictionary，供 EventRouter 打包进 `damage_applied` 事件的 payload，以及 DebugOverlay 显示伤害 trace（base、attack_power、crit、defense、final 各阶段数值）。

DamageResult 的字段在创建后只读，由 CombatResolver 填充后传给 HealthComponent：

- **`final_amount`**：供 HealthComponent 扣除 HP 和 DamageNumberSystem 显示。
- **`was_critical`**：FeedbackSystem 据此选择显示大字暴击数字。
- **`was_lethal`**：HealthComponent 在检测到此标志时触发死亡流程。
- **`applied_status_effects`**：Analytics 和 DebugOverlay 显示"本次命中附加了哪些状态"。
- **`status_applications`**：HealthComponent 的 `_apply_on_hit_statuses` 据此调用 StatusEffectController.apply_status。

## 使用示例

```gdscript
var result := CombatResolver.get_default().resolve(request)
print("Final damage: ", result.final_amount)
print("Was critical: ", result.was_critical)
print("Was lethal: ", result.was_lethal)
print("Applied statuses: ", result.applied_status_effects)
print("Trace: ", result.to_debug_dict())
```
