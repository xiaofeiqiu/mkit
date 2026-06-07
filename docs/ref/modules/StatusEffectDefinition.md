# StatusEffectDefinition

**层：** Module  
**文件：** `addons/mkit/modules/combat/status_effects/status_effect_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

状态效果（DOT / buff / debuff）的静态定义（`.tres`）：时长、tick 周期、叠加规则、三个 effect 链（施加/tick/移除）、属性修饰器。

## 枚举 `StackRule`

`REFRESH_DURATION`（刷新时长）、`ADD_STACK`（叠层+刷新）、`REPLACE`（替换）、`IGNORE`（忽略再施加）、`EXTEND_DURATION`（延长）、`INDEPENDENT_STACKS`

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `status_id` | `String` | `""` | 唯一 id |
| `display_name` | `String` | `""` | 显示名 |
| `duration` | `float` | `5.0` | 持续秒数 |
| `tick_interval` | `float` | `1.0` | tick 周期（`0` 不 tick）|
| `max_stacks` | `int` | `1` | 最大层数 |
| `stack_rule` | `StackRule` | `REFRESH_DURATION` | 叠加规则 |
| `effects_on_apply` | `Array[GameEffect]` | `[]` | 施加时 |
| `effects_on_tick` | `Array[GameEffect]` | `[]` | 每跳 |
| `effects_on_remove` | `Array[GameEffect]` | `[]` | 移除时 |
| `stat_modifiers` | `Array[StatModifierDefinition]` | `[]` | 期间挂载的属性修饰器 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 中毒：tick_interval=1, duration=5, effects_on_tick=[DealDamageEffect base_amount=5]
# 狂暴：tick_interval=0, stat_modifiers=[attack_power +10]
```

## 相关

- → [StatusEffectController](StatusEffectController.md) · [StatusEffectInstance](StatusEffectInstance.md) · [ApplyStatusEffect](ApplyStatusEffect.md)
- → [cookbook/12_status_effects.md](../../cookbook/12_status_effects.md)
