extends Node

var _runtime_context: MkitRuntimeContext
const SERVICE_EVENTS: String = "events"
const SERVICE_CONTENT: String = "content"
const SERVICE_RANDOM: String = "random"
const SERVICE_TIME: String = "time"
const SERVICE_ACTIONS: String = "actions"
const SERVICE_EFFECTS: String = "effects"
const SERVICE_COMMANDS: String = "commands"
const SERVICE_COMBAT: String = "combat"
const SERVICE_SCENES: String = "scenes"
const SERVICE_POOL: String = "pool"
const SERVICE_SAVE: String = "save"
const SERVICE_PROGRESSION: String = "progression"
const SERVICE_ANALYTICS: String = "analytics"
const SERVICE_ADS: String = "ads"
const SERVICE_IAP: String = "iap"
const SERVICE_CLOUD_SAVE: String = "cloud_save"
const SERVICE_QUEST: String = "quest"
const SERVICE_SHOP: String = "shop"
const SERVICE_AUDIO: String = "audio"
const SERVICE_DIALOGUE: String = "dialogue"
const SERVICE_WORLD: String = "world"
const SERVICE_LOOT: String = "loot"
const SERVICE_UI: String = "ui"

var _services: Dictionary = {}
var _service_types: Dictionary = {}


func register_service(
	service_id: String, service: Object, expected_class_name: String = ""
) -> void:
	var normalized_service_id := service_id.strip_edges()
	if normalized_service_id == "":
		push_warning("ServiceRegistry.register_service: service_id is empty")
		return
	if service == null:
		push_warning("ServiceRegistry.register_service: service is null for id %s" % service_id)
		return
	if _services.has(normalized_service_id):
		push_warning("Service already registered: %s. It will be replaced." % normalized_service_id)
	_services[normalized_service_id] = service
	if expected_class_name != "":
		_service_types[normalized_service_id] = expected_class_name
	if _runtime_context != null:
		_runtime_context.register_port(normalized_service_id, service, expected_class_name)


func has_service(service_id: String) -> bool:
	var normalized_service_id := service_id.strip_edges()
	if normalized_service_id == "":
		return false
	return _services.has(normalized_service_id)


func get_service(service_id: String) -> Object:
	var service := get_service_or_null(service_id)
	if service == null and service_id.strip_edges() != "":
		push_warning("Missing service: %s" % service_id)
	return service


func get_service_or_null(service_id: String) -> Object:
	var normalized_service_id := service_id.strip_edges()
	if normalized_service_id == "":
		push_warning("ServiceRegistry.get_service: service_id is empty")
		return null
	if not _services.has(normalized_service_id):
		return null
	return _services[normalized_service_id]


func get_required_service(service_id: String, context: String = "ServiceRegistry") -> Object:
	var service := get_service_or_null(service_id)
	if service == null:
		push_error("%s: required service not found: %s" % [context, service_id.strip_edges()])
	return service


func get_typed(service_id: String, expected_class_name: String) -> Object:
	var service := get_service_or_null(service_id)
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


func get_registered_service_ids() -> Array[String]:
	var ids: Array[String] = []
	for service_id in _services.keys():
		ids.append(str(service_id))
	ids.sort()
	return ids


func unregister_service(service_id: String) -> void:
	if service_id.strip_edges() == "":
		push_warning("ServiceRegistry.unregister_service: service_id is empty")
		return
	_services.erase(service_id)
	_service_types.erase(service_id)
	if _runtime_context != null:
		_runtime_context.unregister_port(service_id)


func set_runtime_context(runtime_context: MkitRuntimeContext) -> void:
	_runtime_context = runtime_context


func get_runtime_context() -> MkitRuntimeContext:
	return _runtime_context


func get_port(service_id: String, expected_class_name: String = "") -> Object:
	if _runtime_context == null:
		if expected_class_name == "":
			return get_service_or_null(service_id)
		return get_typed(service_id, expected_class_name)
	return _runtime_context.get_port_typed(service_id, expected_class_name)


func get_port_ids() -> Array[String]:
	if _runtime_context == null:
		return get_registered_service_ids()
	return _runtime_context.get_registered_ports()


func clear() -> void:
	_services.clear()
	_service_types.clear()
	_runtime_context = null
