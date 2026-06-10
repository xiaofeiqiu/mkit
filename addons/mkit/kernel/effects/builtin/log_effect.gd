class_name LogEffect
extends GameEffect
@export var message: String = "log"
@export var event_type: String = "log"


func _apply_impl(context: GameplayContext) -> EffectResult:
	var source_id := _node_name(context.source)
	var target_id := _node_name(context.target)
	var events := EventService.find()
	if events != null:
		events.emit_domain_event(
			DomainEvent.create(event_type, source_id, target_id, {"message": message})
		)
	print("[LogEffect] %s (source=%s target=%s)" % [message, source_id, target_id])
	return EffectResult.ok(effect_id, {"message": message, "event_type": event_type})


func _node_name(node: Node) -> String:
	if node == null:
		return ""
	return str(node.name)
