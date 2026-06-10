class_name EntitySaveAgent
extends Node

const ENTITY_SAVE_PARTICIPANT_GROUP: String = "mkit_entity_save_participant"
@export var entity_id: String = ""
@export var scene_path: String = ""
@export var zone_id: String = ""
@export var root_path: NodePath = NodePath("")
@export var restore_order: int = 0
@export var include_duck_participants: bool = true
var _last_errors: Array[String] = []


func get_entity_id() -> String:
	return entity_id.strip_edges()


func to_entity_save_record() -> Dictionary:
	_last_errors.clear()
	var root := _resolve_root()
	var components: Dictionary = {}
	if root == null:
		_last_errors.append("missing entity root: %s" % get_entity_id())
		return _make_record(components)
	for node in _collect_participants(root):
		var key := str(node.call("get_save_key")).strip_edges()
		if key == "":
			_last_errors.append("empty component save key on entity: %s" % get_entity_id())
			continue
		if components.has(key):
			_last_errors.append(
				"duplicate component save key: %s on entity: %s" % [key, get_entity_id()]
			)
			continue
		var raw_data = node.call("to_save_data")
		if not (raw_data is Dictionary):
			_last_errors.append(
				"component save data is not a Dictionary: %s on entity: %s"
				% [key, get_entity_id()]
			)
			continue
		components[key] = raw_data
	return _make_record(components)


func apply_entity_save_record(record: Dictionary) -> void:
	_last_errors.clear()
	var root := _resolve_root()
	if root == null:
		_last_errors.append("missing entity root: %s" % get_entity_id())
		return
	var raw_components = record.get("components", {})
	var components: Dictionary = {}
	if raw_components is Dictionary:
		components = raw_components
	var restored: Dictionary = {}
	for node in _collect_participants(root):
		var key := str(node.call("get_save_key")).strip_edges()
		if key == "" or not components.has(key):
			continue
		var raw_data = components[key]
		if raw_data is Dictionary:
			node.call("from_save_data", raw_data)
			restored[key] = true
	for raw_key in components.keys():
		var key := str(raw_key)
		if not restored.has(key):
			_last_errors.append(
				"missing component for save key: %s on entity: %s" % [key, get_entity_id()]
			)


func has_save_errors() -> bool:
	return not _last_errors.is_empty()


func get_save_errors() -> Array[String]:
	var result: Array[String] = []
	for error in _last_errors:
		result.append(error)
	return result


func _make_record(components: Dictionary) -> Dictionary:
	return {
		"scene_path": scene_path,
		"zone_id": zone_id,
		"components": components,
	}


func _resolve_root() -> Node:
	if root_path != NodePath(""):
		var explicit := get_node_or_null(root_path)
		if explicit != null:
			return explicit
	if owner != null:
		return owner
	return get_parent()


func _collect_participants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for node in root.find_children("*", "", true, false):
		if node == self:
			continue
		if _is_participant(node):
			result.append(node)
	return result


func _is_participant(node: Node) -> bool:
	if node is SaveableComponent:
		return true
	return (
		include_duck_participants
		and node.is_in_group(ENTITY_SAVE_PARTICIPANT_GROUP)
		and node.has_method("get_save_key")
		and node.has_method("to_save_data")
		and node.has_method("from_save_data")
	)
