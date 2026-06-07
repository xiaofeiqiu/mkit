# ApplyStatModifierEffect

**层：** Module  
**文件：** `addons/mkit/modules/combat/stats/apply_stat_modifier_effect.gd`  
**继承：** `extends GameEffect`

## 职责

效果：给 source 或 target 的 `StatsComponent` 加一个属性修饰器。常用作奖励（永久加属性）或 buff 技能（限时）。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `stat_id` | `String` | `""` | 目标属性 |
| `operation` | `Operation` | `FLAT_ADD` | 运算方式 |
| `value` | `float` | `0.0` | 数值 |
| `duration` | `float` | `-1.0` | 持续时间（`-1` 永久）|
| `stacking_rule` | `StackingRule` | `STACK` | 叠加规则 |
| `apply_to_source` | `bool` | `true` | 真→作用 source，否则 target |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 失败：`Missing stat_id` / `Missing receiver` / `Receiver has no StatsComponent` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 奖励：永久 +5 攻击力给接收者
var buff := ApplyStatModifierEffect.new()
buff.stat_id = "attack_power"
buff.operation = StatModifierDefinition.Operation.FLAT_ADD
buff.value = 5.0
buff.duration = -1.0
buff.apply_to_source = true
```

## 相关

- → [GameEffect](../kernel/GameEffect.md) · [StatsComponent](StatsComponent.md) · [StatModifierDefinition](StatModifierDefinition.md)
- → [cookbook/10_quest.md](../../cookbook/10_quest.md)（任务奖励）
