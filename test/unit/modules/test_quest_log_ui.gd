extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


const QUEST_LOG_UI_SCRIPT := preload("res://addons/mkit/modules/ui/quest_log_ui.gd")

var content: StubContent
var events: EventService
var effects: EffectService
var quest: QuestService
var ui: Control = null
var container: VBoxContainer
var empty_label: Label


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	events = EventService.new()
	add_child_autofree(events)
	effects = EffectService.new()
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("effects", effects)
	quest = QuestService.new()
	add_child_autofree(quest)
	ServiceRegistry.register_service("quest", quest)
	ui = QUEST_LOG_UI_SCRIPT.new() as Control
	container = VBoxContainer.new()
	container.name = "QuestContainer"
	ui.add_child(container)
	empty_label = Label.new()
	empty_label.name = "EmptyLabel"
	ui.add_child(empty_label)
	add_child_autofree(ui)


func after_each() -> void:
	ServiceRegistry.clear()


func test_tc_qlui_01_bind_renders_empty_and_refreshes_from_quest_signals() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [
		_make_objective("obj.collect", "Collect samples", 3)
	]
	_make_quest("quest.alpha", "Alpha Quest", objectives)

	ui.call("bind", quest)
	assert_true(empty_label.visible)
	assert_eq(container.get_child_count(), 0)

	assert_true(quest.accept_quest("quest.alpha", null))
	assert_false(empty_label.visible)
	assert_eq(container.get_child_count(), 1)
	assert_eq(_label_text(0, "TitleLabel"), "Alpha Quest")
	assert_eq(_label_text(0, "StatusLabel"), "Status: active")
	assert_eq(_label_text(0, "Objective_obj_collect"), "Collect samples 0/3")

	assert_true(quest.advance_objective("quest.alpha", "obj.collect", 2))
	assert_eq(_label_text(0, "Objective_obj_collect"), "Collect samples 2/3")

	assert_true(quest.advance_objective("quest.alpha", "obj.collect", 1))
	assert_true(quest.complete_quest("quest.alpha", null))
	assert_eq(_label_text(0, "StatusLabel"), "Status: completed")

	assert_true(quest.turn_in_quest("quest.alpha", null))
	assert_eq(_label_text(0, "StatusLabel"), "Status: turned_in")
	await get_tree().process_frame


func test_tc_qlui_02_refresh_sorts_states_and_falls_back_to_quest_id() -> void:
	var objectives: Array[QuestObjectiveDefinition] = []
	_make_quest("quest.alpha", "Alpha Quest", objectives)
	var missing := QuestState.create("quest.missing")
	missing.status = "active"
	quest.log.states["quest.missing"] = missing
	var alpha := QuestState.create("quest.alpha")
	alpha.status = "completed"
	quest.log.states["quest.alpha"] = alpha

	ui.call("bind", quest)
	assert_eq(container.get_child_count(), 2)
	assert_eq(_label_text(0, "TitleLabel"), "Alpha Quest")
	assert_eq(_label_text(1, "TitleLabel"), "quest.missing")
	assert_eq(_label_text(1, "StatusLabel"), "Status: active")


func test_tc_qlui_03_bind_with_missing_container_is_safe() -> void:
	var bare := QUEST_LOG_UI_SCRIPT.new() as Control
	add_child_autofree(bare)
	bare.call("bind", quest)
	assert_true(is_instance_valid(bare))


func test_tc_qlui_04_repeatable_turn_in_renders_final_reset_state() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [
		_make_objective("obj.repeat", "Repeat step", 1)
	]
	var definition := _make_quest("quest.repeat", "Repeat Quest", objectives)
	definition.repeatable = true

	ui.call("bind", quest)
	assert_true(quest.accept_quest("quest.repeat", null))
	assert_true(quest.advance_objective("quest.repeat", "obj.repeat", 1))
	assert_true(quest.complete_quest("quest.repeat", null))
	assert_eq(_label_text(0, "StatusLabel"), "Status: completed")

	assert_true(quest.turn_in_quest("quest.repeat", null))
	assert_eq(quest.get_state("quest.repeat").status, "available")
	assert_eq(_label_text(0, "StatusLabel"), "Status: available")
	assert_eq(_label_text(0, "Objective_obj_repeat"), "Repeat step 0/1")
	await get_tree().process_frame


func _make_objective(
	objective_id: String, description: String, required_count: int
) -> QuestObjectiveDefinition:
	var objective := QuestObjectiveDefinition.new()
	objective.objective_id = objective_id
	objective.description = description
	objective.required_count = required_count
	return objective


func _make_quest(
	quest_id: String, display_name: String, objectives: Array[QuestObjectiveDefinition]
) -> QuestDefinition:
	var definition := QuestDefinition.new()
	definition.quest_id = quest_id
	definition.display_name = display_name
	definition.objectives = objectives
	content._defs[quest_id] = definition
	return definition


func _label_text(row_index: int, node_name: String) -> String:
	var row := container.get_child(row_index)
	var label := row.get_node(node_name) as Label
	return label.text
