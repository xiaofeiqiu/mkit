## What: SceneRouter centralizes scene changes and exposes success/failure signals around transitions.
## Responsibilities: lock concurrent transitions, request tree scene changes, track the current scene path, and reload scenes.
## Upstream: menus, run flow, GameBootstrap, or platform services ask it to change scenes.
## Downstream: the SceneTree performs the actual scene switch and UI/audio systems listen to transition signals.
## When to use: Use it whenever code outside a scene needs to move the player to another scene safely.
## Example: `ServiceRegistry.get_service("scene_router").change_scene("res://game/demo/phase1_combat_arena.tscn")`.
class_name SceneRouter
extends Node

## Purpose: Emits the `scene_change_requested` signal to notify external listeners of a state change.
## Example: `self.scene_change_requested.connect(_on_scene_change_requested)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal scene_change_requested(scene_path: String)
## Purpose: Emits the `scene_changed` signal to notify external listeners of a state change.
## Example: `self.scene_changed.connect(_on_scene_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal scene_changed(scene_path: String)
## Purpose: Emits the `scene_change_failed` signal to notify external listeners of a state change.
## Example: `self.scene_change_failed.connect(_on_scene_change_failed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal scene_change_failed(scene_path: String, reason: String)

## Purpose: Public runtime field `current_scene_path`.
## Example: `self.current_scene_path = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_scene_path: String = ""
## Purpose: Public runtime field `transition_locked`.
## Example: `self.transition_locked = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var transition_locked: bool = false


## Purpose: Public method `change_scene` for external gameplay integration.
## Example: `self.change_scene(<scene_path>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func change_scene(scene_path: String) -> bool:
	if transition_locked:
		scene_change_failed.emit(scene_path, "transition_locked")
		return false
	if scene_path == "":
		scene_change_failed.emit(scene_path, "empty_scene_path")
		return false

	transition_locked = true
	scene_change_requested.emit(scene_path)
	var error := get_tree().change_scene_to_file(scene_path)
	transition_locked = false

	if error != OK:
		scene_change_failed.emit(scene_path, "error_%d" % error)
		return false

	current_scene_path = scene_path
	scene_changed.emit(scene_path)
	return true


## Purpose: Public method `reload_current_scene` for external gameplay integration.
## Example: `self.reload_current_scene()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func reload_current_scene() -> bool:
	if current_scene_path == "":
		return false
	return change_scene(current_scene_path)
