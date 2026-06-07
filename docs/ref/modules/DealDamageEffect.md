# DealDamageEffect

**层：** Module  
**文件：** `addons/mkit/modules/combat/damage/deal_damage_effect.gd`  
**继承：** `extends GameEffect`

## 职责

对 `context.target` 造成伤害的效果（不依赖物理碰撞）。技能/动作的 effect 链里最常用的一个。内部走 `CombatService.resolve` → `HealthComponent.apply_damage`。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `base_amount` | `float` | `10.0` | 基础伤害 |
| `damage_type` | `String` | `"physical"` | 伤害类型 |
| `element_type` | `String` | `"none"` | 元素 |
| `can_crit` | `bool` | `true` | 允许暴击 |
| `hit_tags` | `Array[String]` | `[]` | 标签 |
| `on_hit_statuses` | `Array[Dictionary]` | `[]` | 命中附带状态 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 失败原因：`no_target` / `no_health_component`；成功 payload 含 `final_amount` / `was_critical` |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 配进 AbilityDefinition.effects 或 GameAction.on_complete_effects：
var dmg := DealDamageEffect.new()
dmg.effect_id = "fireball_hit"
dmg.base_amount = 30.0
dmg.damage_type = "magic"
```

## 相关

- → [GameEffect](../kernel/GameEffect.md) · [CombatService](CombatService.md) · [HealthComponent](HealthComponent.md)
- → [cookbook/03_health_and_stats.md](../../cookbook/03_health_and_stats.md) · [cookbook/05_ability.md](../../cookbook/05_ability.md)
