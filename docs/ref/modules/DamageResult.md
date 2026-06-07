# DamageResult

**层：** Module  
**文件：** `addons/mkit/modules/combat/damage_result.gd`  
**继承：** `extends RefCounted`

## 职责

一次伤害的公开**输出**。`CombatService.resolve()` 从 `DamageApplication.to_result()` 返回它，`HealthComponent.apply_damage()` 消费它并通过 `EventService.emit_damage_applied` 广播给表现层。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `source` / `target` | `Node` | `null` | 攻防双方 |
| `base_amount` | `float` | `0.0` | 原始基础值 |
| `final_amount` | `float` | `0.0` | 最终伤害 |
| `damage_type` / `element_type` | `String` | — | 类型 |
| `was_critical` | `bool` | `false` | 是否暴击 |
| `was_evaded` | `bool` | `false` | 是否闪避 |
| `was_blocked` | `bool` | `false` | 是否格挡 |
| `was_lethal` | `bool` | `false` | 是否致死（由 `apply_damage` 写）|
| `applied_status_effects` | `Array[String]` | `[]` | 命中触发的状态 id |
| `status_applications` | `Array[Dictionary]` | `[]` | 状态施加明细 |
| `trace` | `Dictionary` | `{}` | 各结算阶段中间值（调试）|

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `to_debug_dict() -> Dictionary` | `Dictionary` | 调试用字典（含 trace）|

## 使用模式

### 最小示例（Level 1）

```gdscript
events.damage_applied.connect(func(r: DamageResult):
    print("%.0f%s" % [r.final_amount, " 暴击!" if r.was_critical else ""])
)
```

## 相关

- → [CombatService](CombatService.md) · [DamageRequest](DamageRequest.md) · [DamageApplication](DamageApplication.md) · [ref/kernel/EventService.md](../kernel/EventService.md)
