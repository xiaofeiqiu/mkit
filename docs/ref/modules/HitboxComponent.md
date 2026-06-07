# HitboxComponent

**层：** Module  
**文件：** `addons/mkit/modules/combat/hitbox_component.gd`  
**继承：** `extends Area2D`

## 职责

攻击判定盒。`active` 时与重叠的 `HurtboxComponent` 碰撞即构造 `DamageRequest` → `CombatService.resolve` → `HealthComponent.apply_damage`。由 `TimedAttackAction` 在攻击的 active 窗口内开关。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `active` | `bool` | `false` | 是否生效（用 `set_active` 控制）|
| `base_damage` | `float` | `1.0` | 基础伤害 |
| `damage_type` | `String` | `"physical"` | 伤害类型 |
| `element_type` | `String` | `"none"` | 元素 |
| `hit_once_per_activation` | `bool` | `true` | 每次激活只命中同一目标一次 |
| `target_factions` | `Array[String]` | `["enemy"]` | 只打这些阵营 |
| `on_hit_statuses` | `Array[Dictionary]` | `[]` | 命中附带状态 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `set_active(value: bool) -> void` | — | 开关判定；开启时清空已命中表并扫描当前重叠 |

## 使用模式

### 最小示例（Level 1）

```gdscript
# 通常由 TimedAttackAction 控制；手动开关：
var hitbox := player.get_node("Components/HitboxComponent") as HitboxComponent
hitbox.set_active(true)
# ...active 窗口结束后
hitbox.set_active(false)
```

## 相关

- → [HurtboxComponent](HurtboxComponent.md) · [TimedAttackAction](TimedAttackAction.md) · [CombatService](CombatService.md)
- → [cookbook/04_attack_action.md](../../cookbook/04_attack_action.md)
