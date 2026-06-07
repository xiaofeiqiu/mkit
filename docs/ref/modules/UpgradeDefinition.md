# UpgradeDefinition

**层：** Module  
**文件：** `addons/mkit/modules/progression/upgrade_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

一个可购买的永久升级定义（`.tres`）：最高等级、各级花费、前置升级、解锁内容、生效 effects。`ProgressionService.unlock_or_level_up` 按它升级。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `upgrade_id` | `String` | `""` | 唯一 id |
| `display_name` | `String` | `""` | 显示名 |
| `description` | `String` | `""` | 描述 |
| `max_level` | `int` | `1` | 最高等级 |
| `currency_id` | `String` | `"meta_currency"` | 花费的货币 |
| `cost_by_level` | `Array[int]` | `[100]` | 各级花费 |
| `prerequisite_upgrade_ids` | `Array[String]` | `[]` | 前置升级 |
| `unlock_content_ids` | `Array[String]` | `[]` | 解锁的内容 id |
| `effects` | `Array[GameEffect]` | `[]` | 升级时执行 |
| `is_meta_upgrade` | `bool` | `true` | 是否局外元升级 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `get_cost_for_level(next_level) -> int` | `int` | 升到某级的花费 |

## 相关

- → [ProgressionService](ProgressionService.md)
