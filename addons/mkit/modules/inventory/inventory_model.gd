class_name InventoryModel
extends RefCounted
## 说明：`InventoryModel` 是 背包与装备系统 的运行时模型，负责保存领域对象集合和查询入口。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在背包与装备系统中复用这段契约或状态时使用它。
## 示例：`var instance := InventoryModel.new()`

## 运行时状态：`owner_id` 表示稳定 id，由 `InventoryModel` 的公开 API 读取或维护。
var owner_id: String = ""
## 运行时状态：`capacity` 表示 `InventoryModel` 的字段值，由 `InventoryModel` 的公开 API 读取或维护。
var capacity: int = 30
## 运行时状态：`slots` 表示 `InventoryModel` 的字段值，由 `InventoryModel` 的公开 API 读取或维护。
var slots: Array[InventorySlot] = []


## 初始化运行时依赖和起始状态，并保持 `InventoryModel` 的领域契约一致。
func setup(slot_count: int) -> void:
	capacity = slot_count
	slots.clear()
	for i in range(slot_count):
		var slot := InventorySlot.new()
		slot.index = i
		slots.append(slot)


## 执行 `find_first_empty_slot` 对应的公开操作，并保持 `InventoryModel` 的领域契约一致。
func find_first_empty_slot() -> InventorySlot:
	for slot in slots:
		if slot.is_empty():
			return slot
	return null


## 执行 `find_stackable_slot` 对应的公开操作，并保持 `InventoryModel` 的领域契约一致。
func find_stackable_slot(definition: ItemDefinition, item: ItemInstance) -> InventorySlot:
	if not definition.stackable:
		return null
	for slot in slots:
		if (
			slot.item != null
			and slot.item.definition_id == item.definition_id
			and slot.item.quantity < definition.max_stack
		):
			return slot
	return null


## 返回 `items` 对应的数据或对象，并保持 `InventoryModel` 的领域契约一致。
func get_items() -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []
	for slot in slots:
		if slot.item != null:
			result.append(slot.item)
	return result
