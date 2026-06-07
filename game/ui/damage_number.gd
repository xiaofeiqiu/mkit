extends Node2D


var amount: float = 0.0
var critical: bool = false
@onready var _label: Label = $Label


func _ready() -> void:
	_render()


func setup(value: float, is_critical: bool = false) -> void:
	amount = value
	critical = is_critical
	_render()


func on_pool_acquired() -> void:
	visible = true


func on_pool_released() -> void:
	amount = 0.0
	critical = false
	position = Vector2.ZERO
	_render()


func _render() -> void:
	if _label == null:
		return
	_label.text = "%.0f" % amount
	_label.modulate = Color(1.0, 0.35, 0.2) if critical else Color(1.0, 0.95, 0.25)
