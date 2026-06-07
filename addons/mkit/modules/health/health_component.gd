class_name HealthComponent
extends SaveableComponent
signal health_changed(current: float, max_value: float)
signal damaged(result: DamageResult)
signal healed(amount: float, source: Node)
signal died(owner_entity: Node)
@export var current_hp: float = 100.0
@export var destroy_on_death: bool = false
var dead: bool = false
var stats: StatsComponent = null


func _ready() -> void:
	if owner != null:
		stats = owner.get_node_or_null("Components/StatsComponent") as StatsComponent
		if stats != null:
			stats.stat_changed.connect(_on_stat_changed)
	current_hp = min(current_hp, get_max_hp())


func get_max_hp() -> float:
	if stats != null:
		return stats.get_stat_value("max_hp", 100.0)
	return 100.0


func apply_damage(result: DamageResult) -> void:
	if dead:
		return
	if result == null or result.was_evaded:
		return
	current_hp = max(0.0, current_hp - result.final_amount)
	result.was_lethal = current_hp <= 0.0
	_apply_on_hit_statuses(result)
	damaged.emit(result)
	health_changed.emit(current_hp, get_max_hp())
	if ServiceRegistry.has_service("events"):
		var events := ServiceRegistry.get_service("events") as EventService
		if events != null:
			events.emit_damage_applied(result)
	if current_hp <= 0.0:
		die(result.source)


func _apply_on_hit_statuses(result: DamageResult) -> void:
	if result.status_applications.is_empty():
		return
	var controller := owner.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
	if controller == null:
		return
	for entry in result.status_applications:
		controller.apply_status(
			str(entry.get("status_id", "")),
			result.source,
			int(entry.get("stacks", 1)),
			float(entry.get("duration", -1.0))
		)


func heal(amount: float, source: Node = null) -> void:
	if dead:
		return
	if amount <= 0:
		return
	current_hp = min(get_max_hp(), current_hp + amount)
	healed.emit(amount, source)
	health_changed.emit(current_hp, get_max_hp())


func die(killer: Node = null) -> void:
	if dead:
		return
	dead = true
	current_hp = 0.0
	died.emit(owner)
	var identity := owner.get_node_or_null("EntityIdentity") as EntityIdentity
	var entity_id: String = identity.entity_id if identity != null else str(owner.name)
	if ServiceRegistry.has_service("events"):
		var events := ServiceRegistry.get_service("events") as EventService
		if events != null:
			events.emit_entity_died(entity_id, owner)
	if destroy_on_death:
		owner.queue_free()


func revive(percent: float = 1.0) -> void:
	dead = false
	current_hp = get_max_hp() * clamp(percent, 0.0, 1.0)
	health_changed.emit(current_hp, get_max_hp())


func to_save_data() -> Dictionary:
	return {"current_hp": current_hp, "dead": dead}


func from_save_data(data: Dictionary) -> void:
	dead = bool(data.get("dead", dead))
	current_hp = clamp(float(data.get("current_hp", current_hp)), 0.0, get_max_hp())
	if dead:
		current_hp = 0.0
	health_changed.emit(current_hp, get_max_hp())


func _on_stat_changed(stat_id: String, old_value: float, new_value: float) -> void:
	if stat_id == "max_hp":
		current_hp = min(current_hp, new_value)
		health_changed.emit(current_hp, new_value)
