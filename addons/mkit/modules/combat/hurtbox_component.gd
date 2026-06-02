class_name HurtboxComponent
extends Area2D
@export var owner_path: NodePath = NodePath("../..")
@export var can_receive_damage: bool = true
@export var damage_multiplier: float = 1.0
@export var damage_tags: Array[String] = []


func get_owner_entity() -> Node:
	return get_node_or_null(owner_path)
