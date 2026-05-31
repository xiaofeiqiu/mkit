class_name AbilityInstance
extends RefCounted

var definition_id: String = ""
var owner: Node = null
var cooldown_remaining: float = 0.0
var current_charges: int = 1
var runtime_level: int = 1
var enabled: bool = true
var temporary_modifiers: Dictionary = {}


func setup(definition: AbilityDefinition, owner_entity: Node) -> void:
	definition_id = definition.ability_id
	owner = owner_entity
	current_charges = definition.charges


func tick(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)


func is_cooldown_ready() -> bool:
	return cooldown_remaining <= 0.0 and current_charges > 0


func start_cooldown(definition: AbilityDefinition, cooldown_reduction: float = 0.0) -> void:
	var final_cd := max(0.0, definition.cooldown * (1.0 - cooldown_reduction))
	cooldown_remaining = final_cd
	if definition.charges > 0:
		current_charges = max(0, current_charges - 1)


func restore_charge(definition: AbilityDefinition) -> void:
	current_charges = min(definition.charges, current_charges + 1)
