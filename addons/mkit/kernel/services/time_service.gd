class_name TimeService
extends RefCounted
var paused: bool = false
var gameplay_time_scale: float = 1.0
var elapsed_gameplay_time: float = 0.0


func set_paused(value: bool) -> void:
	paused = value


func set_gameplay_time_scale(value: float) -> void:
	gameplay_time_scale = max(0.0, value)


func get_scaled_delta(delta: float) -> float:
	if paused:
		return 0.0
	return delta * gameplay_time_scale


func advance(delta: float) -> float:
	var scaled := get_scaled_delta(delta)
	elapsed_gameplay_time += scaled
	return scaled


func get_unix_time() -> int:
	return Time.get_unix_time_from_system()
