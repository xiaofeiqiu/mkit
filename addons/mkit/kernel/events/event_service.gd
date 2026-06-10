class_name EventService
extends Node
signal domain_event_emitted(event: DomainEvent)
signal damage_applied(result: DamageResult)
signal entity_died(entity_id: String, entity_ref: Node)
signal inventory_changed(owner_id: String)
signal room_cleared(room_id: String)
signal reward_selected(reward_id: String)
signal run_started(run_id: String, seed: int)
signal run_finished(run_id: String, result: String)
signal quest_accepted(quest_id: String)
signal quest_objective_advanced(quest_id: String, objective_id: String, current: int, required: int)
signal quest_completed(quest_id: String)
signal quest_turned_in(quest_id: String)
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal npc_talked(npc_id: String)
signal zone_changed(from_zone_id: String, to_zone_id: String)
signal item_purchased(shop_id: String, item_id: String, quantity: int)
signal item_sold(shop_id: String, item_id: String, quantity: int)
var recent_events: Array[DomainEvent] = []
var max_recent_events: int = 100


## Static convenience lookup through the service registry; null when absent.
static func find() -> EventService:
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService


func emit_domain_event(event: DomainEvent) -> void:
	recent_events.append(event)
	if recent_events.size() > max_recent_events:
		recent_events.pop_front()
	domain_event_emitted.emit(event)


func emit_damage_applied(result: DamageResult) -> void:
	damage_applied.emit(result)
	var data: Dictionary = {}
	if result != null:
		data = result.to_debug_dict()
	var source_id := ""
	var target_id := ""
	if result != null:
		source_id = _get_entity_id(result.source)
		target_id = _get_entity_id(result.target)
	_emit_domain_event("damage_applied", source_id, target_id, data)


func emit_entity_died(entity_id: String, entity_ref: Node) -> void:
	entity_died.emit(entity_id, entity_ref)
	_emit_domain_event("entity_died", entity_id, "", {"entity_id": entity_id})


func emit_inventory_changed(
	owner_id: String, item_id: String = "", quantity: int = 0, change_type: String = ""
) -> void:
	inventory_changed.emit(owner_id)
	var payload := {"owner_id": owner_id}
	if item_id != "":
		payload["item_id"] = item_id
	if quantity > 0:
		payload["quantity"] = quantity
	if change_type != "":
		payload["change_type"] = change_type
	_emit_domain_event("inventory_changed", owner_id, item_id, payload)


func emit_room_cleared(room_id: String) -> void:
	room_cleared.emit(room_id)
	_emit_domain_event("room_cleared", room_id, "", {})


func emit_reward_selected(reward_id: String, source_id: String = "") -> void:
	reward_selected.emit(reward_id)
	_emit_domain_event("reward_selected", source_id, "", {"reward_id": reward_id})


func emit_run_started(run_id: String, seed: int) -> void:
	run_started.emit(run_id, seed)
	_emit_domain_event("run_started", run_id, "", {"seed": seed})


func emit_run_finished(run_id: String, result: String) -> void:
	run_finished.emit(run_id, result)
	_emit_domain_event("run_finished", run_id, "", {"result": result})


func emit_quest_accepted(quest_id: String) -> void:
	quest_accepted.emit(quest_id)
	_emit_domain_event("quest_accepted", quest_id, "", {"quest_id": quest_id})


func emit_quest_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> void:
	quest_objective_advanced.emit(quest_id, objective_id, current, required)
	_emit_domain_event(
		"quest_objective_advanced",
		quest_id,
		objective_id,
		{"quest_id": quest_id, "objective_id": objective_id, "current": current, "required": required}
	)


func emit_quest_completed(quest_id: String) -> void:
	quest_completed.emit(quest_id)
	_emit_domain_event("quest_completed", quest_id, "", {"quest_id": quest_id})


func emit_quest_turned_in(quest_id: String) -> void:
	quest_turned_in.emit(quest_id)
	_emit_domain_event("quest_turned_in", quest_id, "", {"quest_id": quest_id})


func emit_dialogue_started(dialogue_id: String) -> void:
	dialogue_started.emit(dialogue_id)
	_emit_domain_event("dialogue_started", dialogue_id, "", {"dialogue_id": dialogue_id})


func emit_dialogue_ended(dialogue_id: String) -> void:
	dialogue_ended.emit(dialogue_id)
	_emit_domain_event("dialogue_ended", dialogue_id, "", {"dialogue_id": dialogue_id})


func emit_npc_talked(npc_id: String) -> void:
	npc_talked.emit(npc_id)
	_emit_domain_event("npc_talked", npc_id, "", {"npc_id": npc_id})


func emit_zone_changed(from_zone_id: String, to_zone_id: String) -> void:
	zone_changed.emit(from_zone_id, to_zone_id)
	_emit_domain_event(
		"zone_changed", from_zone_id, to_zone_id, {"from_zone_id": from_zone_id, "to_zone_id": to_zone_id}
	)


func emit_item_purchased(shop_id: String, item_id: String, quantity: int) -> void:
	item_purchased.emit(shop_id, item_id, quantity)
	_emit_domain_event("item_purchased", shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity})


func emit_item_sold(shop_id: String, item_id: String, quantity: int) -> void:
	item_sold.emit(shop_id, item_id, quantity)
	_emit_domain_event("item_sold", shop_id, item_id, {"shop_id": shop_id, "item_id": item_id, "quantity": quantity})


func _emit_domain_event(
	event_type: String, source_id: String, target_id: String, payload: Dictionary
) -> void:
	emit_domain_event(DomainEvent.create(event_type, source_id, target_id, payload))


func _get_entity_id(entity: Node) -> String:
	if entity == null:
		return ""
	var identity := EntityContract.get_identity(entity)
	if identity != null and "entity_id" in identity:
		return str(identity.entity_id)
	return str(entity.name)
