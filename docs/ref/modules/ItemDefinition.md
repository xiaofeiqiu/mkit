# ItemDefinition

**层：** Module  
**文件：** `addons/mkit/modules/inventory/item_definition.gd`  
**继承：** `extends ContentDefinition`

## 职责

物品的静态定义（`.tres`）：类型、价值、堆叠、装备槽、使用效果、属性词条。背包、商店、掉落、装备都按 `item_id` 引用它。

## 字段（@export）

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `item_id` | `String` | `""` | 唯一 id |
| `display_name` | `String` | `""` | 显示名 |
| `description` | `String` | `""` | 描述（multiline）|
| `item_type` | `String` | `"material"` | 类型（material/consumable/equipment…）|
| `rarity` | `String` | `"common"` | 稀有度 |
| `value` | `int` | `0` | 基准价（商店买卖价基于它）|
| `icon` | `Texture2D` | — | 图标 |
| `stackable` | `bool` | `true` | 可堆叠 |
| `max_stack` | `int` | `99` | 单格上限 |
| `equipment_slot` | `String` | `""` | 装备槽（空=非装备）|
| `tags` | `Array[String]` | `[]` | 标签 |
| `use_conditions` | `Array[Condition]` | `[]` | 使用条件 |
| `use_effects` | `Array[GameEffect]` | `[]` | 使用效果 |
| `stat_modifiers` | `Array[StatModifierDefinition]` | `[]` | 装备时挂载的属性修饰器 |

## 相关

- → [ItemInstance](ItemInstance.md) · [InventoryController](InventoryController.md) · [EquipmentController](EquipmentController.md)
- → [cookbook/14_shop.md](../../cookbook/14_shop.md)
