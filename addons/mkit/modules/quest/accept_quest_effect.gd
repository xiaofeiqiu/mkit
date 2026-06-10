class_name AcceptQuestEffect
extends GameEffect
@export var quest_id: String = ""


func _apply_impl(context: GameplayContext) -> EffectResult:
	if quest_id == "":
		return EffectResult.fail(effect_id, "Missing quest_id")
	var quest := Mkit.quest()
	if quest == null:
		return EffectResult.fail(effect_id, "Missing quest service")
	if not quest.accept_quest(quest_id, context):
		return EffectResult.fail(effect_id, "Cannot accept quest: %s" % quest_id)
	return EffectResult.ok(effect_id, {"quest_id": quest_id})
