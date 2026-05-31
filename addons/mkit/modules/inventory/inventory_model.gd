class_name InventoryModel
extends RefCounted

## Purpose: Public runtime field `owner_id`.
## Example: `self.owner_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var owner_id: String = ""
## Purpose: Public runtime field `capacity`.
## Example: `self.capacity = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var capacity: int = 30
## Purpose: Public runtime field `slots`.
## Example: `self.slots = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var slots: Array[InventorySlot] = []


## Purpose: Public method `setup` for external gameplay integration.
## Example: `self.setup(<slot_count>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func setup(slot_count: int) -> void:
	capacity = slot_count
	slots.clear()
	for i in range(slot_count):
		var slot := InventorySlot.new()
		slot.index = i
		slots.append(slot)


## Purpose: Public method `find_first_empty_slot` for external gameplay integration.
## Example: `self.find_first_empty_slot()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func find_first_empty_slot() -> InventorySlot:
	for slot in slots:
		if slot.is_empty():
			return slot
	return null


## Purpose: Public method `find_stackable_slot` for external gameplay integration.
## Example: `self.find_stackable_slot(<definition>, <item>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func find_stackable_slot(definition: ItemDefinition, item: ItemInstance) -> InventorySlot:
	if not definition.stackable:
		return null
	for slot in slots:
		if slot.item != null and slot.item.definition_id == item.definition_id \
				and slot.item.quantity < definition.max_stack:
			return slot
	return null


## Purpose: Public method `get_items` for external gameplay integration.
## Example: `self.get_items()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_items() -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []
	for slot in slots:
		if slot.item != null:
			result.append(slot.item)
	return result
