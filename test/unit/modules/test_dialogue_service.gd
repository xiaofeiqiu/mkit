extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class PassingCondition:
	extends Condition

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return true


class FailingCondition:
	extends Condition

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return false


class CountingEffect:
	extends GameEffect
	var runs: int = 0
	var contexts: Array = []

	func _apply_impl(context: GameplayContext) -> EffectResult:
		runs += 1
		contexts.append(context)
		return EffectResult.ok(effect_id)


var dialogue: DialogueService
var content: StubContent
var events: EventService
var effects: EffectService


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	events = EventService.new()
	add_child_autofree(events)
	effects = EffectService.new()
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("effects", effects)
	dialogue = DialogueService.new()
	add_child_autofree(dialogue)
	ServiceRegistry.register_service("dialogue", dialogue)


func after_each() -> void:
	ServiceRegistry.clear()


# --- helpers ---


func _make_choice(
	text: String,
	next_node_id: String,
	conditions: Array[Condition] = [],
	effects_list: Array[GameEffect] = []
) -> DialogueChoice:
	var choice := DialogueChoice.new()
	choice.text = text
	choice.next_node_id = next_node_id
	choice.conditions = conditions
	choice.effects = effects_list
	return choice


func _make_node(
	node_id: String,
	text: String = "",
	next_node_id: String = "",
	choices: Array[DialogueChoice] = [],
	on_enter: Array[GameEffect] = []
) -> DialogueNode:
	var node := DialogueNode.new()
	node.node_id = node_id
	node.text = text
	node.next_node_id = next_node_id
	node.choices = choices
	node.on_enter_effects = on_enter
	return node


func _make_dialogue(
	dialogue_id: String, start_node_id: String, nodes: Array[DialogueNode]
) -> DialogueDefinition:
	var definition := DialogueDefinition.new()
	definition.dialogue_id = dialogue_id
	definition.start_node_id = start_node_id
	definition.nodes = nodes
	content._defs[dialogue_id] = definition
	return definition


# --- start enters start node + runs on_enter_effects + emits events ---


func test_tc_dlg_01_start_enters_start_node_and_runs_enter_effects() -> void:
	# unknown dialogue id is rejected and creates no session
	assert_false(dialogue.start("dlg.unknown", null))
	assert_false(dialogue.is_active())

	var enter_fx := CountingEffect.new()
	var on_enter: Array[GameEffect] = [enter_fx]
	var node := _make_node("n.start", "Welcome traveler", "", [], on_enter)
	var nodes: Array[DialogueNode] = [node]
	_make_dialogue("dlg.intro", "n.start", nodes)

	watch_signals(dialogue)
	watch_signals(events)
	var ctx := GameplayContext.new()
	assert_true(dialogue.start("dlg.intro", ctx))
	assert_true(dialogue.is_active())
	assert_eq(dialogue.runtime.current_node_id, "n.start")
	assert_eq(dialogue.runtime.history, ["n.start"] as Array[String])
	assert_eq(enter_fx.runs, 1)
	assert_eq(enter_fx.contexts[0], ctx)
	assert_signal_emitted_with_parameters(dialogue, "dialogue_started", ["dlg.intro"])
	assert_signal_emitted(dialogue, "node_entered")
	assert_signal_emitted_with_parameters(events, "dialogue_started", ["dlg.intro"])


# --- choices filtered by conditions ---


func test_tc_dlg_02_choices_filtered_by_conditions() -> void:
	var blocked: Array[Condition] = [FailingCondition.new()]
	var open: Array[Condition] = [PassingCondition.new()]
	var c_blocked := _make_choice("Locked option", "n.b", blocked)
	var c_open := _make_choice("Open option", "n.a", open)
	var c_plain := _make_choice("Always", "n.c")
	var choices: Array[DialogueChoice] = [c_blocked, c_open, c_plain]
	var hub := _make_node("n.hub", "Pick one", "", choices)
	var nodes: Array[DialogueNode] = [hub, _make_node("n.a"), _make_node("n.b"), _make_node("n.c")]
	_make_dialogue("dlg.branch", "n.hub", nodes)

	watch_signals(dialogue)
	assert_true(dialogue.start("dlg.branch", GameplayContext.new()))
	var available := dialogue.get_available_choices()
	assert_eq(available.size(), 2)
	assert_eq(available[0].text, "Open option")
	assert_eq(available[1].text, "Always")
	assert_signal_emitted(dialogue, "choices_presented")


# --- choose runs effects and advances to next node ---


func test_tc_dlg_03_choose_runs_effects_and_advances() -> void:
	var pick_fx := CountingEffect.new()
	var fx_list: Array[GameEffect] = [pick_fx]
	var skip: Array[Condition] = []
	var c1 := _make_choice("Accept", "n.after", skip, fx_list)
	var choices: Array[DialogueChoice] = [c1]
	var hub := _make_node("n.hub", "Will you help?", "", choices)
	var after := _make_node("n.after", "Thank you", "")
	var nodes: Array[DialogueNode] = [hub, after]
	_make_dialogue("dlg.help", "n.hub", nodes)

	dialogue.start("dlg.help", GameplayContext.new())
	watch_signals(dialogue)
	dialogue.choose(0)
	assert_eq(pick_fx.runs, 1)
	assert_eq(dialogue.runtime.current_node_id, "n.after")
	assert_signal_emitted(dialogue, "node_entered")

	# out-of-range index is a safe no-op
	dialogue.choose(5)
	assert_eq(dialogue.runtime.current_node_id, "n.after")
	assert_eq(pick_fx.runs, 1)


# --- linear advance walks nodes until end emits dialogue_ended ---


func test_tc_dlg_04_linear_advance_until_end_emits_ended() -> void:
	var n1 := _make_node("n1", "Line one", "n2")
	var n2 := _make_node("n2", "Line two", "n3")
	var n3 := _make_node("n3", "Final line", "")
	var nodes: Array[DialogueNode] = [n1, n2, n3]
	_make_dialogue("dlg.linear", "n1", nodes)

	watch_signals(dialogue)
	watch_signals(events)
	dialogue.start("dlg.linear", GameplayContext.new())
	assert_eq(dialogue.runtime.current_node_id, "n1")
	dialogue.advance()
	assert_eq(dialogue.runtime.current_node_id, "n2")
	dialogue.advance()
	assert_eq(dialogue.runtime.current_node_id, "n3")
	dialogue.advance()
	assert_false(dialogue.is_active())
	assert_signal_emitted_with_parameters(dialogue, "dialogue_ended", ["dlg.linear"])
	assert_signal_emitted_with_parameters(events, "dialogue_ended", ["dlg.linear"])

	# advancing with no active session is a safe no-op
	dialogue.advance()
	assert_false(dialogue.is_active())


# --- second start rejected while a dialogue is active ---


func test_tc_dlg_05_second_start_rejected_while_active() -> void:
	var node_a := _make_node("n.start", "Hello", "")
	var nodes_a: Array[DialogueNode] = [node_a]
	_make_dialogue("dlg.a", "n.start", nodes_a)
	var node_b := _make_node("n.start", "Other", "")
	var nodes_b: Array[DialogueNode] = [node_b]
	_make_dialogue("dlg.b", "n.start", nodes_b)

	assert_true(dialogue.start("dlg.a", GameplayContext.new()))
	watch_signals(dialogue)
	assert_false(dialogue.start("dlg.b", GameplayContext.new()))
	assert_eq(dialogue.runtime.dialogue_id, "dlg.a")
	assert_signal_not_emitted(dialogue, "dialogue_started")

	# after ending, a new dialogue can start
	dialogue.end()
	assert_false(dialogue.is_active())
	assert_true(dialogue.start("dlg.b", GameplayContext.new()))
	assert_eq(dialogue.runtime.dialogue_id, "dlg.b")


# --- a definition whose start_node_id is invalid reports failure (start -> immediate end) ---


func test_tc_dlg_06_invalid_start_node_reports_failure() -> void:
	var node := _make_node("n.real", "Hello", "")
	var nodes: Array[DialogueNode] = [node]
	_make_dialogue("dlg.broken", "n.missing", nodes)

	watch_signals(dialogue)
	watch_signals(events)
	assert_false(dialogue.start("dlg.broken", GameplayContext.new()))
	assert_false(dialogue.is_active())
	assert_signal_emitted_with_parameters(dialogue, "dialogue_started", ["dlg.broken"])
	assert_signal_emitted_with_parameters(dialogue, "dialogue_ended", ["dlg.broken"])
	assert_signal_emitted_with_parameters(events, "dialogue_ended", ["dlg.broken"])
