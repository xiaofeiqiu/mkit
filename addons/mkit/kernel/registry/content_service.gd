class_name ContentService
extends Node
var _by_id: Dictionary = {}
var _by_type: Dictionary = {}
var _resource_path_by_id: Dictionary = {}


func load_database(database: ResourceDatabase) -> void:
	for res in database.get_all_resources():
		register_resource(res)


func register_resource(res: Resource) -> void:
	var content_id := _extract_content_id(res)
	if content_id == "":
		push_error("Resource missing stable content id: %s" % res)
		return
	if _by_id.has(content_id):
		push_error("Duplicate content id: %s" % content_id)
		return
	_by_id[content_id] = res
	var type_name := _get_resource_type_name(res)
	if not _by_type.has(type_name):
		_by_type[type_name] = []
	_by_type[type_name].append(res)
	if res.resource_path != "":
		_resource_path_by_id[content_id] = res.resource_path


func get_resource(content_id: String) -> Resource:
	if not _by_id.has(content_id):
		push_warning("Content id not found: %s" % content_id)
		return null
	return _by_id[content_id]


func get_typed_resource(content_id: String, expected_script: Script) -> Resource:
	var res := get_resource(content_id)
	if res == null:
		return null
	if expected_script != null and res.get_script() != expected_script:
		push_error("ContentService: type mismatch for '%s'" % content_id)
		return null
	return res


func get_all_by_type(type_name: String) -> Array:
	if not _by_type.has(type_name):
		return []
	return _by_type[type_name]


func has(content_id: String) -> bool:
	return _by_id.has(content_id)


func validate_all() -> ContentValidationResult:
	var result := ContentValidationResult.new()
	result.success = true
	for id in _by_id.keys():
		var res: Resource = _by_id[id]
		if id == "":
			result.add_error("Empty content id")
		if res == null:
			result.add_error("Null resource for id %s" % id)
	return result


func _extract_content_id(res: Resource) -> String:
	var def := res as ContentDefinition
	if def == null:
		return ""
	return def.get_content_id()


func _get_resource_type_name(res: Resource) -> String:
	if res == null:
		return "Unknown"
	var script := res.get_script() as Script
	if script != null and script.resource_path != "":
		return script.resource_path.get_file().get_basename()
	return res.get_class()
