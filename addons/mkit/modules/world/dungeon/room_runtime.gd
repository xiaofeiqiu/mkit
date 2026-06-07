class_name RoomRuntime
extends RefCounted
var room_runtime_id: String = ""
var definition_id: String = ""
var cleared: bool = false
var entered: bool = false
var active_enemy_ids: Array[String] = []
var reward_options: Array[RewardOption] = []


static func create(definition_id: String, runtime_id: String = "") -> RoomRuntime:
	var r := RoomRuntime.new()
	r.room_runtime_id = runtime_id if runtime_id != "" else "room_%d" % Time.get_ticks_usec()
	r.definition_id = definition_id
	return r


func to_save_data() -> Dictionary:
	var reward_ids: Array[String] = []
	for option in reward_options:
		if option == null:
			continue
		reward_ids.append(option.reward_id)
	return {
		"room_runtime_id": room_runtime_id,
		"definition_id": definition_id,
		"cleared": cleared,
		"entered": entered,
		"active_enemy_ids": active_enemy_ids.duplicate(),
		"reward_ids": reward_ids
	}


func from_save_data(data: Dictionary) -> void:
	room_runtime_id = str(data.get("room_runtime_id", room_runtime_id))
	definition_id = str(data.get("definition_id", definition_id))
	cleared = bool(data.get("cleared", cleared))
	entered = bool(data.get("entered", entered))
	var raw_enemies := data.get("active_enemy_ids", active_enemy_ids)
	if raw_enemies is Array:
		var normalized_enemies: Array[String] = []
		for raw_enemy in raw_enemies:
			normalized_enemies.append(str(raw_enemy))
		active_enemy_ids = normalized_enemies
	else:
		active_enemy_ids = []
	reward_options = []
	for raw_reward_id in data.get("reward_ids", []):
		var option := RewardOption.new()
		option.reward_id = str(raw_reward_id)
		reward_options.append(option)
