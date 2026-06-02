class_name InventoryModel
extends RefCounted
var owner_id: String = ""
var capacity: int = 30
var slots: Array[InventorySlot] = []


func setup(slot_count: int) -> void:
	capacity = slot_count
	slots.clear()
	for i in range(slot_count):
		var slot := InventorySlot.new()
		slot.index = i
		slots.append(slot)


func find_first_empty_slot() -> InventorySlot:
	for slot in slots:
		if slot.is_empty():
			return slot
	return null


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


func get_items() -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []
	for slot in slots:
		if slot.item != null:
			result.append(slot.item)
	return result
