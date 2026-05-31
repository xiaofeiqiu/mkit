class_name Condition
extends Resource

@export var condition_id: String = ""
@export var invert: bool = false


func evaluate(context: GameplayContext) -> bool:
	var result := _evaluate_impl(context)
	if invert:
		return not result
	return result


func _evaluate_impl(context: GameplayContext) -> bool:
	return true


func get_failure_reason(context: GameplayContext) -> String:
	return "Condition failed: %s" % condition_id
