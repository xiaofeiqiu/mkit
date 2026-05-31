class_name InventoryController
extends Node

## Purpose: Emits the `inventory_changed` signal to notify external listeners of a state change.
## Example: `self.inventory_changed.connect(_on_inventory_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal inventory_changed
## Purpose: Emits the `item_added` signal to notify external listeners of a state change.
## Example: `self.item_added.connect(_on_item_added)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal item_added(item: ItemInstance)
## Purpose: Emits the `item_removed` signal to notify external listeners of a state change.
## Example: `self.item_removed.connect(_on_item_removed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal item_removed(item: ItemInstance)

## Purpose: Inspector-exposed configuration `capacity`.
## Example: `self.capacity = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var capacity: int = 30

## Purpose: Public runtime field `model`.
## Example: `self.model = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var model := InventoryModel.new()
## Purpose: Public runtime field `content`.
## Example: `self.content = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var content: ContentRegistry = null


func _ready() -> void:
	content = ServiceRegistry.get_service("content") as ContentRegistry
	model.setup(capacity)
	model.owner_id = _get_owner_id()


## Purpose: Public method `can_add_item` for external gameplay integration.
## Example: `self.can_add_item(<item>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func can_add_item(item: ItemInstance) -> bool:
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	if model.find_stackable_slot(definition, item) != null:
		return true
	return model.find_first_empty_slot() != null


## Purpose: Public method `add_item` for external gameplay integration.
## Example: `self.add_item(<item>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func add_item(item: ItemInstance) -> bool:
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false

	var remaining := item.quantity
	var original_quantity := item.quantity

	if definition.stackable:
		for slot in model.slots:
			if slot.item != null and slot.item.definition_id == item.definition_id:
				var space := definition.max_stack - slot.item.quantity
				var moved := min(space, remaining)
				slot.item.quantity += moved
				remaining -= moved
				if remaining <= 0:
					item_added.emit(item)
					_emit_inventory_changed()
					return true

	while remaining > 0:
		var empty := model.find_first_empty_slot()
		if empty == null:
			item.quantity = remaining
			if remaining < original_quantity:
				item_added.emit(item)
			_emit_inventory_changed()
			return false
		var new_stack := ItemInstance.create(item.definition_id, min(remaining, definition.max_stack))
		empty.item = new_stack
		remaining -= new_stack.quantity

	item_added.emit(item)
	_emit_inventory_changed()
	return true


## Purpose: Public method `remove_item_by_instance_id` for external gameplay integration.
## Example: `self.remove_item_by_instance_id(<instance_id>, <quantity>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func remove_item_by_instance_id(instance_id: String, quantity: int = 1) -> bool:
	for slot in model.slots:
		if slot.item != null and slot.item.instance_id == instance_id:
			slot.item.quantity -= quantity
			if slot.item.quantity <= 0:
				var removed := slot.item
				slot.clear()
				item_removed.emit(removed)
			_emit_inventory_changed()
			return true
	return false


## Purpose: Public method `find_item` for external gameplay integration.
## Example: `self.find_item(<instance_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func find_item(instance_id: String) -> ItemInstance:
	for slot in model.slots:
		if slot.item != null and slot.item.instance_id == instance_id:
			return slot.item
	return null


## Purpose: Public method `find_item_by_definition` for external gameplay integration.
## Example: `self.find_item_by_definition(<definition_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func find_item_by_definition(definition_id: String) -> ItemInstance:
	for slot in model.slots:
		if slot.item != null and slot.item.definition_id == definition_id:
			return slot.item
	return null


## Purpose: Public method `get_item_definition` for external gameplay integration.
## Example: `self.get_item_definition(<item_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_item_definition(item_id: String) -> ItemDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	return content.get_resource(item_id) as ItemDefinition


## Purpose: Public method `to_save_data` for external gameplay integration.
## Example: `self.to_save_data()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func to_save_data() -> Dictionary:
	var items: Array = []
	for slot in model.slots:
		items.append(slot.item.to_save_data() if slot.item != null else null)
	return {"capacity": capacity, "items": items}


## Purpose: Public method `from_save_data` for external gameplay integration.
## Example: `self.from_save_data(<data>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func from_save_data(data: Dictionary) -> void:
	capacity = int(data.get("capacity", capacity))
	model.setup(capacity)
	var items: Array = data.get("items", [])
	for i in range(min(items.size(), model.slots.size())):
		if items[i] != null:
			model.slots[i].item = ItemInstance.from_save_data(items[i])
	_emit_inventory_changed()


func _emit_inventory_changed() -> void:
	inventory_changed.emit()
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.emit_inventory_changed(_get_owner_id())


func _get_owner_id() -> String:
	var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
	return identity.entity_id if identity != null else str(owner.name)
