# DamageResult

## 概念说明

DamageResult 是一次伤害结算的结果单。它记录最终伤害、是否暴击、是否被闪避/格挡、是否致命，以及命中时实际附加的状态效果列表。HealthComponent、伤害数字 UI、音效、死亡流程和 Analytics 都应该读取同一个结果，而不是各自猜测发生了什么。

## 设计目的

提供伤害结算后的完整结构化输出，让所有下游系统（HP 扣除、UI 显示、事件发送、状态附加）都基于同一份数据运作，避免重复计算和数据不一致。

## 文件

`res://addons/mkit/modules/combat/damage_result.gd`

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
var status_applications: Array[Dictionary] = [] # {status_id, stacks, duration}
var trace: Dictionary = {}

func to_debug_dict() -> Dictionary: ...
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
