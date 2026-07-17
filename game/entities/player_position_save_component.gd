extends SaveableComponent


func get_save_key() -> String:
	return "Position"


func to_save_data() -> Dictionary:
	var target := _target()
	if target is Node2D:
		var node := target as Node2D
		return {
			"x": node.global_position.x,
			"y": node.global_position.y
		}
	return {}


func from_save_data(data: Dictionary) -> void:
	var target := _target()
	if not (target is Node2D):
		return
	var node := target as Node2D
	node.global_position = Vector2(
		float(data.get("x", node.global_position.x)),
		float(data.get("y", node.global_position.y))
	)


func _target() -> Node:
	if owner != null:
		return owner
	return get_parent()
