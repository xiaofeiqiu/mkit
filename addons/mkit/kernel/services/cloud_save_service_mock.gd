## What: CloudSaveServiceMock is an in-memory development implementation of CloudSaveService.
## Responsibilities: store slot data locally in memory, simulate async save/load delays, and emit cloud result signals.
## Upstream: GameBootstrap or tests register it for local cloud-save flows.
## Downstream: save/load UI and platform sync code receive realistic async callbacks without network access.
## When to use: Use it to test cloud-save UX and failure handling before wiring a real backend.
## Example: `cloud.save_to_cloud("slot_a", save_data); await cloud.cloud_save_completed`.
class_name CloudSaveServiceMock
extends CloudSaveService

## Development-time cloud save: stores data in-memory, simulates async round-trips.

var _slots: Dictionary = {}


## Purpose: Public method `is_available` used by external systems to invoke this class behavior.
## Example: `self.is_available()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func is_available() -> bool:
	return true


## Purpose: Public method `save_to_cloud` used by external systems to invoke this class behavior.
## Example: `self.save_to_cloud("slot_01", {})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func save_to_cloud(slot: String, data: Dictionary) -> void:
	_slots[slot] = data.duplicate(true)
	await get_tree().create_timer(0.2).timeout
	cloud_save_completed.emit(slot)
	print("[CloudSave] saved slot '%s'" % slot)


## Purpose: Public method `load_from_cloud` used by external systems to invoke this class behavior.
## Example: `self.load_from_cloud("slot_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func load_from_cloud(slot: String) -> void:
	await get_tree().create_timer(0.2).timeout
	if _slots.has(slot):
		cloud_load_completed.emit(slot, _slots[slot].duplicate(true))
		print("[CloudSave] loaded slot '%s'" % slot)
	else:
		cloud_load_failed.emit(slot, "no_data")
		print("[CloudSave] slot '%s' not found" % slot)
