# LootEntry

**层：** Module  
**文件：** `addons/mkit/modules/loot/loot_entry.gd`  
**继承：** `extends Resource`

## 职责

掉落表的一个条目：掉什么、权重、数量区间、条件。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `content_id` | `String` | `""` | 掉落的物品 id |
| `weight` | `float` | `1.0` | 权重 |
| `min_quantity` | `int` | `1` | 最小数量 |
| `max_quantity` | `int` | `1` | 最大数量 |
| `conditions` | `Array[Condition]` | `[]` | 该条目生效条件 |

## 相关

- → [LootTableDefinition](LootTableDefinition.md) · [LootService](LootService.md)
