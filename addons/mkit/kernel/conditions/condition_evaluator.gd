class_name ConditionEvaluator
extends RefCounted


static func evaluate_all(conditions: Array[Condition], context: GameplayContext) -> bool:
	for condition in conditions:
		if condition == null:
			continue
		if not condition.evaluate(context):
			return false
	return true


static func collect_failures(conditions: Array[Condition], context: GameplayContext) -> Array[String]:
	var failures: Array[String] = []
	for condition in conditions:
		if condition != null and not condition.evaluate(context):
			failures.append(condition.get_failure_reason(context))
	return failures
