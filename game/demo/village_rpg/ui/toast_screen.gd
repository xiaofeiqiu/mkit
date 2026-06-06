extends Control


var message: String = ""
@onready var _label: Label = $Label


func _ready() -> void:
	_render()


func setup(data: Dictionary) -> void:
	message = str(data.get("message", ""))
	_render()


func _render() -> void:
	if _label != null:
		_label.text = message
