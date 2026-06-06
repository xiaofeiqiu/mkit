class_name AbilityInstance
extends RefCounted
var definition_id: String = ""
var owner: Node = null
var cooldown_remaining: float = 0.0
var current_charges: int = 1
var runtime_level: int = 1
var enabled: bool = true
var temporary_modifiers: Dictionary = {}
var _definition: AbilityDefinition = null
var _recharge_duration: float = 0.0


func setup(definition: AbilityDefinition, owner_entity: Node) -> void:
	definition_id = definition.ability_id
	owner = owner_entity
	current_charges = _max_charges(definition)
	cooldown_remaining = 0.0
	_recharge_duration = 0.0
	_definition = definition


func tick(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)
		if cooldown_remaining <= 0.0 and _definition != null:
			restore_charge(_definition)
			if current_charges < _max_charges(_definition) and _recharge_duration > 0.0:
				cooldown_remaining = _recharge_duration


func is_cooldown_ready() -> bool:
	return current_charges > 0


func get_recharge_duration() -> float:
	return _recharge_duration


func set_recharge_duration(value: float) -> void:
	_recharge_duration = max(0.0, value)


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


func restore_charge(definition: AbilityDefinition) -> void:
	var max_charges := _max_charges(definition)
	current_charges = min(max_charges, current_charges + 1)
	if current_charges >= max_charges:
		cooldown_remaining = 0.0


func _max_charges(definition: AbilityDefinition) -> int:
	return max(1, definition.charges)
