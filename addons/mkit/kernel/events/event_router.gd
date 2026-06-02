class_name EventRouter
extends Node
signal domain_event_emitted(event: DomainEvent)
signal damage_applied(result)
signal entity_died(entity_id: String, entity_ref: Node)
signal inventory_changed(owner_id: String)
signal room_cleared(room_id: String)
signal reward_selected(reward_id: String)
signal run_started(run_id: String, seed: int)
signal run_finished(run_id: String, result: String)
var recent_events: Array[DomainEvent] = []
var max_recent_events: int = 100


func emit_domain_event(event: DomainEvent) -> void:
	recent_events.append(event)
	if recent_events.size() > max_recent_events:
		recent_events.pop_front()
	domain_event_emitted.emit(event)


func emit_damage_applied(result) -> void:
	damage_applied.emit(result)
	var data: Dictionary = {}
	if result != null and result.has_method("to_debug_dict"):
		data = result.to_debug_dict()
	var source_id := ""
	var target_id := ""
	if result != null:
		source_id = _get_entity_id(result.source)
		target_id = _get_entity_id(result.target)
	emit_domain_event(DomainEvent.create("damage_applied", source_id, target_id, data))


func emit_entity_died(entity_id: String, entity_ref: Node) -> void:
	entity_died.emit(entity_id, entity_ref)
	emit_domain_event(DomainEvent.create("entity_died", entity_id, "", {"entity_id": entity_id}))


func emit_inventory_changed(owner_id: String) -> void:
	inventory_changed.emit(owner_id)
	emit_domain_event(DomainEvent.create("inventory_changed", owner_id, "", {}))


func emit_room_cleared(room_id: String) -> void:
	room_cleared.emit(room_id)
	emit_domain_event(DomainEvent.create("room_cleared", room_id, "", {}))


func emit_reward_selected(reward_id: String, source_id: String = "") -> void:
	reward_selected.emit(reward_id)
	emit_domain_event(
		DomainEvent.create("reward_selected", source_id, "", {"reward_id": reward_id})
	)


func emit_run_started(run_id: String, seed: int) -> void:
	run_started.emit(run_id, seed)
	emit_domain_event(DomainEvent.create("run_started", run_id, "", {"seed": seed}))


func emit_run_finished(run_id: String, result: String) -> void:
	run_finished.emit(run_id, result)
	emit_domain_event(DomainEvent.create("run_finished", run_id, "", {"result": result}))


func _get_entity_id(entity: Node) -> String:
	if entity == null:
		return ""
	var identity = entity.get_node_or_null("EntityIdentity")
	if identity != null and "entity_id" in identity:
		return str(identity.entity_id)
	return str(entity.name)
