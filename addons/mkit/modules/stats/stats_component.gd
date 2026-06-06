class_name StatsComponent
extends SaveableComponent
signal stat_changed(stat_id: String, old_value: float, new_value: float)
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
var modifiers_by_stat: Dictionary = {}
var cached_values: Dictionary[String, float] = {}
var dirty_stats: Dictionary[String, bool] = {}
var _initial_base_stats: Dictionary = {}


func _ready() -> void:
	mark_save_baseline()
	mark_all_dirty()


func get_stat_value(stat_id: String, default_value: float = 0.0) -> float:
	if not base_stats.has(stat_id) and not modifiers_by_stat.has(stat_id):
		return default_value
	if dirty_stats.get(stat_id, true):
		cached_values[stat_id] = _calculate_stat(stat_id)
		dirty_stats[stat_id] = false
	return cached_values[stat_id]


func set_base_stat(stat_id: String, value: float) -> void:
	var old := get_stat_value(stat_id, value)
	base_stats[stat_id] = value
	mark_dirty(stat_id)
	var new_value := get_stat_value(stat_id)
	stat_changed.emit(stat_id, old, new_value)


func add_modifier(modifier: StatModifier) -> void:
	if modifier == null or modifier.stat_id == "":
		return
	var old_value := get_stat_value(modifier.stat_id)
	if not modifiers_by_stat.has(modifier.stat_id):
		var new_list: Array[StatModifier] = []
		modifiers_by_stat[modifier.stat_id] = new_list
	var list: Array[StatModifier] = modifiers_by_stat[modifier.stat_id]
	if _apply_stacking_rule(list, modifier):
		list.append(modifier)
	mark_dirty(modifier.stat_id)
	_emit_stat_changed(modifier.stat_id, old_value)


func remove_modifier(modifier_id: String, source_id: String = "") -> void:
	for stat_id in modifiers_by_stat.keys():
		var list: Array[StatModifier] = modifiers_by_stat[stat_id]
		var old_value := get_stat_value(stat_id)
		var removed := false
		for modifier in list.duplicate():
			if (
				modifier.modifier_id == modifier_id
				and (source_id == "" or modifier.source_id == source_id)
			):
				list.erase(modifier)
				removed = true
		if removed:
			mark_dirty(stat_id)
			_emit_stat_changed(stat_id, old_value)


func remove_modifiers_from_source(source_id: String) -> void:
	for stat_id in modifiers_by_stat.keys():
		var list: Array[StatModifier] = modifiers_by_stat[stat_id]
		var old_value := get_stat_value(stat_id)
		var removed := false
		for modifier in list.duplicate():
			if modifier.source_id == source_id:
				list.erase(modifier)
				removed = true
		if removed:
			mark_dirty(stat_id)
			_emit_stat_changed(stat_id, old_value)


func tick_modifiers(delta: float) -> void:
	for stat_id in modifiers_by_stat.keys():
		var list: Array[StatModifier] = modifiers_by_stat[stat_id]
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


func mark_dirty(stat_id: String) -> void:
	dirty_stats[stat_id] = true


func mark_all_dirty() -> void:
	for stat_id in base_stats.keys():
		dirty_stats[stat_id] = true
	for stat_id in modifiers_by_stat.keys():
		dirty_stats[stat_id] = true


func mark_save_baseline() -> void:
	_initial_base_stats = base_stats.duplicate(true)


func to_save_data() -> Dictionary:
	return {
		"base_overrides": _get_base_overrides(),
		"persistent_modifiers": _get_persistent_modifiers()
	}


func from_save_data(data: Dictionary) -> void:
	if _initial_base_stats.is_empty():
		mark_save_baseline()
	base_stats = _initial_base_stats.duplicate(true)
	modifiers_by_stat.clear()
	cached_values.clear()
	dirty_stats.clear()
	var base_overrides: Dictionary = data.get("base_overrides", {})
	for stat_id in base_overrides.keys():
		base_stats[str(stat_id)] = float(base_overrides[stat_id])
	for raw in data.get("persistent_modifiers", []):
		if raw is Dictionary:
			add_modifier(StatModifier.from_save_data(raw))
	mark_all_dirty()


func _calculate_stat(stat_id: String) -> float:
	var base_value := float(base_stats.get(stat_id, 0.0))
	var value := base_value
	var modifiers: Array[StatModifier] = []
	if modifiers_by_stat.has(stat_id):
		modifiers = modifiers_by_stat[stat_id]
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


func _apply_stacking_rule(list: Array[StatModifier], modifier: StatModifier) -> bool:
	match modifier.stacking_rule:
		StatModifierDefinition.StackingRule.REPLACE_SAME_SOURCE:
			for existing in list.duplicate():
				if (
					existing.source_id == modifier.source_id
					and existing.modifier_id == modifier.modifier_id
				):
					list.erase(existing)
		StatModifierDefinition.StackingRule.UNIQUE:
			for existing in list.duplicate():
				if existing.modifier_id == modifier.modifier_id:
					list.erase(existing)
		StatModifierDefinition.StackingRule.HIGHEST_ONLY:
			for existing in list.duplicate():
				if existing.modifier_id == modifier.modifier_id:
					if existing.value >= modifier.value:
						return false
					list.erase(existing)
		StatModifierDefinition.StackingRule.LOWEST_ONLY:
			for existing in list.duplicate():
				if existing.modifier_id == modifier.modifier_id:
					if existing.value <= modifier.value:
						return false
					list.erase(existing)
	return true


func _emit_stat_changed(stat_id: String, old_value: float) -> void:
	var new_value := get_stat_value(stat_id)
	stat_changed.emit(stat_id, old_value, new_value)


func _get_base_overrides() -> Dictionary[String, float]:
	var overrides: Dictionary = {}
	for stat_id in base_stats.keys():
		var stat_key := str(stat_id)
		var value := float(base_stats[stat_id])
		if _initial_base_stats.is_empty():
			overrides[stat_key] = value
		elif not _initial_base_stats.has(stat_id):
			overrides[stat_key] = value
		elif not is_equal_approx(float(_initial_base_stats[stat_id]), value):
			overrides[stat_key] = value
	return overrides


func _get_persistent_modifiers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stat_id in modifiers_by_stat.keys():
		var list: Array[StatModifier] = modifiers_by_stat[stat_id]
		for modifier in list:
			if modifier is StatModifier and modifier.remaining_duration <= 0.0:
				result.append(modifier.to_save_data())
	return result
