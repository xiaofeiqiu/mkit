class_name DialogueInteractable
extends Interactable
@export var dialogue_id: String = ""
@export var npc_id: String = ""


func _interact_impl(context: GameplayContext) -> bool:
	if dialogue_id == "":
		return false
	if not ServiceRegistry.has_service("dialogue"):
		return false
	var dialogue := ServiceRegistry.get_service("dialogue") as DialogueService
	if dialogue == null:
		return false
	if not dialogue.start(dialogue_id, context):
		return false
	if npc_id != "":
		var events := _get_events()
		if events != null:
			events.emit_npc_talked(npc_id)
	return true


func _get_events() -> EventService:
	if ServiceRegistry.has_service("events"):
		return ServiceRegistry.get_service("events") as EventService
	return null
