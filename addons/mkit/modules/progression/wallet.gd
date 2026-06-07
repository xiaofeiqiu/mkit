class_name Wallet
extends RefCounted
var balances: Dictionary = {}


func get_balance(currency_id: String) -> int:
	return int(balances.get(currency_id, 0))


func set_balance(currency_id: String, amount: int) -> void:
	balances[currency_id] = max(0, amount)


func add(currency_id: String, amount: int) -> void:
	if currency_id.strip_edges() == "":
		return
	set_balance(currency_id, get_balance(currency_id) + amount)


func can_spend(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	return get_balance(currency_id) >= amount


func spend(currency_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_spend(currency_id, amount):
		return false
	set_balance(currency_id, get_balance(currency_id) - amount)
	return true


func to_save_data() -> Dictionary:
	return balances.duplicate(true)


func from_save_data(data: Dictionary) -> void:
	balances = data.duplicate(true)
