## What: CombatResolver converts a DamageRequest into a finalized DamageResult.
## Responsibilities: apply attacker/defender stats, roll crit/evade/block, compute final damage, and select on-hit statuses.
## Upstream: HitboxComponent, DealDamageEffect, abilities, or tests create DamageRequest objects.
## Downstream: HealthComponent applies the DamageResult and EventRouter/UI/debug tools inspect the trace.
## When to use: Use it whenever damage needs to follow the shared combat formula instead of ad hoc subtraction.
## Example: `var result := CombatResolver.get_default().resolve(DamageRequest.new())` after filling source, target, and base_amount.
class_name CombatResolver
extends RefCounted

static var _default: CombatResolver = null


## Purpose: Public method `get_default` for external gameplay integration.
## Example: `CombatResolver.get_default()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func get_default() -> CombatResolver:
	if _default == null:
		_default = CombatResolver.new()
	return _default


## Purpose: Public method `resolve` for external gameplay integration.
## Example: `self.resolve(<request>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func resolve(request: DamageRequest) -> DamageResult:
	var result := DamageResult.new()
	result.source = request.source
	result.target = request.target
	result.base_amount = request.base_amount
	result.damage_type = request.damage_type
	result.element_type = request.element_type

	if request.source == null or request.target == null:
		result.final_amount = 0.0
		result.trace["failure"] = "missing source or target"
		return result

	var source_stats := _get_stats(request.source)
	var target_stats := _get_stats(request.target)

	var attack_power := _stat(source_stats, "attack_power", 0.0)
	var damage_multiplier := _stat(source_stats, "damage_multiplier", 1.0)
	var defense := _stat(target_stats, "defense", 0.0)
	var crit_chance := _stat(source_stats, "crit_chance", 0.0)
	var crit_damage := _stat(source_stats, "crit_damage", 1.5)

	var amount := request.base_amount
	result.trace["base"] = amount

	amount += attack_power
	result.trace["after_attack_power"] = amount

	amount *= damage_multiplier
	result.trace["after_damage_multiplier"] = amount

	if request.can_crit and _roll_chance(crit_chance):
		result.was_critical = true
		amount *= crit_damage
	result.trace["after_crit"] = amount

	amount = max(0.0, amount - defense)
	result.trace["after_defense"] = amount

	# 后续可扩展：元素抗性、护盾、格挡、闪避、伤害上下限。
	result.final_amount = max(0.0, amount)

	_roll_on_hit_statuses(request, result)
	return result


func _roll_on_hit_statuses(request: DamageRequest, result: DamageResult) -> void:
	# 命中被闪避/格挡时不附加 on-hit 状态。
	if result.was_evaded or result.was_blocked:
		return
	for entry in request.on_hit_statuses:
		var status_id := str(entry.get("status_id", ""))
		if status_id == "":
			continue
		var chance := float(entry.get("chance", 1.0))
		if not _roll_chance(chance):
			continue
		result.applied_status_effects.append(status_id)
		result.status_applications.append({
			"status_id": status_id,
			"stacks": int(entry.get("stacks", 1)),
			"duration": float(entry.get("duration", -1.0))
		})
	if not result.applied_status_effects.is_empty():
		result.trace["applied_status_effects"] = result.applied_status_effects


func _get_stats(entity: Node) -> StatsComponent:
	if entity == null:
		return null
	return entity.get_node_or_null("Components/StatsComponent") as StatsComponent


func _stat(stats: StatsComponent, stat_id: String, default_value: float) -> float:
	if stats == null:
		return default_value
	return stats.get_stat_value(stat_id, default_value)


func _roll_chance(chance: float) -> bool:
	var random := ServiceRegistry.get_service("random") as RandomService
	if random != null:
		return random.randf() < chance
	return randf() < chance
