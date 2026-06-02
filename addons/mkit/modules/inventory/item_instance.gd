class_name ItemInstance
extends RefCounted
var instance_id: String = ""
var definition_id: String = ""
var quantity: int = 1
var rolled_affixes: Array[StatModifier] = []
var durability: float = 1.0
var upgrade_level: int = 0
var metadata: Dictionary = {}


static func create(def_id: String, qty: int = 1) -> ItemInstance:
	var item := ItemInstance.new()
	item.instance_id = "item_%d" % Time.get_ticks_usec()
	item.definition_id = def_id
	item.quantity = qty
	return item


func to_save_data() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"quantity": quantity,
		"durability": durability,
		"upgrade_level": upgrade_level,
		"metadata": metadata
	}


static func from_save_data(data: Dictionary) -> ItemInstance:
	var item := ItemInstance.new()
	item.instance_id = str(data.get("instance_id", ""))
	item.definition_id = str(data.get("definition_id", ""))
	item.quantity = int(data.get("quantity", 1))
	item.durability = float(data.get("durability", 1.0))
	item.upgrade_level = int(data.get("upgrade_level", 0))
	item.metadata = data.get("metadata", {})
	return item
