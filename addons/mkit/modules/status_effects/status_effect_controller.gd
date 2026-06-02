class_name StatusEffectController
extends Node
signal status_applied(status_id: String, stacks: int)
signal status_removed(status_id: String)
signal status_ticked(status_id: String)
var active_statuses: Dictionary = {}
var content: ContentRegistry = null


func _ready() -> void:
	content = ServiceRegistry.get_service("content") as ContentRegistry


func _process(delta: float) -> void:
	for status_id in active_statuses.keys().duplicate():
		var instance := active_statuses[status_id] as StatusEffectInstance
		var definition := get_definition(status_id)
		if definition == null:
			continue
		instance.remaining_duration -= delta
		instance.tick_timer -= delta
		if definition.tick_interval > 0 and instance.tick_timer <= 0:
			_tick_status(instance, definition)
			instance.tick_timer = definition.tick_interval
		if instance.remaining_duration <= 0:
			remove_status(status_id)


func apply_status(
	status_id: String, source: Node, stacks: int = 1, duration_override: float = -1.0
) -> bool:
	var definition := get_definition(status_id)
	if definition == null:
		return false
	if active_statuses.has(status_id):
		var existing := active_statuses[status_id] as StatusEffectInstance
		_apply_stack_rule(existing, definition, stacks, duration_override)
		status_applied.emit(status_id, existing.stacks)
		return true
	var instance := StatusEffectInstance.new()
	instance.setup(definition, source, owner, stacks, duration_override)
	active_statuses[status_id] = instance
	_apply_stat_modifiers(instance, definition)
	_execute_effects(definition.effects_on_apply, instance)
	status_applied.emit(status_id, instance.stacks)
	return true


func remove_status(status_id: String) -> void:
	if not active_statuses.has(status_id):
		return
	var instance := active_statuses[status_id] as StatusEffectInstance
	var definition := get_definition(status_id)
	if definition != null:
		_execute_effects(definition.effects_on_remove, instance)
		_remove_stat_modifiers(instance)
	active_statuses.erase(status_id)
	status_removed.emit(status_id)


func has_status(status_id: String) -> bool:
	return active_statuses.has(status_id)


func get_definition(status_id: String) -> StatusEffectDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(status_id) as StatusEffectDefinition


func _tick_status(instance: StatusEffectInstance, definition: StatusEffectDefinition) -> void:
	_execute_effects(definition.effects_on_tick, instance)
	status_ticked.emit(definition.status_id)


func _execute_effects(effects: Array[GameEffect], instance: StatusEffectInstance) -> void:
	var context := GameplayContext.new()
	context.source = instance.source
	context.target = instance.target
	context.status_id = instance.definition_id
	context.payload["stacks"] = instance.stacks
	var executor := ServiceRegistry.get_service("effects") as EffectExecutor
	if executor != null:
		executor.execute_many(effects, context)


func _apply_stack_rule(
	instance: StatusEffectInstance,
	definition: StatusEffectDefinition,
	stacks: int,
	duration_override: float
) -> void:
	var duration := duration_override if duration_override > 0 else definition.duration
	match definition.stack_rule:
		StatusEffectDefinition.StackRule.REFRESH_DURATION:
			instance.remaining_duration = duration
		StatusEffectDefinition.StackRule.ADD_STACK:
			instance.stacks = min(definition.max_stacks, instance.stacks + stacks)
			instance.remaining_duration = duration
		StatusEffectDefinition.StackRule.REPLACE:
			instance.stacks = stacks
			instance.remaining_duration = duration
		StatusEffectDefinition.StackRule.IGNORE:
			pass
		StatusEffectDefinition.StackRule.EXTEND_DURATION:
			instance.remaining_duration += duration
		_:
			pass


func _apply_stat_modifiers(
	instance: StatusEffectInstance, definition: StatusEffectDefinition
) -> void:
	var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats == null:
		return
	for mod_def in definition.stat_modifiers:
		var modifier := StatModifier.from_definition(
			mod_def, instance.instance_id, instance.remaining_duration
		)
		stats.add_modifier(modifier)
		instance.applied_modifier_ids.append(modifier.modifier_id)


func _remove_stat_modifiers(instance: StatusEffectInstance) -> void:
	var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats != null:
		stats.remove_modifiers_from_source(instance.instance_id)
