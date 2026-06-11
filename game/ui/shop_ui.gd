class_name ShopUI
extends Control
var controller: ShopService = null
var buyer: Node = null


func bind(shop_controller: ShopService, shop_buyer: Node = null) -> void:
	controller = shop_controller
	buyer = shop_buyer
	if controller != null:
		if not controller.shop_opened.is_connected(_on_shop_changed):
			controller.shop_opened.connect(_on_shop_changed)
		if not controller.item_purchased.is_connected(_on_item_purchased):
			controller.item_purchased.connect(_on_item_purchased)
		if not controller.item_sold.is_connected(_on_item_sold):
			controller.item_sold.connect(_on_item_sold)
	_render()


func _on_shop_changed(_shop_id: String) -> void:
	_render()


func _on_item_purchased(_item_id: String, _quantity: int, _total_cost: int) -> void:
	_render()


func _on_item_sold(_item_id: String, _quantity: int, _total_gain: int) -> void:
	_render()


func _render() -> void:
	var container := get_node_or_null("EntryContainer")
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	if controller == null or controller.current_shop == null:
		return
	for i in range(controller.current_shop.entries.size()):
		var entry := controller.current_shop.entries[i]
		if entry == null:
			continue
		var button := Button.new()
		button.text = "%sBuy %s - %d %s" % [
			"B / click: " if i == 0 else "",
			_item_name(entry.item_id),
			controller.get_buy_price(entry.item_id),
			controller.current_shop.currency_id
		]
		var entry_id := entry.item_id
		button.pressed.connect(func(): controller.buy(entry_id, 1, buyer))
		container.add_child(button)
	_render_sell_buttons(container)


func close() -> void:
	if controller != null:
		controller.close_shop()
	queue_free()


func _render_sell_buttons(container: Node) -> void:
	if controller == null or controller.current_shop == null or not controller.current_shop.allow_sell:
		return
	var inventory := EntityContract.get_controller(buyer, "InventoryController") as InventoryController
	if inventory == null:
		return
	var rendered := 0
	for item in inventory.model.get_items():
		var price := controller.get_sell_price(item.definition_id)
		if price <= 0:
			continue
		var button := Button.new()
		button.text = "%sSell %s - %d %s" % [
			"V / click: " if rendered == 0 else "",
			_item_name(item.definition_id),
			price,
			controller.current_shop.currency_id
		]
		var instance_id := item.instance_id
		button.pressed.connect(func(): controller.sell(instance_id, 1, buyer))
		container.add_child(button)
		rendered += 1


func _item_name(item_id: String) -> String:
	var content := Mkit.content()
	if content == null:
		return item_id
	var definition := content.get_resource(item_id) as ItemDefinition
	if definition != null and definition.display_name != "":
		return definition.display_name
	return item_id
