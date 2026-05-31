class_name DemoWaitAction
extends GameAction

# Minimal time-based action used by the Phase 0 demo to prove the
# State -> Action -> (completed) -> Effect path. A real game would use
# TimedAttackAction / CastAction here once the combat module exists.

var duration: float = 0.3


func _on_start() -> void:
	action_id = "demo_wait"
	cancel_tags = ["stun", "death"]
	print("[DemoWaitAction] started (duration=%.2fs)" % duration)


func _on_update(delta: float) -> void:
	if elapsed >= duration:
		complete()


func _on_complete() -> void:
	print("[DemoWaitAction] completed")
