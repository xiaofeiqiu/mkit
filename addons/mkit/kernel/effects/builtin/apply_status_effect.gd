class_name ApplyStatusEffect
extends GameEffect

@export var status_id: String = ""
@export var stacks: int = 1
@export var duration_override: float = -1.0


func _apply_impl(context: GameplayContext) -> EffectResult:
	var target := context.target
	if target == null:
		return EffectResult.fail(effect_id, "no_target")
	var controller := target.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
	if controller == null:
		return EffectResult.fail(effect_id, "no_status_controller")
	var ok := controller.apply_status(status_id, context.source, stacks, duration_override)
	if not ok:
		return EffectResult.fail(effect_id, "apply_failed:%s" % status_id)
	return EffectResult.ok(effect_id, {"status_id": status_id})
