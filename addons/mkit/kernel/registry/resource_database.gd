class_name ResourceDatabase
extends Resource

@export var database_id: String = ""
@export var resources: Array[Resource] = []
@export var resource_paths: Array[String] = []


func get_all_resources() -> Array[Resource]:
	var result: Array[Resource] = []
	result.append_array(resources)

	for path in resource_paths:
		var res := load(path)
		if res != null:
			result.append(res)
		else:
			push_warning("Failed to load resource: %s" % path)

	return result
