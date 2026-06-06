extends SaveMigration


func _init() -> void:
	from_version = 1
	to_version = 2


func _migrate_impl(data: Dictionary) -> Dictionary:
	var payload: Dictionary = data.get("payload", {})
	var player: Dictionary = payload.get("phase8_player", {})
	if player.is_empty():
		data["payload"] = payload
		return data
	var components: Dictionary = player.get("components", {})
	_migrate_position(player)
	_migrate_health(player, components)
	_migrate_mana(player, components)
	player["components"] = components
	payload["phase8_player"] = player
	data["payload"] = payload
	return data


func _migrate_position(player: Dictionary) -> void:
	if player.has("position"):
		return
	if not player.has("position_x") and not player.has("position_y"):
		return
	player["position"] = {
		"x": float(player.get("position_x", 0.0)),
		"y": float(player.get("position_y", 0.0))
	}
	player.erase("position_x")
	player.erase("position_y")


func _migrate_health(player: Dictionary, components: Dictionary) -> void:
	if components.has("HealthComponent") or not player.has("current_hp"):
		return
	components["HealthComponent"] = {
		"current_hp": float(player.get("current_hp", 100.0)),
		"dead": bool(player.get("dead", false))
	}
	player.erase("current_hp")
	player.erase("dead")


func _migrate_mana(player: Dictionary, components: Dictionary) -> void:
	if components.has("ResourcePoolComponent") or not player.has("mana"):
		return
	components["ResourcePoolComponent"] = {"mana": float(player.get("mana", 0.0))}
	player.erase("mana")
