class_name QuestLogUI
extends Control
var quest_system: QuestService = null


func bind(system: QuestService) -> void:
	if quest_system != null and quest_system != system:
		_disconnect_quest_system(quest_system)
	quest_system = system
	if quest_system != null:
		_connect_quest_system(quest_system)
	refresh()


func refresh() -> void:
	var container := get_node_or_null("QuestContainer")
	if container == null:
		return
	_clear_container(container)
	var states := _get_sorted_states()
	_set_empty_visible(states.is_empty())
	for state in states:
		_render_state(container, state)


func _connect_quest_system(system: QuestService) -> void:
	if not system.quest_accepted.is_connected(_on_quest_changed):
		system.quest_accepted.connect(_on_quest_changed)
	if not system.objective_advanced.is_connected(_on_objective_advanced):
		system.objective_advanced.connect(_on_objective_advanced)
	if not system.quest_completed.is_connected(_on_quest_changed):
		system.quest_completed.connect(_on_quest_changed)
	if not system.quest_turned_in.is_connected(_on_quest_changed):
		system.quest_turned_in.connect(_on_quest_changed)


func _disconnect_quest_system(system: QuestService) -> void:
	if system.quest_accepted.is_connected(_on_quest_changed):
		system.quest_accepted.disconnect(_on_quest_changed)
	if system.objective_advanced.is_connected(_on_objective_advanced):
		system.objective_advanced.disconnect(_on_objective_advanced)
	if system.quest_completed.is_connected(_on_quest_changed):
		system.quest_completed.disconnect(_on_quest_changed)
	if system.quest_turned_in.is_connected(_on_quest_changed):
		system.quest_turned_in.disconnect(_on_quest_changed)


func _on_quest_changed(_quest_id: String) -> void:
	refresh()


func _on_objective_advanced(
	_quest_id: String, _objective_id: String, _current: int, _required: int
) -> void:
	refresh()


func _get_sorted_states() -> Array[QuestState]:
	var states: Array[QuestState] = []
	if quest_system == null:
		return states
	var quest_ids := quest_system.log.states.keys()
	quest_ids.sort()
	for quest_id in quest_ids:
		var state := quest_system.log.states[quest_id] as QuestState
		if state != null:
			states.append(state)
	return states


func _render_state(container: Node, state: QuestState) -> void:
	var definition: QuestDefinition = null
	if quest_system != null:
		definition = quest_system.get_definition(state.quest_id)
	var row := VBoxContainer.new()
	row.name = _safe_node_name("Quest_", state.quest_id)
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = _quest_title(state, definition)
	row.add_child(title)
	var status := Label.new()
	status.name = "StatusLabel"
	status.text = "Status: %s" % state.status
	row.add_child(status)
	if definition != null:
		for objective in definition.objectives:
			if objective == null:
				continue
			var objective_label := Label.new()
			objective_label.name = _safe_node_name("Objective_", objective.objective_id)
			objective_label.text = _objective_text(state, objective)
			row.add_child(objective_label)
	container.add_child(row)


func _quest_title(state: QuestState, definition: QuestDefinition) -> String:
	if definition != null and definition.display_name != "":
		return definition.display_name
	return state.quest_id


func _objective_text(state: QuestState, objective: QuestObjectiveDefinition) -> String:
	var label := objective.description
	if label == "":
		label = objective.objective_id
	var current := state.get_progress(objective.objective_id)
	return "%s %d/%d" % [label, current, objective.required_count]


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _set_empty_visible(is_empty: bool) -> void:
	var empty := get_node_or_null("EmptyLabel") as CanvasItem
	if empty != null:
		empty.visible = is_empty


func _safe_node_name(prefix: String, id: String) -> String:
	return "%s%s" % [prefix, id.replace(".", "_").replace("/", "_").replace(":", "_")]
