class_name DialogueInteractable
extends Interactable
@export var dialogue_id: String = ""
@export var npc_id: String = ""


func _interact_impl(context: GameplayContext) -> bool:
	if dialogue_id == "":
		return false
	var dialogue := ServiceRegistry.get_port(ServiceRegistry.SERVICE_DIALOGUE) as DialogueService
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
	var events := ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService
	if events != null:
		return events
	return null
