## What: ProgressionSystem owns persistent meta progression such as currency, upgrade levels, and unlocked content.
## Responsibilities: add/spend currency, check upgrade prerequisites/costs, unlock content, apply upgrade effects, and save/load state.
## Upstream: run rewards, menus, SaveManager, achievements, or demo slices call progression APIs.
## Downstream: ProgressionState, UpgradeDefinition, ContentRegistry, EffectExecutor, and UI receive progression changes.
## When to use: Use it for permanent account/profile upgrades that live beyond a single run.
## Example: `$ProgressionSystem.add_currency("meta_currency", 150); $ProgressionSystem.unlock_or_level_up("starter_hp")`.
class_name ProgressionSystem
extends Saveable

## Purpose: Emits the `currency_changed` signal so external listeners can react to this runtime event.
## Example: `self.currency_changed.connect(_on_currency_changed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal currency_changed(currency_id: String, amount: int)
## Purpose: Emits the `upgrade_level_changed` signal so external listeners can react to this runtime event.
## Example: `self.upgrade_level_changed.connect(_on_upgrade_level_changed)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal upgrade_level_changed(upgrade_id: String, level: int)
## Purpose: Emits the `content_unlocked` signal so external listeners can react to this runtime event.
## Example: `self.content_unlocked.connect(_on_content_unlocked)`
## Scenario: Use this for UI, audio, analytics, tests, or orchestration code that should react without direct coupling.
signal content_unlocked(content_id: String)

## Purpose: Public runtime state `state` for this class.
## Example: `self.state = null`
## Scenario: Read or update this when coordinating this object with UI, save data, tests, or sibling systems.
var state := ProgressionState.new()
## Purpose: Public runtime state `content` for this class.
## Example: `self.content = null`
## Scenario: Read or update this when coordinating this object with UI, save data, tests, or sibling systems.
var content: ContentRegistry = null


func _ready() -> void:
	if save_id == "":
		save_id = "progression"
	if ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentRegistry


## Purpose: Public method `add_currency` used by external systems to invoke this class behavior.
## Example: `self.add_currency("currency_01", 1)`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func add_currency(currency_id: String, amount: int) -> void:
	state.add_currency(currency_id, amount)
	currency_changed.emit(currency_id, state.get_currency(currency_id))


## Purpose: Public method `get_currency` used by external systems to invoke this class behavior.
## Example: `self.get_currency("currency_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_currency(currency_id: String) -> int:
	return state.get_currency(currency_id)


## Purpose: Public method `can_unlock` used by external systems to invoke this class behavior.
## Example: `self.can_unlock("upgrade_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func can_unlock(upgrade_id: String) -> bool:
	var definition := get_definition(upgrade_id)
	if definition == null:
		return false
	var current_level := state.get_upgrade_level(upgrade_id)
	if current_level >= definition.max_level:
		return false
	for prerequisite in definition.prerequisite_upgrade_ids:
		if state.get_upgrade_level(prerequisite) <= 0:
			return false
	var next_level := current_level + 1
	return state.get_currency(definition.currency_id) >= definition.get_cost_for_level(next_level)


## Purpose: Public method `unlock_or_level_up` used by external systems to invoke this class behavior.
## Example: `self.unlock_or_level_up("upgrade_01", GameplayContext.new())`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func unlock_or_level_up(upgrade_id: String, context: GameplayContext = null) -> bool:
	if not can_unlock(upgrade_id):
		return false
	var definition := get_definition(upgrade_id)
	var next_level := state.get_upgrade_level(upgrade_id) + 1
	var cost := definition.get_cost_for_level(next_level)
	if not state.spend_currency(definition.currency_id, cost):
		return false

	state.set_upgrade_level(upgrade_id, next_level)
	for content_id in definition.unlock_content_ids:
		state.unlock_content(content_id)
		content_unlocked.emit(content_id)

	_apply_upgrade_effects(definition, context)
	currency_changed.emit(definition.currency_id, state.get_currency(definition.currency_id))
	upgrade_level_changed.emit(upgrade_id, next_level)
	return true


## Purpose: Public method `get_definition` used by external systems to invoke this class behavior.
## Example: `self.get_definition("upgrade_01")`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func get_definition(upgrade_id: String) -> UpgradeDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(upgrade_id) as UpgradeDefinition


func _apply_upgrade_effects(definition: UpgradeDefinition, context: GameplayContext) -> void:
	if definition.effects.is_empty():
		return
	var executor := ServiceRegistry.get_service("effects") as EffectExecutor
	if executor == null:
		return
	var ctx := context if context != null else GameplayContext.new()
	executor.execute_many(definition.effects, ctx)


## Purpose: Public method `to_save_data` used by external systems to invoke this class behavior.
## Example: `self.to_save_data()`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func to_save_data() -> Dictionary:
	return state.to_save_data()


## Purpose: Public method `from_save_data` used by external systems to invoke this class behavior.
## Example: `self.from_save_data({})`
## Scenario: Call this from gameplay systems, UI, tests, or orchestration code instead of reaching into internals.
func from_save_data(data: Dictionary) -> void:
	state.from_save_data(data)
