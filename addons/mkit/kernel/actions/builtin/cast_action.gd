## What: CastAction is a timed GameAction for abilities that have wind-up or casting feedback before effects resolve.
## Responsibilities: wait for duration, optionally play/stop cast feedback, and complete or cancel cleanly.
## Upstream: AbilityController creates it when an AbilityDefinition has cast_time greater than zero.
## Downstream: ActionRunner ticks it and AbilityController listens for completed/cancelled to finish the cast.
## When to use: Use it for spells or interact actions that should be interruptible before applying effects.
## Example: an ability with `ability_id = "meteor"` and `cast_time = 1.2` runs CastAction before damage is applied.
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
