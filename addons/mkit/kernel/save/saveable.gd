## What: Saveable is the base node contract for components that participate in SaveManager persistence.
## Responsibilities: expose a stable save id and provide overridable serialization/deserialization methods.
## Upstream: SaveManager discovers Saveable descendants under the selected root node.
## Downstream: concrete systems such as ExperienceComponent and ProgressionSystem store their own runtime state.
## When to use: Extend it for any node component that must survive save/load across sessions.
## Example: `class_name QuestLog extends Saveable` and return `{ "active_quests": active_quests }` from `to_save_data()`.
class_name Saveable
extends Node

## Purpose: Inspector-facing configuration `save_id` for this class.
## Example: `self.save_id = "value"`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var save_id: String = ""


## Purpose: Public method `get_save_id` used by external systems to invoke this class behavior.
## Example: `self.get_save_id()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_save_id() -> String:
	if save_id == "":
		return owner.name if owner != null else name
	return save_id


## Purpose: Public method `to_save_data` used by external systems to invoke this class behavior.
## Example: `self.to_save_data()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func to_save_data() -> Dictionary:
	return {}


## Purpose: Public method `from_save_data` used by external systems to invoke this class behavior.
## Example: `self.from_save_data({})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func from_save_data(data: Dictionary) -> void:
	pass
