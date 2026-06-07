class_name ProgressionState
extends RefCounted
var wallet: Wallet = Wallet.new()
var upgrade_levels: Dictionary = {}
var unlocked_content_ids: Array[String] = []


func get_currency(currency_id: String) -> int:
	return wallet.get_balance(currency_id)


func add_currency(currency_id: String, amount: int) -> void:
	wallet.add(currency_id, amount)


func spend_currency(currency_id: String, amount: int) -> bool:
	if not wallet.can_spend(currency_id, amount):
		return false
	wallet.spend(currency_id, amount)
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
		"currencies": wallet.to_save_data(),
		"upgrade_levels": upgrade_levels,
		"unlocked_content_ids": unlocked_content_ids
	}


func from_save_data(data: Dictionary) -> void:
	var raw_currencies := data.get("currencies", {})
	if raw_currencies is Dictionary:
		wallet.from_save_data(raw_currencies)
	upgrade_levels = data.get("upgrade_levels", {})
	var raw: Array = data.get("unlocked_content_ids", [])
	unlocked_content_ids.assign(raw)
