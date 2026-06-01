## What: StatsComponent stores base stats and computes final stat values after runtime modifiers.
## Responsibilities: manage base stats, apply stacking rules, cache calculated values, expire timed modifiers, and emit stat changes.
## Upstream: EntitySpawner, equipment, status effects, progression upgrades, and stat modifier effects write stats/modifiers.
## Downstream: combat, health, resource pools, movement, cooldowns, and UI query final stat values.
## When to use: Attach it to entities whose gameplay numbers can be modified by content or runtime effects.
## Example: `$StatsComponent.set_base_stat("max_hp", 150); var power := $StatsComponent.get_stat_value("attack_power", 10)`.
class_name StatsComponent
extends Node

## Purpose: Emits the `stat_changed` signal to notify external listeners of a state change.
## Example: `self.stat_changed.connect(_on_stat_changed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal stat_changed(stat_id: String, old_value: float, new_value: float)

## Purpose: Inspector-exposed configuration `base_stats`.
## Example: `self.base_stats = {}`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var base_stats: Dictionary = {
	"max_hp": 100.0,
	"attack_power": 10.0,
	"defense": 0.0,
	"move_speed": 160.0,
	"max_mana": 0.0,
	"max_stamina": 100.0,
	"attack_speed": 1.0,
	"crit_chance": 0.05,
	"crit_damage": 1.5,
	"cooldown_reduction": 0.0,
	"luck": 0.0,
	"damage_multiplier": 1.0,
	"healing_multiplier": 1.0
}

## Purpose: Public runtime field `modifiers_by_stat`.
## Example: `self.modifiers_by_stat = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var modifiers_by_stat: Dictionary = {}
## Purpose: Public runtime field `cached_values`.
## Example: `self.cached_values = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var cached_values: Dictionary = {}
## Purpose: Public runtime field `dirty_stats`.
## Example: `self.dirty_stats = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var dirty_stats: Dictionary = {}


func _ready() -> void:
	mark_all_dirty()


## Purpose: Public method `get_stat_value` for external gameplay integration.
## Example: `self.get_stat_value(<stat_id>, <default_value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_stat_value(stat_id: String, default_value: float = 0.0) -> float:
	if not base_stats.has(stat_id) and not modifiers_by_stat.has(stat_id):
		return default_value

	if dirty_stats.get(stat_id, true):
		cached_values[stat_id] = _calculate_stat(stat_id)
		dirty_stats[stat_id] = false

	return cached_values[stat_id]


## Purpose: Public method `set_base_stat` for external gameplay integration.
## Example: `self.set_base_stat(<stat_id>, <value>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func set_base_stat(stat_id: String, value: float) -> void:
	var old := get_stat_value(stat_id, value)
	base_stats[stat_id] = value
	mark_dirty(stat_id)
	var new_value := get_stat_value(stat_id)
	stat_changed.emit(stat_id, old, new_value)


## Purpose: Public method `add_modifier` for external gameplay integration.
## Example: `self.add_modifier(<modifier>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func add_modifier(modifier: StatModifier) -> void:
	if modifier == null or modifier.stat_id == "":
		return

	var old_value := get_stat_value(modifier.stat_id)
	if not modifiers_by_stat.has(modifier.stat_id):
		modifiers_by_stat[modifier.stat_id] = []

	var list: Array = modifiers_by_stat[modifier.stat_id]
	_apply_stacking_rule(list, modifier)
	list.append(modifier)
	mark_dirty(modifier.stat_id)
	_emit_stat_changed(modifier.stat_id, old_value)


## Purpose: Public method `remove_modifier` for external gameplay integration.
## Example: `self.remove_modifier(<modifier_id>, <source_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func remove_modifier(modifier_id: String, source_id: String = "") -> void:
	for stat_id in modifiers_by_stat.keys():
		var list: Array = modifiers_by_stat[stat_id]
		var old_value := get_stat_value(stat_id)
		var removed := false
		for modifier in list.duplicate():
			if modifier.modifier_id == modifier_id and (source_id == "" or modifier.source_id == source_id):
				list.erase(modifier)
				removed = true
		if removed:
			mark_dirty(stat_id)
			_emit_stat_changed(stat_id, old_value)


## Purpose: Public method `remove_modifiers_from_source` for external gameplay integration.
## Example: `self.remove_modifiers_from_source(<source_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func remove_modifiers_from_source(source_id: String) -> void:
	for stat_id in modifiers_by_stat.keys():
		var list: Array = modifiers_by_stat[stat_id]
		var old_value := get_stat_value(stat_id)
		var removed := false
		for modifier in list.duplicate():
			if modifier.source_id == source_id:
				list.erase(modifier)
				removed = true
		if removed:
			mark_dirty(stat_id)
			_emit_stat_changed(stat_id, old_value)


## Purpose: Public method `tick_modifiers` for external gameplay integration.
## Example: `self.tick_modifiers(<delta>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func tick_modifiers(delta: float) -> void:
	for stat_id in modifiers_by_stat.keys():
		var list: Array = modifiers_by_stat[stat_id]
		var old_value := get_stat_value(stat_id)
		var removed := false
		for modifier in list.duplicate():
			if modifier.remaining_duration > 0:
				modifier.remaining_duration -= delta
				if modifier.remaining_duration <= 0:
					list.erase(modifier)
					removed = true
		if removed:
			mark_dirty(stat_id)
			_emit_stat_changed(stat_id, old_value)


## Purpose: Public method `mark_dirty` for external gameplay integration.
## Example: `self.mark_dirty(<stat_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func mark_dirty(stat_id: String) -> void:
	dirty_stats[stat_id] = true


## Purpose: Public method `mark_all_dirty` for external gameplay integration.
## Example: `self.mark_all_dirty()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func mark_all_dirty() -> void:
	for stat_id in base_stats.keys():
		dirty_stats[stat_id] = true
	for stat_id in modifiers_by_stat.keys():
		dirty_stats[stat_id] = true


func _calculate_stat(stat_id: String) -> float:
	var base_value := float(base_stats.get(stat_id, 0.0))
	var value := base_value
	var modifiers: Array = modifiers_by_stat.get(stat_id, [])

	var flat_add := 0.0
	var percent_add := 0.0
	var percent_multiply := 1.0
	var override_values: Array[float] = []
	var clamp_min := -INF
	var clamp_max := INF

	modifiers.sort_custom(func(a, b): return a.priority < b.priority)

	for m: StatModifier in modifiers:
		match m.operation:
			StatModifierDefinition.Operation.FLAT_ADD:
				flat_add += m.value
			StatModifierDefinition.Operation.PERCENT_ADD:
				percent_add += m.value
			StatModifierDefinition.Operation.PERCENT_MULTIPLY:
				percent_multiply *= m.value
			StatModifierDefinition.Operation.OVERRIDE:
				override_values.append(m.value)
			StatModifierDefinition.Operation.CLAMP_MIN:
				clamp_min = max(clamp_min, m.value)
			StatModifierDefinition.Operation.CLAMP_MAX:
				clamp_max = min(clamp_max, m.value)

	value = base_value + flat_add
	value *= 1.0 + percent_add
	value *= percent_multiply

	if override_values.size() > 0:
		value = override_values[-1]

	value = clamp(value, clamp_min, clamp_max)
	return value


func _apply_stacking_rule(list: Array, modifier: StatModifier) -> void:
	match modifier.stacking_rule:
		StatModifierDefinition.StackingRule.REPLACE_SAME_SOURCE:
			for existing in list.duplicate():
				if existing.source_id == modifier.source_id and existing.modifier_id == modifier.modifier_id:
					list.erase(existing)
		StatModifierDefinition.StackingRule.UNIQUE:
			for existing in list.duplicate():
				if existing.modifier_id == modifier.modifier_id:
					list.erase(existing)
		_:
			pass


func _emit_stat_changed(stat_id: String, old_value: float) -> void:
	var new_value := get_stat_value(stat_id)
	stat_changed.emit(stat_id, old_value, new_value)
