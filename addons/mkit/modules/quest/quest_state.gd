class_name QuestState
extends RefCounted
var quest_id: String = ""
var status: String = "available"
var objective_progress: Dictionary = {}


static func create(quest_id: String) -> QuestState:
	var state := QuestState.new()
	state.quest_id = quest_id
	return state


func get_progress(objective_id: String) -> int:
	return int(objective_progress.get(objective_id, 0))


func set_progress(objective_id: String, value: int) -> void:
	objective_progress[objective_id] = max(0, value)


func to_save_data() -> Dictionary:
	return {
		"quest_id": quest_id,
		"status": status,
		"objective_progress": objective_progress.duplicate(true)
	}


func from_save_data(data: Dictionary) -> void:
	quest_id = str(data.get("quest_id", quest_id))
	status = str(data.get("status", status))
	objective_progress = {}
	var raw: Dictionary = data.get("objective_progress", {})
	for key in raw:
		objective_progress[key] = int(raw[key])
