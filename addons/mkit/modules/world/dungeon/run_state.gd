class_name RunState
extends RefCounted
## 说明：`RunState` 是 房间与一局流程系统 的运行时状态，负责保存可序列化或可推进的领域状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RunState.new()`

## 本局运行实例 id；用于存档、日志和随机过程追踪。
var run_id: String = ""
## 本局随机种子；相同种子应生成可复现的房间和奖励序列。
var seed: int = 0
## 本局包含的房间或楼层数量。
var run_length: int = 0
## 第一层可抽取的 RoomDefinition id 列表。
var first_floor_room_pool: Array[String] = []
## 当前楼层或房间序号；从 1 开始。
var current_floor: int = 1
## 当前房间在本局路线中的索引；从 0 开始。
var current_room_index: int = 0
## 当前房间运行实例 id 或定义 id；由 RunDirector 切换房间时更新。
var current_room_id: String = ""
## 本局已进行时间，单位为秒。
var elapsed_time: float = 0.0
## 本局内临时获得的升级 id 列表；结束本局后通常清空。
var temporary_upgrade_ids: Array[String] = []
## 本局内临时货币表；key 为 currency id，value 为数量。
var run_currency: Dictionary = {}
## 敌人强度缩放等级；房间推进时可递增。
var enemy_scaling_level: int = 1
## 本局已经进入过的房间 id 列表。
var room_history: Array[String] = []
## 本局已经选择或生成过的奖励 id 列表。
var reward_history: Array[String] = []
## 本局随机数状态快照；用于保存和恢复可复现随机序列。
var rng_state: Dictionary = {}
## 本局当前状态字符串；应使用 not_started、running、completed 等约定值。
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
