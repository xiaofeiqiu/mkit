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
