class_name CombatService
extends RefCounted


func resolve(request: DamageRequest) -> DamageResult:
	var intent := resolve_damage_intent(request)
	var resolution := resolve_damage_resolution(intent)
	return to_application(resolution).to_result()


func resolve_damage_intent(request: DamageRequest) -> DamageIntent:
	return DamageIntent.from_request(request)


func resolve_damage_resolution(intent: DamageIntent) -> DamageResolution:
	var resolution := DamageResolution.new()
	if intent == null or intent.source == null or intent.target == null:
		resolution.failure_reason = "missing source or target"
		resolution.trace["failure"] = resolution.failure_reason
		return resolution

	resolution.source = intent.source
	resolution.target = intent.target
	resolution.base_amount = intent.base_amount
	resolution.damage_type = intent.damage_type
	resolution.element_type = intent.element_type
	resolution.trace["base"] = intent.base_amount
	resolution.trace["damage_source_node"] = _safe_node_name(intent.source)
	resolution.trace["damage_target_node"] = _safe_node_name(intent.target)

	if intent.can_evade and _roll_chance(_stat(_get_stats(intent.target), "evade_chance", 0.0)):
		resolution.was_evaded = true
		resolution.final_amount = 0.0
		resolution.trace["evaded"] = true
		return resolution

	var source_stats := _get_stats(intent.source)
	var target_stats := _get_stats(intent.target)
	var attack_power := _stat(source_stats, "attack_power", 0.0)
	var damage_multiplier := _stat(source_stats, "damage_multiplier", 1.0)
	var defense := _stat(target_stats, "defense", 0.0)
	var crit_chance := _stat(source_stats, "crit_chance", 0.0)
	var crit_damage := _stat(source_stats, "crit_damage", 1.5)

	var amount := intent.base_amount
	amount += attack_power
	resolution.trace["after_attack_power"] = amount
	amount *= damage_multiplier
	resolution.trace["after_damage_multiplier"] = amount

	if intent.can_crit and _roll_chance(crit_chance):
		resolution.was_critical = true
		amount *= crit_damage
		resolution.trace["crit_roll"] = true

	resolution.trace["after_crit"] = amount
	amount = max(0.0, amount - defense)
	resolution.trace["after_defense"] = amount
	resolution.final_amount = max(0.0, amount)
	resolution.trace["final"] = resolution.final_amount

	_resolve_status_applications(intent, resolution)
	return resolution


func to_application(resolution: DamageResolution) -> DamageApplication:
	return DamageApplication.from_resolution(resolution)


func _resolve_status_applications(intent: DamageIntent, resolution: DamageResolution) -> void:
	if intent == null or resolution == null:
		return
	if resolution.was_evaded or resolution.was_blocked:
		return
	for entry in intent.on_hit_statuses:
		var status_id := str(entry.get("status_id", ""))
		if status_id == "":
			continue
		var chance := float(entry.get("chance", 1.0))
		if not _roll_chance(chance):
			continue
		var app := DamageStatusApplication.from_values(
			status_id, int(entry.get("stacks", 1)), float(entry.get("duration", -1.0))
		)
		resolution.applied_status_effects.append(app)
		resolution.trace["applied_status_effects"] = _as_status_id_list(resolution.applied_status_effects)


func _get_stats(entity: Node) -> StatsComponent:
	if entity == null:
		return null
	return EntityContract.get_component(entity, "StatsComponent") as StatsComponent


func _stat(stats: StatsComponent, stat_id: String, default_value: float) -> float:
	if stats == null:
		return default_value
	return stats.get_stat_value(stat_id, default_value)


func _roll_chance(chance: float) -> bool:
	var random: RandomService = null
	random = Mkit.random()
	if random != null:
		return random.randf() < chance
	return randf() < chance


func _safe_node_name(node: Node) -> String:
	return node.name if node != null else "null"


func _as_status_id_list(applications: Array[DamageStatusApplication]) -> Array[String]:
	var ids: Array[String] = []
	for app in applications:
		if app != null:
			ids.append(app.status_id)
	return ids
