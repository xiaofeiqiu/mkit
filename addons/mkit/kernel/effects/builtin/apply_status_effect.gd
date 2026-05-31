## What: ApplyStatusEffect applies a StatusEffectDefinition to a target StatusEffectController.
## Responsibilities: choose stacks/duration, find the target status controller, and request application.
## Upstream: attacks, spells, items, traps, and rewards can include this effect.
## Downstream: StatusEffectController creates/refreshes StatusEffectInstance objects and runs status effects.
## When to use: Use it for poison, burn, stun, buffs, debuffs, or any timed status driven by content.
## Example: set `status_id = "burning"`, `stacks = 2`, `duration_override = 4.0` on a fire attack effect.
class_name ApplyStatusEffect
extends GameEffect

## Purpose: Inspector-exposed configuration `status_id`.
## Example: `self.status_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var status_id: String = ""
## Purpose: Inspector-exposed configuration `stacks`.
## Example: `self.stacks = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var stacks: int = 1
## Purpose: Inspector-exposed configuration `duration_override`.
## Example: `self.duration_override = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var duration_override: float = -1.0


func _apply_impl(context: GameplayContext) -> EffectResult:
	var target := context.target
	if target == null:
		return EffectResult.fail(effect_id, "no_target")
	var controller := target.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
	if controller == null:
		return EffectResult.fail(effect_id, "no_status_controller")
	var ok := controller.apply_status(status_id, context.source, stacks, duration_override)
	if not ok:
		return EffectResult.fail(effect_id, "apply_failed:%s" % status_id)
	return EffectResult.ok(effect_id, {"status_id": status_id})
