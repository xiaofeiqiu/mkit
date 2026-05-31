## What: HealthComponent tracks HP, applies DamageResult values, healing, death, and revival for an entity.
## Responsibilities: clamp health, query max HP from StatsComponent, emit health/death signals, and apply on-hit statuses.
## Upstream: CombatResolver, DealDamageEffect, HealEffect, pickups, or scripts call apply_damage/heal/revive.
## Downstream: EventRouter, StatusEffectController, UI, room clear logic, and death handling consume its signals.
## When to use: Attach it to any damageable entity such as player, enemy, destructible prop, or dummy.
## Example: `var result := CombatResolver.get_default().resolve(request); $HealthComponent.apply_damage(result)`.
class_name HealthComponent
extends Node

## Purpose: Emits the `health_changed` signal to notify external listeners of a state change.
## Example: `self.health_changed.connect(_on_health_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal health_changed(current: float, max_value: float)
## Purpose: Emits the `damaged` signal to notify external listeners of a state change.
## Example: `self.damaged.connect(_on_damaged)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal damaged(result: DamageResult)
## Purpose: Emits the `healed` signal to notify external listeners of a state change.
## Example: `self.healed.connect(_on_healed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal healed(amount: float, source: Node)
## Purpose: Emits the `died` signal to notify external listeners of a state change.
## Example: `self.died.connect(_on_died)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal died(owner_entity: Node)

## Purpose: Inspector-exposed configuration `current_hp`.
## Example: `self.current_hp = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var current_hp: float = 100.0
## Purpose: Inspector-exposed configuration `destroy_on_death`.
## Example: `self.destroy_on_death = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var destroy_on_death: bool = false

## Purpose: Public runtime field `dead`.
## Example: `self.dead = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var dead: bool = false
## Purpose: Public runtime field `stats`.
## Example: `self.stats = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var stats: StatsComponent = null


func _ready() -> void:
	stats = owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats != null:
		stats.stat_changed.connect(_on_stat_changed)
	current_hp = min(current_hp, get_max_hp())


## Purpose: Public method `get_max_hp` for external gameplay integration.
## Example: `self.get_max_hp()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_max_hp() -> float:
	if stats != null:
		return stats.get_stat_value("max_hp", 100.0)
	return 100.0


## Purpose: Public method `apply_damage` for external gameplay integration.
## Example: `self.apply_damage(<result>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func apply_damage(result: DamageResult) -> void:
	if dead:
		return
	if result == null or result.was_evaded:
		return

	current_hp = max(0.0, current_hp - result.final_amount)
	result.was_lethal = current_hp <= 0.0

	# 施加 CombatResolver 已掷定的 on-hit 状态（如命中触发的 burn）。
	# 这里是伤害落地的唯一汇聚点：Hitbox 路径和 DealDamageEffect 路径都经过它。
	_apply_on_hit_statuses(result)

	damaged.emit(result)
	health_changed.emit(current_hp, get_max_hp())

	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.emit_damage_applied(result)

	if current_hp <= 0.0:
		die(result.source)


func _apply_on_hit_statuses(result: DamageResult) -> void:
	if result.status_applications.is_empty():
		return
	# StatusEffectController is a Phase 2 module type; resolve it by duck typing so
	# the combat module does not hard-depend on the status module.
	var controller = owner.get_node_or_null("Controllers/StatusEffectController")
	if controller == null or not controller.has_method("apply_status"):
		return
	for entry in result.status_applications:
		controller.apply_status(
			str(entry.get("status_id", "")),
			result.source,
			int(entry.get("stacks", 1)),
			float(entry.get("duration", -1.0))
		)


## Purpose: Public method `heal` for external gameplay integration.
## Example: `self.heal(<amount>, <source>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func heal(amount: float, source: Node = null) -> void:
	if dead:
		return
	if amount <= 0:
		return

	current_hp = min(get_max_hp(), current_hp + amount)
	healed.emit(amount, source)
	health_changed.emit(current_hp, get_max_hp())


## Purpose: Public method `die` for external gameplay integration.
## Example: `self.die(<killer>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func die(killer: Node = null) -> void:
	if dead:
		return
	dead = true
	current_hp = 0.0
	died.emit(owner)

	var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
	var entity_id: String = identity.entity_id if identity != null else str(owner.name)

	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.emit_entity_died(entity_id, owner)

	if destroy_on_death:
		owner.queue_free()


## Purpose: Public method `revive` for external gameplay integration.
## Example: `self.revive(<percent>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func revive(percent: float = 1.0) -> void:
	dead = false
	current_hp = get_max_hp() * clamp(percent, 0.0, 1.0)
	health_changed.emit(current_hp, get_max_hp())


func _on_stat_changed(stat_id: String, old_value: float, new_value: float) -> void:
	if stat_id == "max_hp":
		current_hp = min(current_hp, new_value)
		health_changed.emit(current_hp, new_value)
