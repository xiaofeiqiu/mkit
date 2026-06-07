class_name QuestService
extends Saveable
signal quest_offered(quest_id: String)
signal quest_accepted(quest_id: String)
signal objective_advanced(quest_id: String, objective_id: String, current: int, required: int)
signal quest_completed(quest_id: String)
signal quest_turned_in(quest_id: String)
var log: QuestLog = QuestLog.new()
var content: ContentService = null
var _quest_contexts: Dictionary = {}


func _ready() -> void:
	if save_id == "":
		save_id = "quest"
	if ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentService
	_connect_events()


func _connect_events() -> void:
	var events := _get_events()
	if events == null:
		return
	if not events.domain_event_emitted.is_connected(notify_event):
		events.domain_event_emitted.connect(notify_event)
	if not events.entity_died.is_connected(_on_entity_died):
		events.entity_died.connect(_on_entity_died)


func can_accept(quest_id: String, context: GameplayContext) -> bool:
	var definition := get_definition(quest_id)
	if definition == null:
		return false
	var existing := log.get_state(quest_id)
	if existing != null:
		if existing.status == "active" or existing.status == "completed":
			return false
		if existing.status == "turned_in" and not definition.repeatable:
			return false
	for prerequisite_id in definition.prerequisite_quest_ids:
		var prerequisite := log.get_state(prerequisite_id)
		if prerequisite == null or prerequisite.status != "turned_in":
			return false
	var ctx := context if context != null else GameplayContext.new()
	if not ConditionEvaluator.evaluate_all(definition.accept_conditions, ctx):
		return false
	return true


func accept_quest(quest_id: String, context: GameplayContext) -> bool:
	if not can_accept(quest_id, context):
		return false
	var definition := get_definition(quest_id)
	var state := log.get_state(quest_id)
	if state == null:
		state = QuestState.create(quest_id)
		log.states[quest_id] = state
	state.status = "active"
	state.objective_progress = {}
	for objective in definition.objectives:
		state.set_progress(objective.objective_id, 0)
	if context != null:
		_quest_contexts[quest_id] = context
	quest_accepted.emit(quest_id)
	var events := _get_events()
	if events != null:
		events.emit_quest_accepted(quest_id)
	return true


func notify_event(event: DomainEvent) -> void:
	if event == null:
		return
	if event.event_type == "inventory_changed":
		_notify_item_acquired(event)
	for state in log.get_active():
		var definition := get_definition(state.quest_id)
		if definition == null:
			continue
		var changed := false
		for objective in definition.objectives:
			if not _objective_matches(objective, event):
				continue
			var amount := 1
			if objective.count_payload_key != "":
				amount = int(event.payload.get(objective.count_payload_key, 1))
			if amount <= 0:
				continue
			if _advance_progress(state, objective, amount):
				changed = true
		if changed and definition.auto_complete and is_quest_complete(state.quest_id):
			complete_quest(state.quest_id, _quest_contexts.get(state.quest_id, null))


func advance_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var state := log.get_state(quest_id)
	if state == null or state.status != "active":
		return false
	var definition := get_definition(quest_id)
	if definition == null:
		return false
	var objective := definition.get_objective(objective_id)
	if objective == null:
		return false
	if _advance_progress(state, objective, amount):
		if definition.auto_complete and is_quest_complete(quest_id):
			return complete_quest(quest_id, _quest_contexts.get(quest_id, null))
		return true
	return false


func is_quest_complete(quest_id: String) -> bool:
	var state := log.get_state(quest_id)
	var definition := get_definition(quest_id)
	if state == null or definition == null:
		return false
	for objective in definition.objectives:
		if objective.optional:
			continue
		if state.get_progress(objective.objective_id) < objective.required_count:
			return false
	return true


func complete_quest(quest_id: String, context: GameplayContext) -> bool:
	var state := log.get_state(quest_id)
	if state == null or state.status != "active":
		return false
	if not is_quest_complete(quest_id):
		return false
	state.status = "completed"
	quest_completed.emit(quest_id)
	var events := _get_events()
	if events != null:
		events.emit_quest_completed(quest_id)
	var definition := get_definition(quest_id)
	if definition != null and definition.auto_complete:
		return turn_in_quest(quest_id, context)
	return true


func turn_in_quest(quest_id: String, context: GameplayContext) -> bool:
	var state := log.get_state(quest_id)
	if state == null or state.status != "completed":
		return false
	var definition := get_definition(quest_id)
	var ctx := context
	if ctx == null:
		ctx = _quest_contexts.get(quest_id, null)
	if ctx == null:
		ctx = GameplayContext.new()
	if not _run_reward_effects(definition, ctx):
		return false
	state.status = "turned_in"
	if definition != null and definition.repeatable:
		state.status = "available"
		state.objective_progress = {}
	quest_turned_in.emit(quest_id)
	var events := _get_events()
	if events != null:
		events.emit_quest_turned_in(quest_id)
	return true


func get_definition(quest_id: String) -> QuestDefinition:
	if quest_id.strip_edges() == "":
		return null
	if content == null and ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentService
	if content == null:
		return null
	return content.get_resource(quest_id) as QuestDefinition


func get_state(quest_id: String) -> QuestState:
	return log.get_state(quest_id)


func to_save_data() -> Dictionary:
	return log.to_save_data()


func from_save_data(data: Dictionary) -> void:
	log.from_save_data(data)


func _advance_progress(state: QuestState, objective: QuestObjectiveDefinition, amount: int) -> bool:
	var current := state.get_progress(objective.objective_id)
	if current >= objective.required_count:
		return false
	var updated: int = min(current + amount, objective.required_count)
	state.set_progress(objective.objective_id, updated)
	objective_advanced.emit(
		state.quest_id, objective.objective_id, updated, objective.required_count
	)
	var events := _get_events()
	if events != null:
		events.emit_quest_objective_advanced(
			state.quest_id, objective.objective_id, updated, objective.required_count
		)
	return true


func _objective_matches(objective: QuestObjectiveDefinition, event: DomainEvent) -> bool:
	if objective.event_type != event.event_type:
		return false
	if objective.match_key == "":
		return true
	var actual = event.payload.get(objective.match_key, null)
	if actual == null:
		return false
	if actual is Array:
		return actual.has(objective.match_value)
	return str(actual) == objective.match_value


func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
	var payload := {"entity_id": entity_id}
	if entity_ref != null:
		var identity := entity_ref.get_node_or_null("EntityIdentity") as EntityIdentity
		if identity != null:
			payload["tags"] = identity.tags
			payload["faction"] = identity.faction
			payload["definition_id"] = identity.definition_id
	notify_event(DomainEvent.create("enemy_killed", entity_id, "", payload))


func _notify_item_acquired(event: DomainEvent) -> void:
	if str(event.payload.get("change_type", "")) != "added":
		return
	var item_id := str(event.payload.get("item_id", ""))
	if item_id == "":
		return
	var amount := int(event.payload.get("quantity", 1))
	if amount <= 0:
		return
	var payload := event.payload.duplicate(true)
	payload["amount"] = amount
	notify_event(DomainEvent.create("item_acquired", event.source_id, event.target_id, payload))


func _run_reward_effects(definition: QuestDefinition, context: GameplayContext) -> bool:
	if definition == null:
		return false
	if definition.reward_effects.is_empty():
		return true
	if not ServiceRegistry.has_service("effects"):
		return false
	var executor := ServiceRegistry.get_service("effects") as EffectService
	if executor == null:
		return false
	var results := executor.execute_many(definition.reward_effects, context, true)
	for result in results:
		if not result.success:
			return false
	return true


func _get_events() -> EventService:
	if ServiceRegistry.has_service("events"):
		return ServiceRegistry.get_service("events") as EventService
	return null
