class_name GameEffect
extends Resource
@export var effect_id: String = ""
@export var conditions: Array[Condition] = []
@export var tags: Array[String] = []


func apply(context: GameplayContext) -> EffectResult:
	if not ConditionEvaluator.evaluate_all(conditions, context):
		var failures := ConditionEvaluator.collect_failures(conditions, context)
		return EffectResult.fail(effect_id, ", ".join(failures))
	return _apply_impl(context)


func _apply_impl(context: GameplayContext) -> EffectResult:
	return EffectResult.ok(effect_id)
