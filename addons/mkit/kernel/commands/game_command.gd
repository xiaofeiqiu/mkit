class_name GameCommand
extends RefCounted

var command_id: String = ""
var command_type: String = ""
var source_id: String = ""
var target_id: String = ""
var timestamp: float = 0.0
var priority: int = 0
var payload: Dictionary = {}
var consumed: bool = false


static func create(type: String, source: String = "", target: String = "", data: Dictionary = {}) -> GameCommand:
	var cmd := GameCommand.new()
	cmd.command_type = type
	cmd.command_id = "%s_%d" % [type, Time.get_ticks_usec()]
	cmd.source_id = source
	cmd.target_id = target
	cmd.timestamp = Time.get_ticks_msec() / 1000.0
	cmd.payload = data
	return cmd


func mark_consumed() -> void:
	consumed = true


func get_vector2(key: String, default_value: Vector2 = Vector2.ZERO) -> Vector2:
	if payload.has(key):
		return payload[key]
	return default_value


func get_string(key: String, default_value: String = "") -> String:
	if payload.has(key):
		return str(payload[key])
	return default_value


func get_float(key: String, default_value: float = 0.0) -> float:
	if payload.has(key):
		return float(payload[key])
	return default_value
