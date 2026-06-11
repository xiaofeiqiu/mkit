class_name QuestState
extends RefCounted
## 说明：`QuestState` 是 任务系统 的运行时状态，负责保存可序列化或可推进的领域状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在任务系统中复用这段契约或状态时使用它。
## 示例：`var instance := QuestState.new()`

## 公开常量 `STATUS_AVAILABLE`，作为 `QuestState` 对外暴露的类型、事件或命令标识。
const STATUS_AVAILABLE: String = "available"
## 公开常量 `STATUS_ACTIVE`，作为 `QuestState` 对外暴露的类型、事件或命令标识。
const STATUS_ACTIVE: String = "active"
## 公开常量 `STATUS_COMPLETED`，作为 `QuestState` 对外暴露的类型、事件或命令标识。
const STATUS_COMPLETED: String = "completed"
## 公开常量 `STATUS_TURNED_IN`，作为 `QuestState` 对外暴露的类型、事件或命令标识。
const STATUS_TURNED_IN: String = "turned_in"
## 运行时状态：`quest_id` 表示稳定 id，由 `QuestState` 的公开 API 读取或维护。
var quest_id: String = ""
## 运行时状态：`status` 表示 `QuestState` 的字段值，由 `QuestState` 的公开 API 读取或维护。
var status: String = STATUS_AVAILABLE
## 运行时状态：`objective_progress` 表示 `QuestState` 的字段值，由 `QuestState` 的公开 API 读取或维护。
var objective_progress: Dictionary = {}


## 创建并返回新的运行时对象，并保持 `QuestState` 的领域契约一致。
static func create(quest_id: String) -> QuestState:
	var state := QuestState.new()
	state.quest_id = quest_id
	return state


## 返回 `progress` 对应的数据或对象，并保持 `QuestState` 的领域契约一致。
func get_progress(objective_id: String) -> int:
	return int(objective_progress.get(objective_id, 0))


## 设置 `progress` 对应的数据或对象，并保持 `QuestState` 的领域契约一致。
func set_progress(objective_id: String, value: int) -> void:
	objective_progress[objective_id] = max(0, value)


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `QuestState` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {
		"quest_id": quest_id,
		"status": status,
		"objective_progress": objective_progress.duplicate(true)
	}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `QuestState` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	quest_id = str(data.get("quest_id", quest_id))
	status = str(data.get("status", status))
	objective_progress = {}
	var raw: Dictionary = data.get("objective_progress", {})
	for key in raw:
		objective_progress[key] = int(raw[key])
