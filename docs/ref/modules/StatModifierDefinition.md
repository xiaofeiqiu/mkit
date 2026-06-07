# StatModifierDefinition

**层：** Module  
**文件：** `addons/mkit/modules/combat/stats/stat_modifier_definition.gd`  
**继承：** `extends Resource`

## 职责

属性修饰器的静态定义（`.tres`）：改哪个属性、用什么运算、叠加规则。装备词条、状态效果、奖励都用它生成运行时 `StatModifier`。

## 枚举

| 枚举 | 取值 |
|------|------|
| `Operation` | `FLAT_ADD`（加常数）、`PERCENT_ADD`（加百分比和）、`PERCENT_MULTIPLY`（乘百分比）、`OVERRIDE`（覆盖）、`CLAMP_MIN`、`CLAMP_MAX` |
| `StackingRule` | `STACK`、`REPLACE_SAME_SOURCE`、`HIGHEST_ONLY`、`LOWEST_ONLY`、`UNIQUE` |

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `modifier_id` | `String` | `""` | 标识 |
| `stat_id` | `String` | `""` | 目标属性 |
| `operation` | `Operation` | `FLAT_ADD` | 运算方式 |
| `value` | `float` | `0.0` | 数值 |
| `priority` | `int` | `0` | 计算顺序（小先算）|
| `stacking_rule` | `StackingRule` | `STACK` | 叠加规则 |
| `tags` | `Array[String]` | `[]` | 标签 |

## 结算顺序（在 `StatsComponent`）

`base + 所有FLAT_ADD → ×(1+PERCENT_ADD之和) → ×各PERCENT_MULTIPLY → OVERRIDE(取最后) → CLAMP`

## 使用模式

### 最小示例（Level 1）

```gdscript
var mod := StatModifierDefinition.new()
mod.modifier_id = "ring.atk"
mod.stat_id = "attack_power"
mod.operation = StatModifierDefinition.Operation.FLAT_ADD
mod.value = 5.0
```

## 相关

- → [StatModifier](StatModifier.md)（运行时实例）· [StatsComponent](StatsComponent.md) · [ApplyStatModifierEffect](ApplyStatModifierEffect.md)
