# DamageResolution

**文件：** `addons/mkit/modules/combat/damage_resolution.gd`  
**用途：** 伤害计算中间产物，携带命中判定与数值后的最终统计。

## 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `source` | `Node` | `null` | 伤害来源 |
| `target` | `Node` | `null` | 伤害目标 |
| `base_amount` | `float` | `0.0` | 基础伤害 |
| `final_amount` | `float` | `0.0` | 最终伤害 |
| `damage_type` | `String` | `"physical"` | 伤害类型 |
| `element_type` | `String` | `"none"` | 元素类型 |
| `was_critical` | `bool` | `false` | 暴击结果 |
| `was_evaded` | `bool` | `false` | 闪避结果 |
| `was_blocked` | `bool` | `false` | 格挡结果 |
| `was_lethal` | `bool` | `false` | 是否致命 |
| `applied_status_effects` | `Array[DamageStatusApplication]` | `[]` | 已应用状态 |
| `trace` | `Dictionary` | `{}` | 调试链路 |
| `failure_reason` | `String` | `""` | 失败原因 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `to_result() -> DamageResult` | `DamageResult` | 映射为公开 `DamageResult` |

## 相关

- → [DamageIntent](DamageIntent.md)
- → [DamageStatusApplication](DamageStatusApplication.md)
