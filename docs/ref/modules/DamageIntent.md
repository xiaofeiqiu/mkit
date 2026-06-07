# DamageIntent

**文件：** `addons/mkit/modules/combat/damage_intent.gd`  
**用途：** 伤害请求的中间意图模型，承载伤害前元数据与状态应用配置。

## 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `source` | `Node` | `null` | 伤害来源 |
| `target` | `Node` | `null` | 伤害目标 |
| `base_amount` | `float` | `0.0` | 基础伤害量 |
| `damage_type` | `String` | `"physical"` | 伤害类别 |
| `element_type` | `String` | `"none"` | 元素属性 |
| `can_crit` | `bool` | `true` | 是否允许暴击 |
| `can_evade` | `bool` | `true` | 是否允许闪避 |
| `can_block` | `bool` | `true` | 是否允许格挡 |
| `tags` | `Array[String]` | `[]` | 伤害标签 |
| `on_hit_statuses` | `Array[Dictionary]` | `[]` | 命中时附带状态 |
| `payload` | `Dictionary` | `{}` | 扩展元数据 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `from_request(request: DamageRequest) -> DamageIntent` | `DamageIntent` | 从 `DamageRequest` 复制字段，形成可复用意图 |

## 相关

- → [DamageResolution](DamageResolution.md)
- → [DamageApplication](DamageApplication.md)
