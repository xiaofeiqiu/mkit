## What: EventRouter is the shared event bus for facts that already happened in gameplay.
## Responsibilities: emit typed signals, mirror them into DomainEvent objects, and keep recent event history.
## Upstream: combat, inventory, rooms, rewards, runs, and custom systems publish events through it.
## Downstream: UI, audio, analytics, debug tools, save hooks, and tests subscribe without coupling to publishers.
## When to use: Use it for notifications such as damage_applied, entity_died, room_cleared, or run_finished.
## Example: `events.entity_died.connect(_on_entity_died); events.emit_room_cleared("room_01")`.
class_name EventRouter
extends Node

# Event is an already-happened fact. Name events in the past tense.
# Do NOT use events to request that another system do something.
#
# Phase 0 scope: the generic domain event stream plus the signals whose
# parameters only depend on built-in types. Signals that carry combat/inventory
# payloads (damage_applied -> DamageResult, item_collected -> ItemInstance) are
# added together with their modules in later phases so the kernel stays
# self-contained and compiles on its own.

## Purpose: Emits the `domain_event_emitted` signal to notify external listeners of a state change.
## Example: `self.domain_event_emitted.connect(_on_domain_event_emitted)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal domain_event_emitted(event: DomainEvent)
# `result` is a combat DamageResult, but the kernel sits below the combat module
# so the parameter is left untyped to avoid an inward->outward dependency.
# Listeners cast it themselves.
## Purpose: Emits the `damage_applied` signal to notify external listeners of a state change.
## Example: `self.damage_applied.connect(_on_damage_applied)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal damage_applied(result)
## Purpose: Emits the `entity_died` signal to notify external listeners of a state change.
## Example: `self.entity_died.connect(_on_entity_died)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal entity_died(entity_id: String, entity_ref: Node)
## Purpose: Emits the `inventory_changed` signal to notify external listeners of a state change.
## Example: `self.inventory_changed.connect(_on_inventory_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal inventory_changed(owner_id: String)
## Purpose: Emits the `room_cleared` signal to notify external listeners of a state change.
## Example: `self.room_cleared.connect(_on_room_cleared)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal room_cleared(room_id: String)
## Purpose: Emits the `reward_selected` signal to notify external listeners of a state change.
## Example: `self.reward_selected.connect(_on_reward_selected)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal reward_selected(reward_id: String)
## Purpose: Emits the `run_started` signal to notify external listeners of a state change.
## Example: `self.run_started.connect(_on_run_started)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal run_started(run_id: String, seed: int)
## Purpose: Emits the `run_finished` signal to notify external listeners of a state change.
## Example: `self.run_finished.connect(_on_run_finished)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal run_finished(run_id: String, result: String)

## Purpose: Public runtime field `recent_events`.
## Example: `self.recent_events = []`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var recent_events: Array[DomainEvent] = []
## Purpose: Public runtime field `max_recent_events`.
## Example: `self.max_recent_events = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var max_recent_events: int = 100


## Purpose: Public method `emit_domain_event` for external gameplay integration.
## Example: `self.emit_domain_event(<event>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func emit_domain_event(event: DomainEvent) -> void:
	recent_events.append(event)
	if recent_events.size() > max_recent_events:
		recent_events.pop_front()
	domain_event_emitted.emit(event)


## Purpose: Public method `emit_damage_applied` for external gameplay integration.
## Example: `self.emit_damage_applied(<result>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
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


## Purpose: Public method `emit_entity_died` for external gameplay integration.
## Example: `self.emit_entity_died(<entity_id>, <entity_ref>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func emit_entity_died(entity_id: String, entity_ref: Node) -> void:
	entity_died.emit(entity_id, entity_ref)
	emit_domain_event(DomainEvent.create("entity_died", entity_id, "", {"entity_id": entity_id}))


## Purpose: Public method `emit_inventory_changed` for external gameplay integration.
## Example: `self.emit_inventory_changed(<owner_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func emit_inventory_changed(owner_id: String) -> void:
	inventory_changed.emit(owner_id)
	emit_domain_event(DomainEvent.create("inventory_changed", owner_id, "", {}))


## Purpose: Public method `emit_room_cleared` for external gameplay integration.
## Example: `self.emit_room_cleared(<room_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func emit_room_cleared(room_id: String) -> void:
	room_cleared.emit(room_id)
	emit_domain_event(DomainEvent.create("room_cleared", room_id, "", {}))


## Purpose: Public method `emit_reward_selected` for external gameplay integration.
## Example: `self.emit_reward_selected(<reward_id>, <source_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func emit_reward_selected(reward_id: String, source_id: String = "") -> void:
	reward_selected.emit(reward_id)
	emit_domain_event(DomainEvent.create("reward_selected", source_id, "", {
		"reward_id": reward_id
	}))


## Purpose: Public method `emit_run_started` for external gameplay integration.
## Example: `self.emit_run_started(<run_id>, <seed>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func emit_run_started(run_id: String, seed: int) -> void:
	run_started.emit(run_id, seed)
	emit_domain_event(DomainEvent.create("run_started", run_id, "", {
		"seed": seed
	}))


## Purpose: Public method `emit_run_finished` for external gameplay integration.
## Example: `self.emit_run_finished(<run_id>, <result>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func emit_run_finished(run_id: String, result: String) -> void:
	run_finished.emit(run_id, result)
	emit_domain_event(DomainEvent.create("run_finished", run_id, "", {
		"result": result
	}))


# Resolve a stable entity id from a node. EntityIdentity is a gameplay-module
# type that sits above the kernel, so it is read by duck typing to avoid an
# inward->outward dependency.
func _get_entity_id(entity: Node) -> String:
	if entity == null:
		return ""
	var identity = entity.get_node_or_null("EntityIdentity")
	if identity != null and "entity_id" in identity:
		return str(identity.entity_id)
	return str(entity.name)
