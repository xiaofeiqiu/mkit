class_name RunState
extends RefCounted

var run_id: String = ""
var seed: int = 0
var current_floor: int = 1
var current_room_index: int = 0
var current_room_id: String = ""
var elapsed_time: float = 0.0
var temporary_upgrade_ids: Array[String] = []
var run_currency: Dictionary = {}
var enemy_scaling_level: int = 1
var room_history: Array[String] = []
var reward_history: Array[String] = []
var rng_state: Dictionary = {}
var status: String = "not_started"

static func create(seed_value: int) -> RunState:
	var s := RunState.new()
	s.run_id = "run_%d" % Time.get_ticks_usec()
	s.seed = seed_value
	return s

func to_save_data() -> Dictionary:
	return {
		"run_id": run_id,
		"seed": seed,
		"current_floor": current_floor,
		"current_room_index": current_room_index,
		"current_room_id": current_room_id,
		"elapsed_time": elapsed_time,
		"temporary_upgrade_ids": temporary_upgrade_ids,
		"run_currency": run_currency,
		"enemy_scaling_level": enemy_scaling_level,
		"room_history": room_history,
		"reward_history": reward_history,
		"rng_state": rng_state,
		"status": status
	}
