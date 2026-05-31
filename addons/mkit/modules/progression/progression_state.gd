## What: ProgressionState is the serializable runtime data object behind ProgressionSystem.
## Responsibilities: store currencies, upgrade levels, unlocked content ids, and convert them to/from save data.
## Upstream: ProgressionSystem mutates it during currency and upgrade operations.
## Downstream: SaveManager persists it and UI/progression code reads its current values.
## When to use: Use it as the plain data model for meta progression without scene-node dependencies.
## Example: `state.add_currency("meta_currency", 50); state.set_upgrade_level("starter_hp", 1)`.
class_name ProgressionState
extends RefCounted

## Purpose: Public runtime state `currencies` for this class.
## Example: `self.currencies = {}`
## Scenario: Read or update this when coordinating this object with UI, save data, tests, or sibling systems.
var currencies: Dictionary = {}
## Purpose: Public runtime state `upgrade_levels` for this class.
## Example: `self.upgrade_levels = {}`
## Scenario: Read or update this when coordinating this object with UI, save data, tests, or sibling systems.
var upgrade_levels: Dictionary = {}
## Purpose: Public runtime state `unlocked_content_ids` for this class.
## Example: `self.unlocked_content_ids = []`
## Scenario: Read or update this when coordinating this object with UI, save data, tests, or sibling systems.
var unlocked_content_ids: Array[String] = []


## Purpose: Public method `get_currency` used by external systems to invoke this class behavior.
## Example: `self.get_currency("currency_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_currency(currency_id: String) -> int:
	return int(currencies.get(currency_id, 0))


## Purpose: Public method `add_currency` used by external systems to invoke this class behavior.
## Example: `self.add_currency("currency_01", 1)`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func add_currency(currency_id: String, amount: int) -> void:
	currencies[currency_id] = max(0, get_currency(currency_id) + amount)


## Purpose: Public method `spend_currency` used by external systems to invoke this class behavior.
## Example: `self.spend_currency("currency_01", 1)`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func spend_currency(currency_id: String, amount: int) -> bool:
	if get_currency(currency_id) < amount:
		return false
	currencies[currency_id] = get_currency(currency_id) - amount
	return true


## Purpose: Public method `get_upgrade_level` used by external systems to invoke this class behavior.
## Example: `self.get_upgrade_level("upgrade_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


## Purpose: Public method `set_upgrade_level` used by external systems to invoke this class behavior.
## Example: `self.set_upgrade_level("upgrade_01", 1)`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func set_upgrade_level(upgrade_id: String, level: int) -> void:
	upgrade_levels[upgrade_id] = max(0, level)


## Purpose: Public method `unlock_content` used by external systems to invoke this class behavior.
## Example: `self.unlock_content("content_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func unlock_content(content_id: String) -> void:
	if not unlocked_content_ids.has(content_id):
		unlocked_content_ids.append(content_id)


## Purpose: Public method `to_save_data` used by external systems to invoke this class behavior.
## Example: `self.to_save_data()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func to_save_data() -> Dictionary:
	return {
		"currencies": currencies,
		"upgrade_levels": upgrade_levels,
		"unlocked_content_ids": unlocked_content_ids
	}


## Purpose: Public method `from_save_data` used by external systems to invoke this class behavior.
## Example: `self.from_save_data({})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func from_save_data(data: Dictionary) -> void:
	currencies = data.get("currencies", {})
	upgrade_levels = data.get("upgrade_levels", {})
	var raw: Array = data.get("unlocked_content_ids", [])
	unlocked_content_ids.assign(raw)
