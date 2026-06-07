# InventorySlot

**层：** Module  
**文件：** `addons/mkit/modules/inventory/inventory_slot.gd`  
**继承：** `extends RefCounted`

## 职责

背包的一个格子，持有一个 `ItemInstance`（或空）。`InventoryModel.slots` 是它的数组。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `index` | `int` | `-1` | 格子序号 |
| `item` | `ItemInstance` | `null` | 格内物品 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `is_empty() -> bool` | `bool` | 是否空格 |
| `clear() -> void` | — | 清空 |

## 相关

- → [InventoryModel](InventoryModel.md) · [InventoryController](InventoryController.md)
