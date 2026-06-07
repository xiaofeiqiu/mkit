class_name CooldownReadyCondition
extends Condition
@export var ability_id: String = ""


func _evaluate_impl(context: GameplayContext) -> bool:
	var id := ability_id if ability_id != "" else context.ability_id
	if id == "" or context.source == null:
		return false
	var controller := (
		EntityContract.get_controller(context.source, "AbilityController") as AbilityController
	)
	if controller == null:
		return false
	return controller.is_cooldown_ready(id)


func get_failure_reason(_context: GameplayContext) -> String:
	return "Cooldown not ready: %s" % ability_id
