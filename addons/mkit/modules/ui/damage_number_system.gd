class_name DamageNumberSystem
extends Node
@export var damage_number_scene_path: String = ""
@export var default_offset: Vector2 = Vector2(0, -24)


func show_number(position: Vector2, amount: float, critical: bool = false) -> Node:
	if damage_number_scene_path == "":
		return null
	var scene := load(damage_number_scene_path) as PackedScene
	if scene == null:
		return null
	var node := scene.instantiate()
	add_child(node)
	if node is Node2D:
		node.global_position = position + default_offset
	if node.has_method("setup"):
		node.setup(amount, critical)
	return node
