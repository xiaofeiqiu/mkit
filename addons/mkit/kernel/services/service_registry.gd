# Registered by plugin.gd as the autoload singleton "ServiceRegistry".
# IMPORTANT: do NOT declare `class_name ServiceRegistry` here — in Godot 4 an
# autoload name cannot collide with a class_name. Access it everywhere through
# the autoload global (e.g. ServiceRegistry.get_service("events")).
extends Node

var _services: Dictionary = {}
var _service_types: Dictionary = {}


## Purpose: Public method `register_service` for external gameplay integration.
## Example: `self.register_service(<service_id>, <service>, <expected_class_name>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func register_service(service_id: String, service: Object, expected_class_name: String = "") -> void:
	assert(service_id != "")
	assert(service != null)
	if _services.has(service_id):
		push_warning("Service already registered: %s. It will be replaced." % service_id)
	_services[service_id] = service
	if expected_class_name != "":
		_service_types[service_id] = expected_class_name


## Purpose: Public method `has_service` for external gameplay integration.
## Example: `self.has_service(<service_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func has_service(service_id: String) -> bool:
	return _services.has(service_id)


## Purpose: Public method `get_service` for external gameplay integration.
## Example: `self.get_service(<service_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_service(service_id: String) -> Object:
	if not _services.has(service_id):
		push_error("Missing service: %s" % service_id)
		return null
	return _services[service_id]


## Purpose: Public method `get_typed` for external gameplay integration.
## Example: `self.get_typed(<service_id>, <expected_class_name>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_typed(service_id: String, expected_class_name: String) -> Object:
	var service := get_service(service_id)
	if service == null:
		return null
	if expected_class_name != "" and service.get_class() != expected_class_name and not service.is_class(expected_class_name):
		push_warning("Service %s may not match expected type %s" % [service_id, expected_class_name])
	return service


## Purpose: Public method `unregister_service` for external gameplay integration.
## Example: `self.unregister_service(<service_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func unregister_service(service_id: String) -> void:
	_services.erase(service_id)
	_service_types.erase(service_id)


## Purpose: Public method `clear` for external gameplay integration.
## Example: `self.clear()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func clear() -> void:
	_services.clear()
	_service_types.clear()
