# LootTableDefinition

**层：** Module  
**文件：** `addons/mkit/modules/loot/loot_table_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

掉落表（`.tres`）：掷几次、有哪些条目、是否允许空掉落。`LootService.roll_table` 按它产出。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `loot_table_id` | `String` | `""` | 唯一 id |
| `rolls` | `int` | `1` | 掷骰次数 |
| `entries` | `Array[LootEntry]` | `[]` | 条目（带权重）|
| `allow_empty` | `bool` | `true` | 是否可能空掉落 |
| `empty_weight` | `float` | `0.0` | 空结果的权重 |

## 相关

- → [LootEntry](LootEntry.md) · [LootService](LootService.md) · [LootRollResult](LootRollResult.md)
