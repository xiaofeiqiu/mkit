extends CombatService

# Game policy: base_amount is the complete outgoing hit, not an addition to ATK.
# Keep the framework's DamageRequest / DamageResult / HealthComponent pipeline.
func resolve(request: DamageRequest) -> DamageResult:
	var result := DamageResult.new()
	if request == null or not is_instance_valid(request.source) or not is_instance_valid(request.target):
		result.trace["failure"] = "missing source or target"
		return result
	result.source = request.source
	result.target = request.target
	result.base_amount = request.base_amount
	result.damage_type = request.damage_type
	result.element_type = request.element_type
	var target_stats := _get_stats(request.target)
	var source_stats := _get_stats(request.source)
	var defense := maxf(0.0, _stat(target_stats, "defense", 0.0))
	var amount := maxf(0.0, request.base_amount)
	if request.can_crit and _roll_chance(_stat(source_stats, "crit_chance", 0.05)):
		result.was_critical = true
		amount *= _stat(source_stats, "crit_damage", 1.5)
	result.final_amount = maxf(1.0, roundf(amount * 100.0 / (100.0 + defense)))
	result.trace = {"outgoing": request.base_amount, "defense": defense, "final": result.final_amount}
	return result
