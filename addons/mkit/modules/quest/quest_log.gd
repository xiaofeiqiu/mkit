class_name QuestLog
extends RefCounted
var states: Dictionary = {}


func get_state(quest_id: String) -> QuestState:
	return states.get(quest_id, null)


func has(quest_id: String) -> bool:
	return states.has(quest_id)


func get_active() -> Array[QuestState]:
	var result: Array[QuestState] = []
	for quest_id in states:
		var state: QuestState = states[quest_id]
		if state.status == "active":
			result.append(state)
	return result


func to_save_data() -> Dictionary:
	var serialized: Dictionary = {}
	for quest_id in states:
		serialized[quest_id] = states[quest_id].to_save_data()
	return {"states": serialized}


func from_save_data(data: Dictionary) -> void:
	states = {}
	var raw: Dictionary = data.get("states", {})
	for quest_id in raw:
		var state := QuestState.create(quest_id)
		state.from_save_data(raw[quest_id])
		states[quest_id] = state
