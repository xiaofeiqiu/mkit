# InventoryController

## 概念说明

InventoryController 是实体背包操作的场景控制器。它连接拾取、命令、UI、存档和 InventoryModel，负责背包数据和外部系统之间的桥接。背包数据和 UI 需要解耦；即使背包界面没打开，拾取和存档也应该正常工作。

## 设计目的

作为背包操作的对外接口，把 InventoryModel 的数据操作、ItemDefinition 的规则查找、堆叠逻辑、信号发送和存档序列化统一管理，使外部系统（掉落、命令、奖励）只需调用 add_item/remove_item 而无需了解内部数据结构。

## 文件

`res://addons/mkit/modules/inventory/inventory_controller.gd`

## 字段说明

- **capacity**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **model**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **content**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name InventoryController
extends Node
signal inventory_changed
signal item_added(item: ItemInstance)
signal item_removed(item: ItemInstance)
@export var capacity: int = 30
var model := InventoryModel.new()
var content: ContentRegistry = null
func can_add_item(item: ItemInstance) -> bool
func add_item(item: ItemInstance) -> bool
func remove_item_by_instance_id(instance_id: String, quantity: int = 1) -> bool
func find_item(instance_id: String) -> ItemInstance
func find_item_by_definition(definition_id: String) -> ItemInstance
func get_item_definition(item_id: String) -> ItemDefinition
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`can_add_item(item)`**：拾取前检查，优先查找可堆叠槽位，其次查找空格子，两者都不存在时返回 false。GrantItemEffect 和 Pickup 场景在实际 add 之前调用此方法。
- **`add_item(item)`**：执行添加，优先堆叠到已有槽位，超过 max_stack 则开新格子。全部放入成功返回 true，背包满（部分放入或未放入）返回 false，并发出 `item_added` 和 `inventory_changed` 信号（以及携带 item_id、quantity、change_type 的 EventRouter.inventory_changed）。
- **`remove_item_by_instance_id(instance_id, quantity)`**：按 instance_id 查找并减少数量，归零时清空槽位并发出 `item_removed`。使用消耗品、丢弃物品时调用，并发出携带移除物品信息的 EventRouter.inventory_changed。
- **`find_item(instance_id)`**：按 instance_id 在所有槽位中查找 ItemInstance，供装备系统或任务系统检查特定物品是否在背包中。
- **`to_save_data()` / `from_save_data(data)`**：序列化和反序列化所有槽位的物品数据，供 Saveable 接口或 SaveManager 使用。

## 使用示例

### 添加物品

```gdscript
var inventory := player.get_node("Controllers/InventoryController") as InventoryController
var item := ItemInstance.create("item.potion_small", 3)

if inventory.can_add_item(item):
    inventory.add_item(item)
```

### 删除物品

```gdscript
inventory.remove_item_by_instance_id(item.instance_id, 1)
```

### 保存和恢复背包

```gdscript
var save_data := inventory.to_save_data()
inventory.from_save_data(save_data)
```
