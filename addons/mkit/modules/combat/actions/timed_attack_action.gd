class_name TimedAttackAction
extends GameAction
var startup_duration: float = 0.12
var active_duration: float = 0.10
var recovery_duration: float = 0.25
var hitbox_component_name: StringName = &"HitboxComponent"
var hitbox_path: NodePath = NodePath("")
var _hitbox_enabled: bool = false


func _on_start() -> void:
	action_id = "timed_attack"
	cancel_tags = ["dash", "stun", "death"]
	_play_animation("attack")
	_set_hitbox_enabled(false)


func _on_update(delta: float) -> void:
	var total_active_start := startup_duration
	var total_active_end := startup_duration + active_duration
	var total_end := startup_duration + active_duration + recovery_duration
	if elapsed >= total_active_start and elapsed < total_active_end:
		if not _hitbox_enabled:
			_set_hitbox_enabled(true)
	else:
		if _hitbox_enabled:
			_set_hitbox_enabled(false)
	if elapsed >= total_end:
		complete()


func _on_cancel(reason: String) -> void:
	_set_hitbox_enabled(false)


func _on_complete() -> void:
	_set_hitbox_enabled(false)


func _set_hitbox_enabled(enabled: bool) -> void:
	_hitbox_enabled = enabled
	if context == null or context.source == null:
		return
	var hitbox: HitboxComponent = null
	if hitbox_path != NodePath(""):
		var hitbox_node := context.source.get_node_or_null(hitbox_path) as Node
		hitbox = hitbox_node as HitboxComponent
	if hitbox == null:
		hitbox = EntityContract.get_component(context.source, hitbox_component_name) as HitboxComponent
	if hitbox != null:
		hitbox.set_active(enabled)


func _play_animation(anim_name: String) -> void:
	if context == null or context.source == null:
		return
	var anim := EntityContract.get_contract_node(context.source, "Presentation", "AnimationPlayer") as AnimationPlayer
	if anim != null and anim.has_animation(anim_name):
		anim.play(anim_name)
