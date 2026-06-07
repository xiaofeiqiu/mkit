# HealEffect

**层：** Module  
**文件：** `addons/mkit/modules/combat/health/heal_effect.gd`  
**继承：** `extends GameEffect`

## 职责

治疗效果。对 `context.target`（为空则回退 `context.source`）的 `HealthComponent` 回血。常用作技能/奖励的 effect。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `base_amount` | `float` | `20.0` | 治疗量 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `_apply_impl(context) -> EffectResult` | `EffectResult` | 失败：`no_target` / `no_health_component`；成功 payload 含 `healed_amount` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var heal := HealEffect.new()
heal.effect_id = "potion_heal"
heal.base_amount = 40.0
# 配进 RewardDefinition.effects 或 ItemDefinition.use_effects
```

## 相关

- → [GameEffect](../kernel/GameEffect.md) · [HealthComponent](HealthComponent.md)
- → [cookbook/08_loot_and_rewards.md](../../cookbook/08_loot_and_rewards.md)
