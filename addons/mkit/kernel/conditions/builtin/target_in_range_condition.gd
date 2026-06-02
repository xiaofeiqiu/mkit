class_name TargetInRangeCondition
extends Condition
@export var range: float = 64.0


func _evaluate_impl(context: GameplayContext) -> bool:
	var source_2d := context.source as Node2D
	var target_2d := context.target as Node2D
	if source_2d == null or target_2d == null:
		return false
	return source_2d.global_position.distance_to(target_2d.global_position) <= range


func get_failure_reason(context: GameplayContext) -> String:
	return "target_out_of_range"
