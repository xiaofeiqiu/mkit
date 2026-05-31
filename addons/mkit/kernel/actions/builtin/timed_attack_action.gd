## What: TimedAttackAction models an attack with startup, active, and recovery phases.
## Responsibilities: tick phase timing, enable/disable the configured HitboxComponent, and play matching animation hooks.
## Upstream: StateMachine states, input commands, or AI behavior start it through ActionRunner.
## Downstream: HitboxComponent scans overlaps during the active window and combat systems resolve hits.
## When to use: Use it for melee attacks or short active-window hitboxes that need deterministic timing.
## Example: set `startup_duration = 0.12`, `active_duration = 0.10`, `recovery_duration = 0.25` for a sword slash action.
class_name TimedAttackAction
extends GameAction

# Melee attack with startup / active / recovery windows. The hitbox is only
# enabled during the active window. Lives in the kernel because the timing
# pattern is reusable; it talks to HitboxComponent (combat module) but only
# through set_active(), so it stays a thin, content-agnostic action.

## Purpose: Public runtime field `startup_duration`.
## Example: `self.startup_duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var startup_duration: float = 0.12
## Purpose: Public runtime field `active_duration`.
## Example: `self.active_duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var active_duration: float = 0.10
## Purpose: Public runtime field `recovery_duration`.
## Example: `self.recovery_duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var recovery_duration: float = 0.25
## Purpose: Public runtime field `hitbox_path`.
## Example: `self.hitbox_path = NodePath(".")`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var hitbox_path: NodePath = NodePath("Components/HitboxComponent")
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
	var hitbox := context.source.get_node_or_null(hitbox_path) as HitboxComponent
	if hitbox != null:
		hitbox.set_active(enabled)


func _play_animation(anim_name: String) -> void:
	if context == null or context.source == null:
		return
	var anim := context.source.get_node_or_null("Presentation/AnimationPlayer") as AnimationPlayer
	if anim != null and anim.has_animation(anim_name):
		anim.play(anim_name)
