class_name DialogueService
extends Node
signal dialogue_started(dialogue_id: String)
signal node_entered(node: DialogueNode)
signal choices_presented(node: DialogueNode, available: Array[DialogueChoice])
signal dialogue_ended(dialogue_id: String)
var runtime: DialogueRuntime = null


func is_active() -> bool:
	return runtime != null


func start(dialogue_id: String, context: GameplayContext) -> bool:
	if is_active():
		return false
	var definition := get_definition(dialogue_id)
	if definition == null:
		return false
	runtime = DialogueRuntime.new()
	runtime.dialogue_id = dialogue_id
	runtime.context = GameplayContext.from_context(context)
	dialogue_started.emit(dialogue_id)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(DialogueEvents.dialogue_started(dialogue_id))
	_enter_node(definition.start_node_id)
	return is_active()


func get_available_choices() -> Array[DialogueChoice]:
	var available: Array[DialogueChoice] = []
	var node := _current_node()
	if node == null:
		return available
	for choice in node.choices:
		if choice == null:
			continue
		if ConditionEvaluator.evaluate_all(choice.conditions, runtime.context):
			available.append(choice)
	return available


func choose(choice_index: int) -> void:
	if runtime == null:
		return
	var available := get_available_choices()
	if choice_index < 0 or choice_index >= available.size():
		return
	var choice := available[choice_index]
	_run_effects(choice.effects)
	if runtime == null:
		return
	if choice.next_node_id == "":
		end()
		return
	_enter_node(choice.next_node_id)


func advance() -> void:
	if runtime == null:
		return
	var node := _current_node()
	if node == null:
		end()
		return
	if not node.choices.is_empty():
		return
	if node.next_node_id == "":
		end()
		return
	_enter_node(node.next_node_id)


func end() -> void:
	if runtime == null:
		return
	var ended_id := runtime.dialogue_id
	runtime = null
	dialogue_ended.emit(ended_id)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(DialogueEvents.dialogue_ended(ended_id))


func get_definition(dialogue_id: String) -> DialogueDefinition:
	return ContentService.find_resource(dialogue_id) as DialogueDefinition


func _enter_node(node_id: String) -> void:
	if runtime == null:
		return
	var definition := get_definition(runtime.dialogue_id)
	if definition == null:
		end()
		return
	var node := definition.get_node(node_id)
	if node == null:
		end()
		return
	runtime.current_node_id = node_id
	runtime.history.append(node_id)
	_run_effects(node.on_enter_effects)
	if runtime == null:
		return
	node_entered.emit(node)
	if not node.choices.is_empty():
		choices_presented.emit(node, get_available_choices())


func _current_node() -> DialogueNode:
	if runtime == null:
		return null
	var definition := get_definition(runtime.dialogue_id)
	if definition == null:
		return null
	return definition.get_node(runtime.current_node_id)


func _run_effects(effects: Array[GameEffect]) -> void:
	if effects.is_empty():
		return
	if runtime == null:
		return
	var executor := Mkit.effects()
	if executor == null:
		return
	executor.execute_many(effects, runtime.context, false)
