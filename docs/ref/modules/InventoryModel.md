# InventoryModel

**层：** Module  
**文件：** `addons/mkit/modules/inventory/inventory_model.gd`  
**继承：** `extends RefCounted`

## 职责

背包的**纯数据模型**：固定数量的格子与查询/定位辅助。`InventoryController` 包着它做信号/存档。

## 字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `owner_id` | `String` | `""` | 拥有者 id |
| `capacity` | `int` | `30` | 格子数 |
| `slots` | `Array[InventorySlot]` | `[]` | 格子数组 |

## 方法

| 方法签名 | 返回值 | 说明 |
|----------|--------|------|
| `setup(slot_count) -> void` | — | 初始化指定数量空格 |
| `find_first_empty_slot() -> InventorySlot` | — | 找第一个空格 |
| `find_stackable_slot(definition, item) -> InventorySlot` | — | 找可堆叠格 |
| `get_items() -> Array[ItemInstance]` | — | 当前所有物品 |

## 相关

- → [InventorySlot](InventorySlot.md) · [InventoryController](InventoryController.md)
