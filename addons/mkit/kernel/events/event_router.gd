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
	emit_domain_event(DomainEvent.create("inventory_changed", owner_id, item_id, payload))


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


func emit_quest_accepted(quest_id: String) -> void:
	quest_accepted.emit(quest_id)
	emit_domain_event(DomainEvent.create("quest_accepted", quest_id, "", {"quest_id": quest_id}))


func emit_quest_objective_advanced(
	quest_id: String, objective_id: String, current: int, required: int
) -> void:
	quest_objective_advanced.emit(quest_id, objective_id, current, required)
	emit_domain_event(
		DomainEvent.create(
			"quest_objective_advanced",
			quest_id,
			objective_id,
			{
				"quest_id": quest_id,
				"objective_id": objective_id,
				"current": current,
				"required": required
			}
		)
	)


func emit_quest_completed(quest_id: String) -> void:
	quest_completed.emit(quest_id)
	emit_domain_event(DomainEvent.create("quest_completed", quest_id, "", {"quest_id": quest_id}))


func emit_quest_turned_in(quest_id: String) -> void:
	quest_turned_in.emit(quest_id)
	emit_domain_event(DomainEvent.create("quest_turned_in", quest_id, "", {"quest_id": quest_id}))


func emit_dialogue_started(dialogue_id: String) -> void:
	dialogue_started.emit(dialogue_id)
	emit_domain_event(
		DomainEvent.create("dialogue_started", dialogue_id, "", {"dialogue_id": dialogue_id})
	)


func emit_dialogue_ended(dialogue_id: String) -> void:
	dialogue_ended.emit(dialogue_id)
	emit_domain_event(
		DomainEvent.create("dialogue_ended", dialogue_id, "", {"dialogue_id": dialogue_id})
	)


func emit_npc_talked(npc_id: String) -> void:
	npc_talked.emit(npc_id)
	emit_domain_event(DomainEvent.create("npc_talked", npc_id, "", {"npc_id": npc_id}))


func emit_zone_changed(from_zone_id: String, to_zone_id: String) -> void:
	zone_changed.emit(from_zone_id, to_zone_id)
	emit_domain_event(
		DomainEvent.create(
			"zone_changed",
			from_zone_id,
			to_zone_id,
			{"from_zone_id": from_zone_id, "to_zone_id": to_zone_id}
		)
	)


func emit_item_purchased(shop_id: String, item_id: String, quantity: int) -> void:
	item_purchased.emit(shop_id, item_id, quantity)
	emit_domain_event(
		DomainEvent.create(
			"item_purchased",
			shop_id,
			item_id,
			{"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
		)
	)


func emit_item_sold(shop_id: String, item_id: String, quantity: int) -> void:
	item_sold.emit(shop_id, item_id, quantity)
	emit_domain_event(
		DomainEvent.create(
			"item_sold",
			shop_id,
			item_id,
			{"shop_id": shop_id, "item_id": item_id, "quantity": quantity}
		)
	)


func _get_entity_id(entity: Node) -> String:
	if entity == null:
		return ""
	var identity = entity.get_node_or_null("EntityIdentity")
	if identity != null and "entity_id" in identity:
		return str(identity.entity_id)
	return str(entity.name)
