# InventorySlot

## 概念说明

InventorySlot 是背包中的一个格子或存储位置。它保存该格子里的 ItemInstance 及格子索引。UI 网格、快捷栏、背包容量和物品移动都需要明确的 slot，而不是只有一个散列表。

## 设计目的

把背包的存储结构抽象为离散的格子，使 InventoryModel 能管理格子数量上限、堆叠查找和物品移动，同时让 UI 能按格子索引渲染物品图标。

## 文件

`res://addons/mkit/modules/inventory/inventory_slot.gd`

## 接口

```gdscript
class_name InventorySlot
extends RefCounted

var index: int = -1
var item: ItemInstance = null

func is_empty() -> bool:
    return item == null

func clear() -> void:
    item = null
```

## 函数使用场景

- **`is_empty()`**：InventoryModel 查找空格子、判断是否有空间拾取物品时调用。UI 据此决定是否在格子上渲染物品图标。
- **`clear()`**：物品移出格子（使用消耗品、丢弃、卸下装备）时调用，将 `item` 设为 null，释放对 ItemInstance 的引用。

## 使用示例

```gdscript
var slot := InventorySlot.new()
slot.index = 0
slot.item = ItemInstance.create("item.potion_small", 3)

if not slot.is_empty():
    print(slot.item.definition_id) # "item.potion_small"

# 清空格子
slot.clear()
print(slot.is_empty()) # true
```
