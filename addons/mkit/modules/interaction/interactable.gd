class_name Interactable
extends Node
@export var interaction_id: String = ""
@export var display_text: String = "Interact"
@export var conditions: Array[Condition] = []


func can_interact(context: GameplayContext) -> bool:
	return ConditionEvaluator.evaluate_all(conditions, context)


func interact(context: GameplayContext) -> bool:
	if not can_interact(context):
		return false
	return _interact_impl(context)


func _interact_impl(context: GameplayContext) -> bool:
	return true
