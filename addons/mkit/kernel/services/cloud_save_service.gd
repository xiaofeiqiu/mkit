## What: CloudSaveService is the platform abstraction for syncing save data to remote storage.
## Responsibilities: report availability, save data by slot, load data by slot, and emit async result signals.
## Upstream: SaveManager, menus, or platform sync flows call it after local save/load operations.
## Downstream: provider adapters for Game Center, Google Play, Steam, or custom backends implement the transport.
## When to use: Use it when local SaveManager data must be mirrored or restored from a remote profile.
## Example: `cloud.save_to_cloud("profile_001", {"save_version": 1, "payload": payload})`.
class_name CloudSaveService
extends Node

## Cloud-save platform abstraction. Local SaveManager is the source of truth; this layer
## syncs to a remote store (Google Play, Game Center, custom backend, etc.).

## Purpose: Emits the `cloud_save_completed` signal so external listeners can react to this runtime event.
## Example: `self.cloud_save_completed.connect(_on_cloud_save_completed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal cloud_save_completed(slot: String)
## Purpose: Emits the `cloud_save_failed` signal so external listeners can react to this runtime event.
## Example: `self.cloud_save_failed.connect(_on_cloud_save_failed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal cloud_save_failed(slot: String, reason: String)
## Purpose: Emits the `cloud_load_completed` signal so external listeners can react to this runtime event.
## Example: `self.cloud_load_completed.connect(_on_cloud_load_completed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal cloud_load_completed(slot: String, data: Dictionary)
## Purpose: Emits the `cloud_load_failed` signal so external listeners can react to this runtime event.
## Example: `self.cloud_load_failed.connect(_on_cloud_load_failed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal cloud_load_failed(slot: String, reason: String)


## Purpose: Public method `is_available` used by external systems to invoke this class behavior.
## Example: `self.is_available()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func is_available() -> bool:
	return false


## Purpose: Public method `save_to_cloud` used by external systems to invoke this class behavior.
## Example: `self.save_to_cloud("slot_01", {})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func save_to_cloud(slot: String, data: Dictionary) -> void:
	cloud_save_failed.emit(slot, "not_implemented")


## Purpose: Public method `load_from_cloud` used by external systems to invoke this class behavior.
## Example: `self.load_from_cloud("slot_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func load_from_cloud(slot: String) -> void:
	cloud_load_failed.emit(slot, "not_implemented")
