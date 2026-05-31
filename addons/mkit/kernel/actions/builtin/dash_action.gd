class_name DashAction
extends GameAction

## Purpose: Public runtime field `duration`.
## Example: `self.duration = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var duration: float = 0.18
## Purpose: Public runtime field `speed`.
## Example: `self.speed = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var speed: float = 480.0
## Purpose: Public runtime field `direction`.
## Example: `self.direction = Vector2.ZERO`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var direction: Vector2 = Vector2.ZERO


func _on_start() -> void:
	action_id = "dash"
	cancel_tags = ["stun", "death"]
	direction = context.direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT


func _on_update(delta: float) -> void:
	if context.source == null:
		complete()
		return

	var body := context.source as CharacterBody2D
	if body != null:
		body.velocity = direction * speed
		body.move_and_slide()

	if elapsed >= duration:
		complete()


func _on_complete() -> void:
	var body := context.source as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO
