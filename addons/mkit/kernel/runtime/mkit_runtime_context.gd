class_name MkitRuntimeContext
extends RefCounted

var _ports: Dictionary = {}


func register_port(service_id: String, service: Object, expected_class_name: String = "") -> void:
	var normalized_service_id := service_id.strip_edges()
	if normalized_service_id == "":
		push_warning("MkitRuntimeContext.register_port: service_id is empty")
		return
	if service == null:
		push_warning("MkitRuntimeContext.register_port: service is null for %s" % service_id)
		return
	if expected_class_name != "":
		var normalized_expected_class_name := expected_class_name.strip_edges()
		if normalized_expected_class_name != "":
			var service_class := service.get_class()
			if service_class != normalized_expected_class_name and not service.is_class(normalized_expected_class_name):
				push_warning("MkitRuntimeContext.register_port: %s type mismatch. expected=%s actual=%s" % [normalized_service_id, normalized_expected_class_name, service_class])
	_ports[normalized_service_id] = service


func unregister_port(service_id: String) -> void:
	var normalized_service_id := service_id.strip_edges()
	if normalized_service_id == "":
		push_warning("MkitRuntimeContext.unregister_port: service_id is empty")
		return
	_ports.erase(normalized_service_id)


func has_port(service_id: String) -> bool:
	var normalized_service_id := service_id.strip_edges()
	if normalized_service_id == "":
		return false
	return _ports.has(normalized_service_id)


func get_port(service_id: String) -> Object:
	var normalized_service_id := service_id.strip_edges()
	if normalized_service_id == "":
		push_warning("MkitRuntimeContext.get_port: service_id is empty")
		return null
	var service := _ports.get(normalized_service_id, null)
	if service == null:
		push_warning("MkitRuntimeContext.get_port: missing %s" % normalized_service_id)
	return service


func get_port_typed(service_id: String, expected_class_name: String) -> Object:
	var service := get_port(service_id) as Object
	if service == null:
		return null
	if expected_class_name != "":
		var normalized_expected_class_name := expected_class_name.strip_edges()
		var service_class := service.get_class()
		if normalized_expected_class_name != "" and service_class != normalized_expected_class_name and not service.is_class(normalized_expected_class_name):
			push_warning("MkitRuntimeContext.get_port_typed: %s expected %s actual %s" % [service_id, normalized_expected_class_name, service_class])
	return service


func get_registered_ports() -> Array[String]:
	var ids: Array[String] = []
	for service_id in _ports.keys():
		ids.append(str(service_id))
	ids.sort()
	return ids
