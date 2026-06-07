# EquipmentController

**层：** Module  
**文件：** `addons/mkit/modules/inventory/equipment_controller.gd`  
**继承：** `extends SaveableComponent`

## 职责

装备控制器，挂在 `Controllers/EquipmentController`。装备/卸下物品，并把物品的 `stat_modifiers` 与随机词条挂到/卸下同实体 `StatsComponent`（按 `instance_id` 作为来源）。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `allowed_slots` | `Array[String]`（@export）| `["weapon","helmet","armor","ring","amulet"]` | 允许的装备槽 |
| `equipped` | `Dictionary` | `{}` | `slot_id → ItemInstance` |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `can_equip(item, slot_id) -> bool` | `bool` | 物品的 `equipment_slot` 是否匹配 |
| `equip(item, slot_id) -> bool` | `bool` | 装备（先卸下原有），挂属性 |
| `unequip(slot_id) -> ItemInstance` | — | 卸下并卸属性 |
| `get_equipped(slot_id) -> ItemInstance` | — | 查某槽 |

## 信号

`equipment_changed(slot_id, item)`

## 使用模式

### 最小示例（Level 1）

```gdscript
var equip := player.get_node("Controllers/EquipmentController") as EquipmentController
if equip.can_equip(sword, "weapon"):
    equip.equip(sword, "weapon")   # StatsComponent 自动加上武器词条
```

## 相关

- → [InventoryController](InventoryController.md) · [ItemDefinition](ItemDefinition.md) · [ref/modules/StatsComponent.md](StatsComponent.md)
