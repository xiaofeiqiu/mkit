class_name StatsComponent
extends SaveableComponent
## 说明：`StatsComponent` 是 属性系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := StatsComponent.new()`

## 当 `StatsComponent` 发生 `stat changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal stat_changed(stat_id: String, old_value: float, new_value: float)
## 实体基础属性表；key 为 stat id，value 为初始数值。
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
## 按 stat id 分组的运行时修饰器表。
var modifiers_by_stat: Dictionary = {}
## 属性计算缓存；dirty_stats 标记后会在下次读取时刷新。
var cached_values: Dictionary[String, float] = {}
## 需要重新计算的属性标记表；key 为 stat id。
var dirty_stats: Dictionary[String, bool] = {}
var _initial_base_stats: Dictionary = {}


func _ready() -> void:
	mark_save_baseline()
	mark_all_dirty()


## 返回 `stat_value` 对应的数据或对象，并保持 `StatsComponent` 的领域契约一致。
func get_stat_value(stat_id: String, default_value: float = 0.0) -> float:
	if not base_stats.has(stat_id) and not modifiers_by_stat.has(stat_id):
		return default_value
	if dirty_stats.get(stat_id, true):
		cached_values[stat_id] = _calculate_stat(stat_id)
		dirty_stats[stat_id] = false
	return cached_values[stat_id]


## 设置 `base_stat` 对应的数据或对象，并保持 `StatsComponent` 的领域契约一致。
func set_base_stat(stat_id: String, value: float) -> void:
	var old := get_stat_value(stat_id, value)
	base_stats[stat_id] = value
	mark_dirty(stat_id)
	var new_value := get_stat_value(stat_id)
	stat_changed.emit(stat_id, old, new_value)


## 向当前集合或状态中增加数据，并保持 `StatsComponent` 的领域契约一致。
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


## 从当前集合或状态中移除数据，并保持 `StatsComponent` 的领域契约一致。
func remove_modifier(modifier_id: String, source_id: String = "") -> void:
	_remove_modifiers_where(
		func(m: StatModifier) -> bool:
			return m.modifier_id == modifier_id and (source_id == "" or m.source_id == source_id)
	)


## 从当前集合或状态中移除数据，并保持 `StatsComponent` 的领域契约一致。
func remove_modifiers_from_source(source_id: String) -> void:
	_remove_modifiers_where(func(m: StatModifier) -> bool: return m.source_id == source_id)


## 执行 `tick_modifiers` 对应的公开操作，并保持 `StatsComponent` 的领域契约一致。
func tick_modifiers(delta: float) -> void:
	_remove_modifiers_where(
		func(m: StatModifier) -> bool:
			if m.remaining_duration <= 0:
				return false
			m.remaining_duration -= delta
			return m.remaining_duration <= 0
	)


func _remove_modifiers_where(predicate: Callable) -> void:
	for stat_id in modifiers_by_stat.keys():
		var list: Array[StatModifier] = modifiers_by_stat[stat_id]
		var old_value := get_stat_value(stat_id)
		var removed := false
		for modifier in list.duplicate():
			if predicate.call(modifier):
				list.erase(modifier)
				removed = true
		if removed:
			mark_dirty(stat_id)
			_emit_stat_changed(stat_id, old_value)


## 执行 `mark_dirty` 对应的公开操作，并保持 `StatsComponent` 的领域契约一致。
func mark_dirty(stat_id: String) -> void:
	dirty_stats[stat_id] = true


## 执行 `mark_all_dirty` 对应的公开操作，并保持 `StatsComponent` 的领域契约一致。
func mark_all_dirty() -> void:
	for stat_id in base_stats.keys():
		dirty_stats[stat_id] = true
	for stat_id in modifiers_by_stat.keys():
		dirty_stats[stat_id] = true


## 执行 `mark_save_baseline` 对应的公开操作，并保持 `StatsComponent` 的领域契约一致。
func mark_save_baseline() -> void:
	_initial_base_stats = base_stats.duplicate(true)


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `StatsComponent` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {
		"base_overrides": _get_base_overrides(),
		"persistent_modifiers": _get_persistent_modifiers()
	}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `StatsComponent` 的领域契约一致。
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
