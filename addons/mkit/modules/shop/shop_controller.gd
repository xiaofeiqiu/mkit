class_name ShopController
extends Node
signal shop_opened(shop_id: String)
signal item_purchased(item_id: String, quantity: int, total_cost: int)
signal item_sold(item_id: String, quantity: int, total_gain: int)
signal transaction_failed(item_id: String, reason: String)
var current_shop: ShopDefinition = null
var content: ContentRegistry = null


func _ready() -> void:
	if ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentRegistry


func open_shop(shop_id: String) -> bool:
	var definition := get_definition(shop_id)
	if definition == null:
		return false
	current_shop = definition
	shop_opened.emit(shop_id)
	return true


func close_shop() -> void:
	current_shop = null


func get_buy_price(item_id: String) -> int:
	if current_shop == null:
		return -1
	var entry := current_shop.get_entry(item_id)
	if entry == null:
		return -1
	if entry.price_override >= 0:
		return entry.price_override
	var item_def := _get_item_definition(item_id)
	var base := item_def.value if item_def != null else 0
	return int(round(base * current_shop.buy_price_multiplier))


func get_sell_price(item_id: String) -> int:
	if current_shop == null:
		return -1
	var item_def := _get_item_definition(item_id)
	if item_def == null:
		return -1
	return int(round(item_def.value * current_shop.sell_price_multiplier))


func can_buy(item_id: String, quantity: int, buyer: Node) -> bool:
	return _buy_block_reason(item_id, quantity, buyer) == ""


func buy(item_id: String, quantity: int, buyer: Node) -> bool:
	var reason := _buy_block_reason(item_id, quantity, buyer)
	if reason != "":
		transaction_failed.emit(item_id, reason)
		return false
	var total_cost := get_buy_price(item_id) * quantity
	var progression := _get_progression()
	if total_cost > 0 and not progression.spend_currency(current_shop.currency_id, total_cost):
		transaction_failed.emit(item_id, "Insufficient currency")
		return false
	var inventory := _get_inventory(buyer)
	var item := ItemInstance.create(item_id, quantity)
	if not inventory.add_item(item):
		if total_cost > 0:
			progression.add_currency(current_shop.currency_id, total_cost)
		transaction_failed.emit(item_id, "Inventory could not accept item")
		return false
	var entry := current_shop.get_entry(item_id)
	if entry != null and entry.stock >= 0:
		entry.stock = max(0, entry.stock - quantity)
	item_purchased.emit(item_id, quantity, total_cost)
	var events := _get_events()
	if events != null:
		events.emit_item_purchased(current_shop.shop_id, item_id, quantity)
	return true


func sell(item_instance_id: String, quantity: int, seller: Node) -> bool:
	if current_shop == null:
		transaction_failed.emit("", "No shop open")
		return false
	if not current_shop.allow_sell:
		transaction_failed.emit("", "Shop does not buy items")
		return false
	if quantity <= 0:
		transaction_failed.emit("", "Invalid quantity")
		return false
	var inventory := _get_inventory(seller)
	if inventory == null:
		transaction_failed.emit("", "Seller has no inventory")
		return false
	var item := inventory.find_item(item_instance_id)
	if item == null:
		transaction_failed.emit("", "Item not in inventory")
		return false
	var item_id := item.definition_id
	if item.quantity < quantity:
		transaction_failed.emit(item_id, "Not enough quantity to sell")
		return false
	if _get_item_definition(item_id) == null:
		transaction_failed.emit(item_id, "Unknown item")
		return false
	var total_gain := get_sell_price(item_id) * quantity
	if not inventory.remove_item_by_instance_id(item_instance_id, quantity):
		transaction_failed.emit(item_id, "Could not remove item")
		return false
	var progression := _get_progression()
	if progression != null:
		progression.add_currency(current_shop.currency_id, total_gain)
	item_sold.emit(item_id, quantity, total_gain)
	var events := _get_events()
	if events != null:
		events.emit_item_sold(current_shop.shop_id, item_id, quantity)
	return true


func get_definition(shop_id: String) -> ShopDefinition:
	if shop_id.strip_edges() == "":
		return null
	if content == null and ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(shop_id) as ShopDefinition


func _buy_block_reason(item_id: String, quantity: int, buyer: Node) -> String:
	if current_shop == null:
		return "No shop open"
	if quantity <= 0:
		return "Invalid quantity"
	var entry := current_shop.get_entry(item_id)
	if entry == null:
		return "Item not sold here"
	if _get_item_definition(item_id) == null:
		return "Unknown item"
	if not ConditionEvaluator.evaluate_all(entry.conditions, _make_context(buyer)):
		return "Entry locked"
	if entry.stock >= 0 and entry.stock < quantity:
		return "Out of stock"
	var inventory := _get_inventory(buyer)
	if inventory == null:
		return "Buyer has no inventory"
	if not inventory.can_add_item(ItemInstance.create(item_id, quantity)):
		return "Inventory cannot accept item"
	var progression := _get_progression()
	if progression == null:
		return "Missing progression service"
	if progression.get_currency(current_shop.currency_id) < get_buy_price(item_id) * quantity:
		return "Insufficient currency"
	return ""


func _make_context(buyer: Node) -> GameplayContext:
	var ctx := GameplayContext.new()
	if buyer != null:
		ctx.source = buyer
	return ctx


func _get_inventory(node: Node) -> InventoryController:
	if node == null:
		return null
	return node.get_node_or_null("Controllers/InventoryController") as InventoryController


func _get_item_definition(item_id: String) -> ItemDefinition:
	if content == null and ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(item_id) as ItemDefinition


func _get_progression() -> ProgressionSystem:
	if ServiceRegistry.has_service("progression"):
		return ServiceRegistry.get_service("progression") as ProgressionSystem
	return null


func _get_events() -> EventRouter:
	if ServiceRegistry.has_service("events"):
		return ServiceRegistry.get_service("events") as EventRouter
	return null
