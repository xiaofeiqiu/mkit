class_name RoomRuntime
extends RefCounted
## 说明：`RoomRuntime` 是 房间与一局流程系统 的运行时模型，负责保存当前流程执行中的临时状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RoomRuntime.new()`

## 房间运行实例 id；用于区分同一 RoomDefinition 的多次出现。
var room_runtime_id: String = ""
## 该房间实例来源的 RoomDefinition id；恢复和调试时用它回查静态配置。
var definition_id: String = ""
## 房间是否已清场；清场后通常允许选择奖励或前往下个房间。
var cleared: bool = false
## 玩家是否已经进入过该房间实例。
var entered: bool = false
## 当前房间仍活跃的敌人实体 id 列表。
var active_enemy_ids: Array[String] = []
## 当前房间可选择的奖励选项列表。
var reward_options: Array[RewardOption] = []


## 创建并返回新的运行时对象，并保持 `RoomRuntime` 的领域契约一致。
static func create(definition_id: String, runtime_id: String = "") -> RoomRuntime:
	var r := RoomRuntime.new()
	r.room_runtime_id = runtime_id if runtime_id != "" else "room_%d" % Time.get_ticks_usec()
	r.definition_id = definition_id
	return r


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `RoomRuntime` 的领域契约一致。
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


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `RoomRuntime` 的领域契约一致。
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
