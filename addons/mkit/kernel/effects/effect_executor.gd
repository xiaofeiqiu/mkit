class_name EffectExecutor
extends RefCounted
var trace_enabled: bool = true
var recent_results: Array[EffectResult] = []
var max_recent_results: int = 100


func execute(effect: GameEffect, context: GameplayContext) -> EffectResult:
	if effect == null:
		return EffectResult.fail("null_effect", "Effect is null")
	var result := effect.apply(context)
	_record_result(result)
	return result


func execute_many(
	effects: Array[GameEffect], context: GameplayContext, stop_on_failure: bool = false
) -> Array[EffectResult]:
	var results: Array[EffectResult] = []
	for effect in effects:
		var result := execute(effect, context)
		results.append(result)
		if stop_on_failure and not result.success:
			break
	return results


func clear_recent_results() -> void:
	recent_results.clear()


func _record_result(result: EffectResult) -> void:
	if not trace_enabled:
		return
	recent_results.append(result)
	if recent_results.size() > max_recent_results:
		recent_results.pop_front()
