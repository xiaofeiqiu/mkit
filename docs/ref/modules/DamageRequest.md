# DamageRequest

**层：** Module  
**文件：** `addons/mkit/modules/combat/damage_request.gd`  
**继承：** `extends RefCounted`

## 职责

一次伤害的公开**输入**。交给 `CombatService.resolve()` 后会先转成 `DamageIntent`，再结算为 `DamageResolution` / `DamageApplication`，最终得到 `DamageResult`。由 `HitboxComponent` / `DealDamageEffect` 构造，也可手动构造。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `source` | `Node` | `null` | 攻击方（读其 `StatsComponent`）|
| `target` | `Node` | `null` | 受击方 |
| `base_amount` | `float` | `0.0` | 基础伤害 |
| `damage_type` | `String` | `"physical"` | 伤害类型 |
| `element_type` | `String` | `"none"` | 元素类型 |
| `can_crit` | `bool` | `true` | 允许暴击 |
| `can_evade` | `bool` | `true` | 允许闪避 |
| `can_block` | `bool` | `true` | 允许格挡 |
| `tags` | `Array[String]` | `[]` | 标签 |
| `on_hit_statuses` | `Array[Dictionary]` | `[]` | 命中附带状态：`{status_id, chance, stacks, duration}` |

## 使用模式

### 最小示例（Level 1）

```gdscript
var req := DamageRequest.new()
req.source = player
req.target = enemy
req.base_amount = 15.0
req.on_hit_statuses = [{"status_id": "status.bleed", "chance": 0.3}]
var result := (Mkit.combat()).resolve(req)
```

## 相关

- → [CombatService](CombatService.md) · [DamageResult](DamageResult.md) · [DealDamageEffect](DealDamageEffect.md)
- → [DamageIntent](DamageIntent.md) · [DamageResolution](DamageResolution.md) · [DamageApplication](DamageApplication.md)
