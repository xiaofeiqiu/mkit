class_name DealDamageEffect
extends GameEffect

## Purpose: Inspector-exposed configuration `base_amount`.
## Example: `self.base_amount = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var base_amount: float = 10.0
## Purpose: Inspector-exposed configuration `damage_type`.
## Example: `self.damage_type = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var damage_type: String = "physical"
## Purpose: Inspector-exposed configuration `element_type`.
## Example: `self.element_type = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var element_type: String = "none"
## Purpose: Inspector-exposed configuration `can_crit`.
## Example: `self.can_crit = true`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var can_crit: bool = true
## Purpose: Inspector-exposed configuration `hit_tags`.
## Example: `self.hit_tags = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var hit_tags: Array[String] = []
## Purpose: Inspector-exposed configuration `on_hit_statuses`.
## Example: `self.on_hit_statuses = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
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
