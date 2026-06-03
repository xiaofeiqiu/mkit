class_name ShopUI
extends Control
var controller: ShopController = null
var buyer: Node = null


func bind(shop_controller: ShopController, shop_buyer: Node = null) -> void:
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
	for entry in controller.current_shop.entries:
		if entry == null:
			continue
		var button := Button.new()
		button.text = "%s  (%d)" % [entry.item_id, controller.get_buy_price(entry.item_id)]
		var entry_id := entry.item_id
		button.pressed.connect(func(): controller.buy(entry_id, 1, buyer))
		container.add_child(button)


func close() -> void:
	if controller != null:
		controller.close_shop()
	queue_free()
