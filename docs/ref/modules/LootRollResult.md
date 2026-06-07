# LootRollResult

**层：** Module  
**文件：** `addons/mkit/modules/loot/loot_roll_result.gd`  
**继承：** `extends RefCounted`

## 职责

`LootService.roll_table`/`roll` 的结果：掉落的物品实例、货币与掷骰调试记录。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `item_instances` | `Array[ItemInstance]` | `[]` | 掉落物品 |
| `currency` | `Dictionary` | `{}` | 掉落货币 |
| `debug_rolls` | `Array[Dictionary]` | `[]` | 每次掷骰记录（调试）|

## 相关

- → [LootService](LootService.md) · [ItemInstance](ItemInstance.md)
