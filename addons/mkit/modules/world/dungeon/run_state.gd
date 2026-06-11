class_name RunState
extends RefCounted
## 说明：`RunState` 是 房间与一局流程系统 的运行时状态，负责保存可序列化或可推进的领域状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RunState.new()`

## 运行时状态：`run_id` 表示稳定 id，由 `RunState` 的公开 API 读取或维护。
var run_id: String = ""
## 运行时状态：`seed` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var seed: int = 0
## 运行时状态：`run_length` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var run_length: int = 0
## 运行时状态：`first_floor_room_pool` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var first_floor_room_pool: Array[String] = []
## 运行时状态：`current_floor` 表示当前值，由 `RunState` 的公开 API 读取或维护。
var current_floor: int = 1
## 运行时状态：`current_room_index` 表示当前值，由 `RunState` 的公开 API 读取或维护。
var current_room_index: int = 0
## 运行时状态：`current_room_id` 表示稳定 id，由 `RunState` 的公开 API 读取或维护。
var current_room_id: String = ""
## 运行时状态：`elapsed_time` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var elapsed_time: float = 0.0
## 运行时状态：`temporary_upgrade_ids` 表示稳定 id 列表，由 `RunState` 的公开 API 读取或维护。
var temporary_upgrade_ids: Array[String] = []
## 运行时状态：`run_currency` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var run_currency: Dictionary = {}
## 运行时状态：`enemy_scaling_level` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var enemy_scaling_level: int = 1
## 运行时状态：`room_history` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var room_history: Array[String] = []
## 运行时状态：`reward_history` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var reward_history: Array[String] = []
## 运行时状态：`rng_state` 表示运行时状态，由 `RunState` 的公开 API 读取或维护。
var rng_state: Dictionary = {}
## 运行时状态：`status` 表示 `RunState` 的字段值，由 `RunState` 的公开 API 读取或维护。
var status: String = "not_started"


## 创建并返回新的运行时对象，并保持 `RunState` 的领域契约一致。
static func create(seed_value: int) -> RunState:
	var s := RunState.new()
	s.run_id = "run_%d" % Time.get_ticks_usec()
	s.seed = seed_value
	return s


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `RunState` 的领域契约一致。
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


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `RunState` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	run_id = str(data.get("run_id", run_id))
	seed = int(data.get("seed", seed))
	run_length = int(data.get("run_length", run_length))
	current_floor = int(data.get("current_floor", current_floor))
	current_room_index = int(data.get("current_room_index", current_room_index))
	current_room_id = str(data.get("current_room_id", current_room_id))
	elapsed_time = float(data.get("elapsed_time", elapsed_time))
	temporary_upgrade_ids = _coerce_string_array(
		data.get("temporary_upgrade_ids", temporary_upgrade_ids),
		temporary_upgrade_ids
	)
	run_currency = (data.get("run_currency", run_currency)).duplicate(true)
	enemy_scaling_level = int(data.get("enemy_scaling_level", enemy_scaling_level))
	room_history = _coerce_string_array(
		data.get("room_history", room_history),
		room_history
	)
	reward_history = _coerce_string_array(
		data.get("reward_history", reward_history),
		reward_history
	)
	rng_state = (data.get("rng_state", rng_state)).duplicate(true)
	status = str(data.get("status", status))
	var pool := data.get("first_floor_room_pool", [])
	var normalized_pool: Array[String] = []
	if pool is Array:
		for raw in pool:
			normalized_pool.append(str(raw))
		first_floor_room_pool = normalized_pool


func _coerce_string_array(raw: Variant, fallback: Array[String]) -> Array[String]:
	if not (raw is Array):
		return fallback.duplicate()
	var values: Array[String] = []
	for raw_value in raw:
		values.append(str(raw_value))
	return values
