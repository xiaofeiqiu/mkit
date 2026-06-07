# DamageStatusApplication

**文件：** `addons/mkit/modules/combat/damage_status_application.gd`  
**用途：** 命中状态应用项的轻量描述。

## 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `status_id` | `String` | `""` | 状态定义 ID |
| `stacks` | `int` | `1` | 状态层数 |
| `duration` | `float` | `-1.0` | 持续时长（`-1`=无限） |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `from_dictionary(raw: Dictionary) -> DamageStatusApplication` | `DamageStatusApplication` | 从字典恢复 |
| `from_values(status_id: String, stacks: int = 1, duration: float = -1.0) -> DamageStatusApplication` | `DamageStatusApplication` | 便捷构造 |
| `to_dictionary() -> Dictionary` | `Dictionary` | 序列化 |

## 相关

- → [DamageIntent](DamageIntent.md)
- → [DamageResolution](DamageResolution.md)
