class_name InventorySlot
extends RefCounted

var index: int = -1
var item: ItemInstance = null


func is_empty() -> bool:
	return item == null


func clear() -> void:
	item = null
