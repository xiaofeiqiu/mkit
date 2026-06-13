class_name QuestLog
extends RefCounted
## 说明：`QuestLog` 是 任务系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在任务系统中复用这段契约或状态时使用它。
## 示例：`var instance := QuestLog.new()`

## 任务运行状态表；key 为 quest id，value 为 QuestState。
var states: Dictionary = {}


## 读取当前对象中的 `state`；未找到时返回 null、空集合或该 API 的默认值。
func get_state(quest_id: String) -> QuestState:
	return states.get(quest_id, null)


## 执行 `has` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func has(quest_id: String) -> bool:
	return states.has(quest_id)


## 读取当前对象中的 `active`；未找到时返回 null、空集合或该 API 的默认值。
func get_active() -> Array[QuestState]:
	var result: Array[QuestState] = []
	for quest_id in states:
		var state: QuestState = states[quest_id]
		if state.status == QuestState.STATUS_ACTIVE:
			result.append(state)
	return result


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
func to_save_data() -> Dictionary:
	var serialized: Dictionary = {}
	for quest_id in states:
		serialized[quest_id] = states[quest_id].to_save_data()
	return {"states": serialized}


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
func from_save_data(data: Dictionary) -> void:
	states = {}
	var raw: Dictionary = data.get("states", {})
	for quest_id in raw:
		var state := QuestState.create(quest_id)
		state.from_save_data(raw[quest_id])
		states[quest_id] = state
