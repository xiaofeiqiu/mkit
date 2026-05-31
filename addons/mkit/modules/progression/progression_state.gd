class_name ProgressionState
extends RefCounted

var currencies: Dictionary = {}
var upgrade_levels: Dictionary = {}
var unlocked_content_ids: Array[String] = []


func get_currency(currency_id: String) -> int:
	return int(currencies.get(currency_id, 0))


func add_currency(currency_id: String, amount: int) -> void:
	currencies[currency_id] = max(0, get_currency(currency_id) + amount)


func spend_currency(currency_id: String, amount: int) -> bool:
	if get_currency(currency_id) < amount:
		return false
	currencies[currency_id] = get_currency(currency_id) - amount
	return true


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func set_upgrade_level(upgrade_id: String, level: int) -> void:
	upgrade_levels[upgrade_id] = max(0, level)


func unlock_content(content_id: String) -> void:
	if not unlocked_content_ids.has(content_id):
		unlocked_content_ids.append(content_id)


func to_save_data() -> Dictionary:
	return {
		"currencies": currencies,
		"upgrade_levels": upgrade_levels,
		"unlocked_content_ids": unlocked_content_ids
	}


func from_save_data(data: Dictionary) -> void:
	currencies = data.get("currencies", {})
	upgrade_levels = data.get("upgrade_levels", {})
	var raw: Array = data.get("unlocked_content_ids", [])
	unlocked_content_ids.assign(raw)
