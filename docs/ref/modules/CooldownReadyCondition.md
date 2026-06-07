# CooldownReadyCondition

**层：** Module  
**文件：** `addons/mkit/modules/combat/abilities/cooldown_ready_condition.gd`  
**继承：** `extends Condition`

## 职责

条件：判断 `context.source` 的某个技能冷却是否就绪。用于"只有 A 技能好了才能放 B"之类的联动门槛。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `ability_id` | `String`（@export）| `""` | 要检查的技能；空则用 `context.ability_id` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_evaluate_impl(context) -> bool` | `bool` | 查 source 的 `AbilityController.is_cooldown_ready(id)` |
| `get_failure_reason(context) -> String` | `String` | `"Cooldown not ready: <id>"` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var cond := CooldownReadyCondition.new()
cond.ability_id = "dash"
combo_ability_def.conditions = [cond]   # dash 就绪才能放连招
```

## 相关

- → [Condition](../kernel/Condition.md) · [AbilityController](AbilityController.md)
