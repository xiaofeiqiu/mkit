class_name Blackboard
extends RefCounted

var _data: Dictionary = {}


## Purpose: Public method `set_value` for external gameplay integration.
## Example: `self.set_value(<key>, <value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func set_value(key: String, value) -> void:
	_data[key] = value


## Purpose: Public method `get_value` for external gameplay integration.
## Example: `self.get_value(<key>, <default_value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_value(key: String, default_value = null):
	if _data.has(key):
		return _data[key]
	return default_value


## Purpose: Public method `has_value` for external gameplay integration.
## Example: `self.has_value(<key>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func has_value(key: String) -> bool:
	return _data.has(key)


## Purpose: Public method `erase_value` for external gameplay integration.
## Example: `self.erase_value(<key>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func erase_value(key: String) -> void:
	_data.erase(key)


## Purpose: Public method `clear` for external gameplay integration.
## Example: `self.clear()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func clear() -> void:
	_data.clear()


## Purpose: Public method `to_debug_dict` for external gameplay integration.
## Example: `self.to_debug_dict()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func to_debug_dict() -> Dictionary:
	return _data.duplicate(true)
