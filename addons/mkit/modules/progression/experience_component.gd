## What: ExperienceComponent tracks XP and level for one saveable entity or profile system.
## Responsibilities: add XP, process level-ups from an ExperienceCurve, emit XP/level signals, and save/load current level and XP.
## Upstream: combat rewards, quests, room clears, or demo scripts call add_xp().
## Downstream: UI, stat systems, progression screens, and SaveManager observe or persist experience state.
## When to use: Attach it to a player/profile node that should level up from earned XP.
## Example: `$ExperienceComponent.curve = preload("res://content/xp_curve.tres"); $ExperienceComponent.add_xp(75)`.
class_name ExperienceComponent
extends Saveable

## Purpose: Emits the `level_up` signal so external listeners can react to this runtime event.
## Example: `self.level_up.connect(_on_level_up)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal level_up(old_level: int, new_level: int)
## Purpose: Emits the `xp_changed` signal so external listeners can react to this runtime event.
## Example: `self.xp_changed.connect(_on_xp_changed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal xp_changed(current_xp: int, xp_to_next: int)

## Purpose: Inspector-facing configuration `curve` for this class.
## Example: `self.curve = null`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var curve: ExperienceCurve = null
## Purpose: Inspector-facing configuration `starting_level` for this class.
## Example: `self.starting_level = 1`
## Scenario: Set this from a scene/resource to tune behavior without changing code.
@export var starting_level: int = 1

## Purpose: Public runtime state `current_level` for this class.
## Example: `self.current_level = 1`
## Scenario: Read or update this when coordinating this object with UI, save data, tests, or sibling systems.
var current_level: int = 1
## Purpose: Public runtime state `current_xp` for this class.
## Example: `self.current_xp = 1`
## Scenario: Read or update this when coordinating this object with UI, save data, tests, or sibling systems.
var current_xp: int = 0


func _ready() -> void:
	if save_id == "":
		save_id = "experience"
	current_level = starting_level


## Purpose: Public method `add_xp` used by external systems to invoke this class behavior.
## Example: `self.add_xp(1)`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	if curve == null or current_level >= curve.max_level:
		return
	current_xp += amount
	_check_level_ups()
	xp_changed.emit(current_xp, get_xp_to_next_level())


## XP still needed to reach the next level.
## Purpose: Public method `get_xp_to_next_level` used by external systems to invoke this class behavior.
## Example: `self.get_xp_to_next_level()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_xp_to_next_level() -> int:
	if curve == null:
		return 0
	return max(0, curve.get_xp_required(current_level) - current_xp)


## Progress toward next level as a 0–1 fraction.
## Purpose: Public method `get_level_progress` used by external systems to invoke this class behavior.
## Example: `self.get_level_progress()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_level_progress() -> float:
	if curve == null:
		return 0.0
	var required := curve.get_xp_required(current_level)
	if required <= 0:
		return 1.0
	return clampf(float(current_xp) / float(required), 0.0, 1.0)


## Purpose: Public method `to_save_data` used by external systems to invoke this class behavior.
## Example: `self.to_save_data()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func to_save_data() -> Dictionary:
	return {
		"current_level": current_level,
		"current_xp": current_xp,
	}


## Purpose: Public method `from_save_data` used by external systems to invoke this class behavior.
## Example: `self.from_save_data({})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func from_save_data(data: Dictionary) -> void:
	current_level = data.get("current_level", starting_level)
	current_xp = data.get("current_xp", 0)


func _check_level_ups() -> void:
	if curve == null:
		return
	while current_level < curve.max_level:
		var required := curve.get_xp_required(current_level)
		if current_xp < required:
			break
		current_xp -= required
		var old_level := current_level
		current_level += 1
		level_up.emit(old_level, current_level)
