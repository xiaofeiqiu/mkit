# InventoryModel

## 概念说明

InventoryModel 是背包的纯数据模型，不负责 UI。它添加、移除、堆叠、移动、查找、序列化和恢复物品实例。玩家即使没有打开背包界面，也可能拾取、消耗、保存和恢复物品；这些逻辑应该独立于 UI。

## 设计目的

把背包的数据结构和操作逻辑与 UI 显示分离，使 InventoryController 可以在无界面状态下完成所有背包操作，InventoryUI 只负责读取 model 状态并渲染。

## 文件

`res://addons/mkit/modules/inventory/inventory_model.gd`

## 接口

```gdscript
class_name InventoryModel
extends RefCounted

var owner_id: String = ""
var capacity: int = 30
var slots: Array[InventorySlot] = []

func setup(slot_count: int) -> void: ...
func find_first_empty_slot() -> InventorySlot: ...
func find_stackable_slot(definition: ItemDefinition, item: ItemInstance) -> InventorySlot: ...
func get_items() -> Array[ItemInstance]: ...
```

## 函数使用场景

- **`setup(slot_count)`**：初始化指定数量的 InventorySlot，每个槽位赋予 index。InventoryController._ready() 和 from_save_data() 调用此方法，确保 slots 数组匹配配置容量。
- **`find_first_empty_slot()`**：返回第一个 `item == null` 的槽位，InventoryController.add_item() 在无法堆叠时调用，查找放置新物品的位置。
- **`find_stackable_slot(definition, item)`**：若物品可堆叠，查找已有相同物品且未满的槽位；找不到则返回 null。InventoryController.add_item() 优先尝试此方法。
- **`get_items()`**：返回所有非空槽位的 ItemInstance 列表，供存档序列化、UI 渲染和效果系统遍历背包使用。

## 使用示例

```gdscript
var model := InventoryModel.new()
model.setup(20)

var empty_slot := model.find_first_empty_slot()
empty_slot.item = ItemInstance.create("item.potion_small", 1)

var all_items := model.get_items()
print(all_items.size()) # 1
```
