## What: TargetInRangeCondition checks whether context source and target nodes are close enough.
## Responsibilities: read node positions, compare distance against range, and provide a clear failure reason.
## Upstream: abilities, items, loot, rewards, or effects include it in their conditions arrays.
## Downstream: ConditionEvaluator calls it before allowing a cast or effect execution.
## When to use: Use it for melee attacks, short-range spells, interactions, or pickups that need distance gating.
## Example: set `range = 96.0` on a melee AbilityDefinition condition before `AbilityController.cast("slash", ctx)`.
class_name TargetInRangeCondition
extends Condition

## Purpose: Inspector-exposed configuration `range`.
## Example: `self.range = 1.0`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var range: float = 64.0


func _evaluate_impl(context: GameplayContext) -> bool:
	var source_2d := context.source as Node2D
	var target_2d := context.target as Node2D
	if source_2d == null or target_2d == null:
		return false
	return source_2d.global_position.distance_to(target_2d.global_position) <= range


## Purpose: Public method `get_failure_reason` for external gameplay integration.
## Example: `self.get_failure_reason(<context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_failure_reason(context: GameplayContext) -> String:
	return "target_out_of_range"
