class_name LogEffect
extends GameEffect

# A game-agnostic kernel effect that records that something happened. It emits a
# DomainEvent through the EventRouter (so it shows up in DebugOverlay's recent
# events) and returns a structured EffectResult. It is the minimal effect needed
# to validate the Phase 0 pipeline (command -> state -> action -> effect ->
# event) before combat/inventory effects exist. Concrete games keep using the
# real domain effects (DealDamageEffect, HealEffect, ...) added in later phases.

@export var message: String = "log"
@export var event_type: String = "log"


func _apply_impl(context: GameplayContext) -> EffectResult:
	var source_id := _node_name(context.source)
	var target_id := _node_name(context.target)

	if ServiceRegistry.has_service("events"):
		var events := ServiceRegistry.get_service("events") as EventRouter
		if events != null:
			events.emit_domain_event(DomainEvent.create(event_type, source_id, target_id, {
				"message": message,
			}))

	print("[LogEffect] %s (source=%s target=%s)" % [message, source_id, target_id])
	return EffectResult.ok(effect_id, {"message": message, "event_type": event_type})


func _node_name(node: Node) -> String:
	if node == null:
		return ""
	return str(node.name)
