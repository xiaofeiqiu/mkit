class_name RoomRuntime
extends RefCounted
var room_runtime_id: String = ""
var definition_id: String = ""
var cleared: bool = false
var entered: bool = false
var active_enemy_ids: Array[String] = []
var reward_options: Array[RewardOption] = []


static func create(definition_id: String) -> RoomRuntime:
	var r := RoomRuntime.new()
	r.room_runtime_id = "room_%d" % Time.get_ticks_usec()
	r.definition_id = definition_id
	return r
