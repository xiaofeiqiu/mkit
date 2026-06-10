class_name InventoryEvents
extends RefCounted
## Inventory-owned domain event catalog: event type constants + DomainEvent constructors.

const INVENTORY_CHANGED := "inventory_changed"


static func inventory_changed(
	owner_id: String, item_id: String = "", quantity: int = 0, change_type: String = ""
) -> DomainEvent:
	var payload: Dictionary = {"owner_id": owner_id}
	if item_id != "":
		payload["item_id"] = item_id
	if quantity > 0:
		payload["quantity"] = quantity
	if change_type != "":
		payload["change_type"] = change_type
	return DomainEvent.create(INVENTORY_CHANGED, owner_id, item_id, payload)
