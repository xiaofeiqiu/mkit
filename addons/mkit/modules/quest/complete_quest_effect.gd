class_name CompleteQuestEffect
extends GameEffect
@export var quest_id: String = ""
@export var turn_in: bool = true


func _apply_impl(context: GameplayContext) -> EffectResult:
	if quest_id == "":
		return EffectResult.fail(effect_id, "Missing quest_id")
	var quest := ServiceRegistry.get_port(ServiceRegistry.SERVICE_QUEST) as QuestService
	if quest == null:
		return EffectResult.fail(effect_id, "Missing quest service")
	var succeeded := false
	if turn_in:
		var state := quest.get_state(quest_id)
		if state != null and state.status == "completed":
			succeeded = quest.turn_in_quest(quest_id, context)
		else:
			succeeded = quest.complete_quest(quest_id, context)
			state = quest.get_state(quest_id)
			if succeeded and state != null and state.status == "completed":
				succeeded = quest.turn_in_quest(quest_id, context)
	else:
		succeeded = quest.complete_quest(quest_id, context)
	if not succeeded:
		return EffectResult.fail(effect_id, "Quest transition failed: %s" % quest_id)
	return EffectResult.ok(effect_id, {"quest_id": quest_id, "turn_in": turn_in})
