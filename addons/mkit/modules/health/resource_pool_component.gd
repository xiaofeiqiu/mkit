## What: ResourcePoolComponent manages spendable resources such as mana, stamina, energy, or ammo.
## Responsibilities: initialize pools, query current/max values, spend/restore resources, emit changes, and serialize state.
## Upstream: AbilityController, items, pickups, save/load, or UI interactions spend and restore resource values.
## Downstream: StatsComponent supplies max resources and UI listens to resource change signals.
## When to use: Attach it to entities that have costs or regenerating pools separate from HP.
## Example: `$ResourcePoolComponent.spend("mana", 25.0)` before casting `"fireball"`.
class_name ResourcePoolComponent
extends Node

## Purpose: Emits the `resource_changed` signal to notify external listeners of a state change.
## Example: `self.resource_changed.connect(_on_resource_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal resource_changed(resource_id: String, current: float, max_value: float)
## Purpose: Emits the `resource_spent` signal to notify external listeners of a state change.
## Example: `self.resource_spent.connect(_on_resource_spent)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal resource_spent(resource_id: String, amount: float)
## Purpose: Emits the `resource_restored` signal to notify external listeners of a state change.
## Example: `self.resource_restored.connect(_on_resource_restored)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal resource_restored(resource_id: String, amount: float)

## Purpose: Inspector-exposed configuration `starting_values`.
## Example: `self.starting_values = {}`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var starting_values: Dictionary = {}

## Purpose: Public runtime field `current_values`.
## Example: `self.current_values = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_values: Dictionary = {}
## Purpose: Public runtime field `stats`.
## Example: `self.stats = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var stats: StatsComponent = null


func _ready() -> void:
	stats = owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	current_values = starting_values.duplicate(true)
	for resource_id in current_values.keys():
		set_current(str(resource_id), float(current_values[resource_id]))


## Purpose: Public method `get_current` for external gameplay integration.
## Example: `self.get_current(<resource_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_current(resource_id: String) -> float:
	return float(current_values.get(resource_id, get_max_resource(resource_id)))


## Purpose: Public method `get_max_resource` for external gameplay integration.
## Example: `self.get_max_resource(<resource_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_max_resource(resource_id: String) -> float:
	if stats == null:
		return 0.0
	return stats.get_stat_value("max_%s" % resource_id, 0.0)


## Purpose: Public method `has_resource` for external gameplay integration.
## Example: `self.has_resource(<resource_id>, <amount>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func has_resource(resource_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
	return get_current(resource_id) >= amount


## Purpose: Public method `spend` for external gameplay integration.
## Example: `self.spend(<resource_id>, <amount>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func spend(resource_id: String, amount: float) -> bool:
	if not has_resource(resource_id, amount):
		return false
	set_current(resource_id, get_current(resource_id) - amount)
	resource_spent.emit(resource_id, amount)
	return true


## Purpose: Public method `restore` for external gameplay integration.
## Example: `self.restore(<resource_id>, <amount>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func restore(resource_id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	set_current(resource_id, get_current(resource_id) + amount)
	resource_restored.emit(resource_id, amount)


## Purpose: Public method `set_current` for external gameplay integration.
## Example: `self.set_current(<resource_id>, <value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func set_current(resource_id: String, value: float) -> void:
	var max_value := get_max_resource(resource_id)
	current_values[resource_id] = clamp(value, 0.0, max_value)
	resource_changed.emit(resource_id, current_values[resource_id], max_value)


## Purpose: Public method `to_save_data` for external gameplay integration.
## Example: `self.to_save_data()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func to_save_data() -> Dictionary:
	return current_values.duplicate(true)


## Purpose: Public method `from_save_data` for external gameplay integration.
## Example: `self.from_save_data(<data>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func from_save_data(data: Dictionary) -> void:
	current_values = data.duplicate(true)
	for resource_id in current_values.keys():
		set_current(str(resource_id), float(current_values[resource_id]))
