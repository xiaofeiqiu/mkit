class_name DealDamageEffect
extends GameEffect

@export var base_amount: float = 10.0
@export var damage_type: String = "physical"
@export var element_type: String = "none"
@export var can_crit: bool = true
@export var hit_tags: Array[String] = []
@export var on_hit_statuses: Array[Dictionary] = []


func _apply_impl(context: GameplayContext) -> EffectResult:
	var target := context.target
	if target == null:
		return EffectResult.fail(effect_id, "no_target")
	var health := target.get_node_or_null("Components/HealthComponent") as HealthComponent
	if health == null:
		return EffectResult.fail(effect_id, "no_health_component")

	var request := DamageRequest.new()
	request.source = context.source
	request.target = target
	request.base_amount = base_amount
	request.damage_type = damage_type
	request.element_type = element_type
	request.can_crit = can_crit
	request.tags = hit_tags.duplicate()
	request.on_hit_statuses = on_hit_statuses.duplicate()

	var result := CombatResolver.get_default().resolve(request)
	health.apply_damage(result)

	return EffectResult.ok(effect_id, {
		"final_amount": result.final_amount,
		"was_critical": result.was_critical
	})
