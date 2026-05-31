## What: ConditionEvaluator is a static helper for checking arrays of Condition resources.
## Responsibilities: evaluate all conditions and collect failure reasons for UI or logs.
## Upstream: AbilityController, LootSystem, RewardSystem, ItemDefinition usage, and tests pass condition arrays.
## Downstream: Condition subclasses such as CooldownReadyCondition and TargetInRangeCondition perform specific checks.
## When to use: Use it when content has multiple gates that must all pass before execution.
## Example: `if ConditionEvaluator.evaluate_all(ability.conditions, ctx): ability_controller.cast("fireball", ctx)`.
class_name ConditionEvaluator
extends RefCounted


## Purpose: Public method `evaluate_all` for external gameplay integration.
## Example: `ConditionEvaluator.evaluate_all(<conditions>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func evaluate_all(conditions: Array[Condition], context: GameplayContext) -> bool:
	for condition in conditions:
		if condition == null:
			continue
		if not condition.evaluate(context):
			return false
	return true


## Purpose: Public method `collect_failures` for external gameplay integration.
## Example: `ConditionEvaluator.collect_failures(<conditions>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
static func collect_failures(conditions: Array[Condition], context: GameplayContext) -> Array[String]:
	var failures: Array[String] = []
	for condition in conditions:
		if condition != null and not condition.evaluate(context):
			failures.append(condition.get_failure_reason(context))
	return failures
