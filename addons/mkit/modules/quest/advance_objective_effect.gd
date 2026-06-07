class_name AdvanceObjectiveEffect
extends GameEffect
@export var quest_id: String = ""
@export var objective_id: String = ""
@export var amount: int = 1


func _apply_impl(context: GameplayContext) -> EffectResult:
	if quest_id == "":
		return EffectResult.fail(effect_id, "Missing quest_id")
	var quest := ServiceRegistry.get_port(ServiceRegistry.SERVICE_QUEST) as QuestService
	if quest == null:
		return EffectResult.fail(effect_id, "Missing quest service")
	if not quest.advance_objective(quest_id, objective_id, amount):
		return EffectResult.fail(effect_id, "Objective transition failed: %s" % objective_id)
	return EffectResult.ok(
		effect_id, {"quest_id": quest_id, "objective_id": objective_id, "amount": amount}
	)
