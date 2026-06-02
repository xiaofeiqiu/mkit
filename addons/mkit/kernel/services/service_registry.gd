extends Node
var _services: Dictionary = {}
var _service_types: Dictionary = {}


func register_service(
	service_id: String, service: Object, expected_class_name: String = ""
) -> void:
	if service_id.strip_edges() == "":
		push_warning("ServiceRegistry.register_service: service_id is empty")
		return
	if service == null:
		push_warning("ServiceRegistry.register_service: service is null for id %s" % service_id)
		return
	if _services.has(service_id):
		push_warning("Service already registered: %s. It will be replaced." % service_id)
	_services[service_id] = service
	if expected_class_name != "":
		_service_types[service_id] = expected_class_name


func has_service(service_id: String) -> bool:
	if service_id.strip_edges() == "":
		return false
	return _services.has(service_id)


func get_service(service_id: String) -> Object:
	if service_id.strip_edges() == "":
		push_warning("ServiceRegistry.get_service: service_id is empty")
		return null
	if not _services.has(service_id):
		push_warning("Missing service: %s" % service_id)
		return null
	return _services[service_id]


func get_typed(service_id: String, expected_class_name: String) -> Object:
	var service := get_service(service_id)
	if service == null:
		return null
	if (
		expected_class_name != ""
		and service.get_class() != expected_class_name
		and not service.is_class(expected_class_name)
	):
		push_warning(
			"Service %s may not match expected type %s" % [service_id, expected_class_name]
		)
	return service


func unregister_service(service_id: String) -> void:
	if service_id.strip_edges() == "":
		push_warning("ServiceRegistry.unregister_service: service_id is empty")
		return
	_services.erase(service_id)
	_service_types.erase(service_id)


func clear() -> void:
	_services.clear()
	_service_types.clear()
