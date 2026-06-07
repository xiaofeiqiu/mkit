class_name InventoryController
extends SaveableComponent
signal inventory_changed
signal item_added(item: ItemInstance)
signal item_removed(item: ItemInstance)
@export var capacity: int = 30
var model := InventoryModel.new()
var content: ContentService = null


func _ready() -> void:
	if ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentService
	capacity = max(1, capacity)
	model.setup(capacity)
	model.owner_id = _get_owner_id()


func can_add_item(item: ItemInstance) -> bool:
	if item == null:
		return false
	if item.quantity <= 0:
		return false
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	if definition.stackable and definition.max_stack <= 0:
		return false
	return _free_space_for(definition) >= item.quantity


func add_item(item: ItemInstance) -> bool:
	if item == null:
		push_warning("InventoryController.add_item: item is null")
		return false
	if item.quantity <= 0:
		push_warning("InventoryController.add_item: item quantity must be > 0")
		return false
	var definition := get_item_definition(item.definition_id)
	if definition == null:
		return false
	if definition.stackable and definition.max_stack <= 0:
		push_error(
			(
				"InventoryController.add_item: stackable item has invalid max_stack <= 0: %s"
				% item.definition_id
			)
		)
		return false
	var stack_size := definition.max_stack if definition.stackable else 1
	if stack_size <= 0:
		push_error(
			"InventoryController.add_item: invalid stack size for item %s" % item.definition_id
		)
		return false
	if _free_space_for(definition) < item.quantity:
		return false
	var remaining := item.quantity
	var original_quantity := item.quantity
	if definition.stackable:
		for slot in model.slots:
			if slot.item != null and slot.item.definition_id == item.definition_id:
				var space := definition.max_stack - slot.item.quantity
				if space <= 0:
					continue
				var moved := min(space, remaining)
				slot.item.quantity += moved
				remaining -= moved
				if remaining <= 0:
					item_added.emit(item)
					_emit_inventory_changed(item, original_quantity, "added")
					return true
	var placed_original := false
	while remaining > 0:
		var empty := model.find_first_empty_slot()
		if empty == null:
			break
		var amount := min(remaining, stack_size)
		var stack: ItemInstance
		if not placed_original:
			item.quantity = amount
			stack = item
			placed_original = true
		else:
			stack = ItemInstance.create(item.definition_id, amount)
		empty.item = stack
		remaining -= amount
	item_added.emit(item)
	_emit_inventory_changed(item, original_quantity, "added")
	return true


func _free_space_for(definition: ItemDefinition) -> int:
	var stack_size := definition.max_stack if definition.stackable else 1
	if stack_size <= 0:
		return 0
	var total := 0
	for slot in model.slots:
		if slot.item == null:
			total += stack_size
		elif definition.stackable and slot.item.definition_id == definition.item_id:
			total += max(0, stack_size - slot.item.quantity)
	return total


func remove_item_by_instance_id(instance_id: String, quantity: int = 1) -> bool:
	if instance_id.strip_edges() == "":
		return false
	if quantity <= 0:
		push_warning("InventoryController.remove_item_by_instance_id: quantity must be > 0")
		return false
	for slot in model.slots:
		if slot.item != null and slot.item.instance_id == instance_id:
			var removed_quantity: int = min(quantity, slot.item.quantity)
			var changed_item := slot.item
			slot.item.quantity -= quantity
			if slot.item.quantity <= 0:
				var removed := slot.item
				slot.clear()
				item_removed.emit(removed)
			_emit_inventory_changed(changed_item, removed_quantity, "removed")
			return true
	return false


func find_item(instance_id: String) -> ItemInstance:
	for slot in model.slots:
		if slot.item != null and slot.item.instance_id == instance_id:
			return slot.item
	return null


func find_item_by_definition(definition_id: String) -> ItemInstance:
	for slot in model.slots:
		if slot.item != null and slot.item.definition_id == definition_id:
			return slot.item
	return null


func get_item_definition(item_id: String) -> ItemDefinition:
	if item_id.strip_edges() == "":
		return null
	if content == null:
		if ServiceRegistry.has_service("content"):
			content = ServiceRegistry.get_service("content") as ContentService
	if content == null:
		return null
	return content.get_resource(item_id) as ItemDefinition


func to_save_data() -> Dictionary:
	var items: Array = []
	for slot in model.slots:
		items.append(slot.item.to_save_data() if slot.item != null else null)
	return {"capacity": capacity, "items": items}


func from_save_data(data: Dictionary) -> void:
	capacity = int(data.get("capacity", capacity))
	capacity = max(1, capacity)
	model.setup(capacity)
	var items: Array = data.get("items", [])
	for i in range(min(items.size(), model.slots.size())):
		if items[i] != null:
			model.slots[i].item = ItemInstance.from_save_data(items[i])
	_emit_inventory_changed(null, 0, "loaded")


func _emit_inventory_changed(
	item: ItemInstance = null, quantity: int = 0, change_type: String = ""
) -> void:
	inventory_changed.emit()
	var events: EventService = null
	if ServiceRegistry.has_service("events"):
		events = ServiceRegistry.get_service("events") as EventService
	if events != null:
		events.emit_inventory_changed(
			_get_owner_id(), item.definition_id if item != null else "", quantity, change_type
		)


func _get_owner_id() -> String:
	var owner_node := owner if owner != null else get_parent()
	if owner_node == null:
		return name
	var identity := owner_node.get_node_or_null("EntityIdentity") as EntityIdentity
	return identity.entity_id if identity != null else str(owner_node.name)
