class_name ShopDefinition
extends ContentDefinition
@export var shop_id: String = ""
@export var display_name: String = ""
@export var currency_id: String = "gold"
@export var entries: Array[ShopEntry] = []
@export var buy_price_multiplier: float = 1.0
@export var sell_price_multiplier: float = 0.5
@export var allow_sell: bool = true


func get_content_id() -> String:
	return shop_id


func get_entry(item_id: String) -> ShopEntry:
	for entry in entries:
		if entry != null and entry.item_id == item_id:
			return entry
	return null
