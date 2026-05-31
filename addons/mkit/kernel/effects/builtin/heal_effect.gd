## What: HealEffect restores HP on the source or target carried by a GameplayContext.
## Responsibilities: locate a HealthComponent, apply a fixed heal amount, and return an EffectResult.
## Upstream: consumables, shrine rewards, support abilities, or status effects include this effect.
## Downstream: HealthComponent emits healed/health_changed and any UI listening to health updates refreshes.
## When to use: Use it when a content resource should restore health without custom script code.
## Example: set `base_amount = 50` on a potion ItemDefinition use_effect.
class_name HealEffect
extends GameEffect

## Purpose: Inspector-exposed configuration `base_amount`.
## Example: `self.base_amount = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var base_amount: float = 20.0


func _apply_impl(context: GameplayContext) -> EffectResult:
	var target := context.target if context.target != null else context.source
	if target == null:
		return EffectResult.fail(effect_id, "no_target")
	var health := target.get_node_or_null("Components/HealthComponent") as HealthComponent
	if health == null:
		return EffectResult.fail(effect_id, "no_health_component")
	health.heal(base_amount, context.source)
	return EffectResult.ok(effect_id, {"healed_amount": base_amount})
