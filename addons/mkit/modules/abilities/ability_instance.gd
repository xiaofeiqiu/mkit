## What: AbilityInstance is the runtime state for one registered AbilityDefinition on an entity.
## Responsibilities: track owner, cooldown remaining, charges, level, enabled state, and temporary modifiers.
## Upstream: AbilityController creates and ticks instances when abilities are registered.
## Downstream: AbilityController reads cooldown/charge state before casting and when starting cooldowns.
## When to use: Use it internally to represent per-entity ability state separate from shared definition resources.
## Example: after `register_ability("blink")`, `abilities["blink"].cooldown_remaining` tracks that entity only.
class_name AbilityInstance
extends RefCounted

## Purpose: Public runtime field `definition_id`.
## Example: `self.definition_id = "value"`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var definition_id: String = ""
## Purpose: Public runtime field `owner`.
## Example: `self.owner = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var owner: Node = null
## Purpose: Public runtime field `cooldown_remaining`.
## Example: `self.cooldown_remaining = 1.0`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var cooldown_remaining: float = 0.0
## Purpose: Public runtime field `current_charges`.
## Example: `self.current_charges = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_charges: int = 1
## Purpose: Public runtime field `runtime_level`.
## Example: `self.runtime_level = 1`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var runtime_level: int = 1
## Purpose: Public runtime field `enabled`.
## Example: `self.enabled = true`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var enabled: bool = true
## Purpose: Public runtime field `temporary_modifiers`.
## Example: `self.temporary_modifiers = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var temporary_modifiers: Dictionary = {}

var _definition: AbilityDefinition = null
var _recharge_duration: float = 0.0


## Purpose: Public method `setup` for external gameplay integration.
## Example: `self.setup(<definition>, <owner_entity>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func setup(definition: AbilityDefinition, owner_entity: Node) -> void:
	definition_id = definition.ability_id
	owner = owner_entity
	current_charges = _max_charges(definition)
	cooldown_remaining = 0.0
	_recharge_duration = 0.0
	_definition = definition


## Purpose: Public method `tick` for external gameplay integration.
## Example: `self.tick(<delta>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func tick(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)
		if cooldown_remaining <= 0.0 and _definition != null:
			restore_charge(_definition)
			if current_charges < _max_charges(_definition) and _recharge_duration > 0.0:
				cooldown_remaining = _recharge_duration


## Purpose: Public method `is_cooldown_ready` for external gameplay integration.
## Example: `self.is_cooldown_ready()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func is_cooldown_ready() -> bool:
	return current_charges > 0


## Purpose: Public method `start_cooldown` for external gameplay integration.
## Example: `self.start_cooldown(<definition>, <cooldown_reduction>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func start_cooldown(definition: AbilityDefinition, cooldown_reduction: float = 0.0) -> void:
	var max_charges := _max_charges(definition)
	var final_cd := max(0.0, definition.cooldown * (1.0 - cooldown_reduction))
	_recharge_duration = final_cd
	current_charges = max(0, current_charges - 1)
	if final_cd <= 0.0:
		current_charges = max_charges
		cooldown_remaining = 0.0
		return
	if current_charges < max_charges:
		cooldown_remaining = final_cd
	else:
		cooldown_remaining = 0.0


## Purpose: Public method `restore_charge` for external gameplay integration.
## Example: `self.restore_charge(<definition>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func restore_charge(definition: AbilityDefinition) -> void:
	var max_charges := _max_charges(definition)
	current_charges = min(max_charges, current_charges + 1)
	if current_charges >= max_charges:
		cooldown_remaining = 0.0


func _max_charges(definition: AbilityDefinition) -> int:
	return max(1, definition.charges)
