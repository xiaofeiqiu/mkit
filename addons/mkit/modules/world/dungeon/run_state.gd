class_name RunState
extends RefCounted
var run_id: String = ""
var seed: int = 0
var run_length: int = 0
var first_floor_room_pool: Array[String] = []
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
		"run_length": run_length,
		"first_floor_room_pool": first_floor_room_pool,
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


func from_save_data(data: Dictionary) -> void:
	run_id = str(data.get("run_id", run_id))
	seed = int(data.get("seed", seed))
	run_length = int(data.get("run_length", run_length))
	current_floor = int(data.get("current_floor", current_floor))
	current_room_index = int(data.get("current_room_index", current_room_index))
	current_room_id = str(data.get("current_room_id", current_room_id))
	elapsed_time = float(data.get("elapsed_time", elapsed_time))
	temporary_upgrade_ids = Array(data.get("temporary_upgrade_ids", temporary_upgrade_ids)).duplicate()
	run_currency = (data.get("run_currency", run_currency)).duplicate(true)
	enemy_scaling_level = int(data.get("enemy_scaling_level", enemy_scaling_level))
	room_history = Array(data.get("room_history", room_history)).duplicate()
	reward_history = Array(data.get("reward_history", reward_history)).duplicate()
	rng_state = (data.get("rng_state", rng_state)).duplicate(true)
	status = str(data.get("status", status))
	var pool := data.get("first_floor_room_pool", [])
	var normalized_pool: Array[String] = []
	if pool is Array:
		for raw in pool:
			normalized_pool.append(str(raw))
		first_floor_room_pool = normalized_pool
