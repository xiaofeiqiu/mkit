class_name CastAction
extends GameAction

## Purpose: Public runtime field `duration`.
## Example: `self.duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var duration: float = 0.0
## Purpose: Public runtime field `animation_name`.
## Example: `self.animation_name = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var animation_name: String = "cast"
var _started_animation: bool = false


func _on_start() -> void:
	action_id = "cast"
	cancel_tags = ["stun", "death", "silence"]
	context.duration = duration
	_play_animation()


func _on_update(delta: float) -> void:
	if context == null or context.source == null:
		cancel("missing_source")
		return
	context.elapsed = elapsed
	if elapsed >= duration:
		complete()


func _on_cancel(reason: String) -> void:
	_stop_cast_feedback()


func _on_complete() -> void:
	_stop_cast_feedback()


func _play_animation() -> void:
	if _started_animation or context == null or context.source == null:
		return
	var anim := context.source.get_node_or_null("Presentation/AnimationPlayer") as AnimationPlayer
	if anim != null and animation_name != "":
		anim.play(animation_name)
	_started_animation = true


func _stop_cast_feedback() -> void:
	if context == null or context.source == null:
		return
	if context.source.has_method("on_cast_action_finished"):
		context.source.call("on_cast_action_finished", self)
