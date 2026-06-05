# EquipmentController

## 概念说明

EquipmentController 是装备槽和装备属性的控制器。它负责校验槽位、装备/卸下物品、应用/移除属性 modifier。装备会影响属性、技能和 UI，所以需要独立于普通背包存储。

## 设计目的

把装备的校验（物品类型、槽位匹配）、属性 modifier 的施加与移除集中到一处，使装备/卸下操作可靠地同步 StatsComponent 状态，UI 只需监听 `equipment_changed` 信号刷新装备栏显示。

## 文件

`res://addons/mkit/modules/inventory/equipment_controller.gd`

## 字段说明

- **allowed_slots**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **equipped**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。
- **content**：代码字段。实际存在于当前实现中，供运行时或 Inspector 配置使用。

## 接口

```gdscript
class_name EquipmentController
extends SaveableComponent
signal equipment_changed(slot_id: String, item: ItemInstance)
@export var allowed_slots: Array[String] = ["weapon", "helmet", "armor", "ring", "amulet"]
var equipped: Dictionary = {}
var content: ContentRegistry = null
func can_equip(item: ItemInstance, slot_id: String) -> bool
func equip(item: ItemInstance, slot_id: String) -> bool
func unequip(slot_id: String) -> ItemInstance
func get_equipped(slot_id: String) -> ItemInstance
func get_item_definition(item_id: String) -> ItemDefinition
func to_save_data() -> Dictionary
func from_save_data(data: Dictionary) -> void
```

## 函数使用场景

- **`can_equip(item, slot_id)`**：校验 slot_id 是否在 allowed_slots 中，且物品的 `equipment_slot` 与 slot_id 匹配。UI 据此决定是否允许拖入操作，装备命令在执行前也调用此方法。
- **`equip(item, slot_id)`**：若该槽位已有装备则先 unequip，再装备新物品，通过 `_apply_item_modifiers` 把 ItemDefinition.stat_modifiers 和 rolled_affixes 都添加到 StatsComponent。发出 `equipment_changed` 信号。
- **`unequip(slot_id)`**：移除槽位上的物品，通过 `_remove_item_modifiers` 按 item.instance_id 撤销 StatsComponent 中所有来自该物品的 modifier。返回被卸下的 ItemInstance，供调用方放回背包。
- **`get_equipped(slot_id)`**：查询指定槽位当前装备的 ItemInstance，UI 渲染装备栏时调用。
- **`to_save_data()` / `from_save_data(data)`**：作为 SaveableComponent 序列化 `{ slots }`，每个槽位复用 ItemInstance payload。恢复时重建已装备物品并重新应用装备 modifier。

## 使用示例

### 装备武器

```gdscript
var inventory := player.get_node("Controllers/InventoryController") as InventoryController
var equipment := player.get_node("Controllers/EquipmentController") as EquipmentController

var sword := inventory.find_item("item_instance_001")
if equipment.can_equip(sword, "weapon"):
    equipment.equip(sword, "weapon")
```

### 卸下装备

```gdscript
var old_weapon := equipment.unequip("weapon")
if old_weapon != null:
    inventory.add_item(old_weapon)
```
