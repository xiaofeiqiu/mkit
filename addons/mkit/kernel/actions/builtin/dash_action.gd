class_name DashAction
extends GameAction

var duration: float = 0.18
var speed: float = 480.0
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
