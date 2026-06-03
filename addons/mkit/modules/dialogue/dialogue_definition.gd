class_name DialogueDefinition
extends Resource
@export var dialogue_id: String = ""
@export var start_node_id: String = ""
@export var nodes: Array[DialogueNode] = []


func get_resource_id() -> String:
	return dialogue_id


func get_node(node_id: String) -> DialogueNode:
	for node in nodes:
		if node != null and node.node_id == node_id:
			return node
	return null
