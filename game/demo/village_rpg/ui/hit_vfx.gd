extends Node2D


var play_count: int = 0
var direction: Vector2 = Vector2.ZERO


func play() -> void:
	play_count += 1
	visible = true


func set_direction(value: Vector2) -> void:
	direction = value
	rotation = value.angle() if value != Vector2.ZERO else 0.0


func on_pool_acquired() -> void:
	visible = true


func on_pool_released() -> void:
	visible = false
	direction = Vector2.ZERO
	rotation = 0.0
