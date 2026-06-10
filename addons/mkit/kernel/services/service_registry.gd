extends Node

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


func register_service(service_id: String, service: Object, expected_class_name: String = "") -> void:
	var id := service_id.strip_edges()
	if id == "":
		push_warning("ServiceRegistry.register_service: service_id is empty")
		return
	if service == null:
		push_warning("ServiceRegistry.register_service: service is null for id %s" % service_id)
		return
	if _services.has(id):
		push_warning("Service already registered: %s. It will be replaced." % id)
	_warn_on_type_mismatch(id, service, expected_class_name)
	_services[id] = service


func has_service(service_id: String) -> bool:
	return _services.has(service_id.strip_edges())


## @deprecated: use the typed [Mkit] facade from game/module code, or
## [method get_port] from kernel code.
func get_service(service_id: String) -> Object:
	var service := get_service_or_null(service_id)
	if service == null and service_id.strip_edges() != "":
		push_warning("Missing service: %s" % service_id)
	return service


func get_service_or_null(service_id: String) -> Object:
	var id := service_id.strip_edges()
	if id == "":
		push_warning("ServiceRegistry.get_service: service_id is empty")
		return null
	return _services.get(id, null)


## Low-level lookup that warns when the service is missing or does not match
## the expected class. Kernel code uses this; game/module code should prefer
## the typed [Mkit] facade.
func get_port(service_id: String, expected_class_name: String = "") -> Object:
	var service := get_service(service_id)
	if service != null:
		_warn_on_type_mismatch(service_id.strip_edges(), service, expected_class_name)
	return service


func get_registered_service_ids() -> Array[String]:
	var ids: Array[String] = []
	for service_id in _services.keys():
		ids.append(str(service_id))
	ids.sort()
	return ids


func get_port_ids() -> Array[String]:
	return get_registered_service_ids()


func unregister_service(service_id: String) -> void:
	if service_id.strip_edges() == "":
		push_warning("ServiceRegistry.unregister_service: service_id is empty")
		return
	_services.erase(service_id)


func clear() -> void:
	_services.clear()


func _warn_on_type_mismatch(service_id: String, service: Object, expected_class_name: String) -> void:
	var expected := expected_class_name.strip_edges()
	if expected == "":
		return
	# is_class only knows native classes; script classes need a walk up the
	# get_base_script chain comparing class_name declarations.
	if service.is_class(expected):
		return
	var script := service.get_script() as Script
	while script != null:
		if str(script.get_global_name()) == expected:
			return
		script = script.get_base_script()
	push_warning("Service %s may not match expected type %s" % [service_id, expected])
