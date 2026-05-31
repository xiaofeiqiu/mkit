## What: CooldownReadyCondition checks whether an ability is registered and off cooldown on the source entity.
## Responsibilities: find AbilityController, inspect cooldown remaining, and provide a failure reason.
## Upstream: AbilityDefinition conditions or custom ability gates reference this resource.
## Downstream: ConditionEvaluator invokes it before casts or effect execution.
## When to use: Use it when content wants an explicit reusable cooldown gate separate from AbilityController.can_cast().
## Example: set `ability_id = "blink"` and include this condition on an item that refreshes only when Blink is ready.
class_name CooldownReadyCondition
extends Condition

## Purpose: Inspector-exposed configuration `ability_id`.
## Example: `self.ability_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var ability_id: String = ""


func _evaluate_impl(context: GameplayContext) -> bool:
	var id := ability_id if ability_id != "" else context.ability_id
	if id == "" or context.source == null:
		return false
	var controller := context.source.get_node_or_null("Controllers/AbilityController") as AbilityController
	if controller == null:
		return false
	return controller.is_cooldown_ready(id)


## Purpose: Public method `get_failure_reason` for external gameplay integration.
## Example: `self.get_failure_reason(<_context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_failure_reason(_context: GameplayContext) -> String:
	return "Cooldown not ready: %s" % ability_id
