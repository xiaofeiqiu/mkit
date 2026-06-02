class_name AbilityController
extends Node
signal ability_registered(ability_id: String)
signal ability_cast_started(ability_id: String)
signal ability_cast_finished(ability_id: String)
signal ability_failed(ability_id: String, reason: String)
signal cooldown_started(ability_id: String, duration: float)
@export var starting_ability_ids: Array[String] = []
var abilities: Dictionary = {}
var active_cast_actions: Array[GameAction] = []
var content: ContentRegistry = null


func _ready() -> void:
	if ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentRegistry
	for id in starting_ability_ids:
		if id.strip_edges() == "":
			push_warning("AbilityController: ignoring empty starting ability id")
			continue
		register_ability(id)


func _process(delta: float) -> void:
	for instance: AbilityInstance in abilities.values():
		if instance != null:
			instance.tick(delta)
	for action in active_cast_actions.duplicate():
		if action == null:
			active_cast_actions.erase(action)
			continue
		action.update(delta)
		if action.is_finished():
			active_cast_actions.erase(action)


func register_ability(ability_id: String) -> bool:
	if ability_id.strip_edges() == "":
		push_warning("AbilityController.register_ability: ability_id is empty")
		return false
	if abilities.has(ability_id):
		return true
	var definition := get_definition(ability_id)
	if definition == null:
		push_warning("AbilityController: definition not found: %s" % ability_id)
		return false
	var instance := AbilityInstance.new()
	instance.setup(definition, owner)
	abilities[ability_id] = instance
	ability_registered.emit(ability_id)
	return true


func unregister_ability(ability_id: String) -> void:
	abilities.erase(ability_id)


func has_ability(ability_id: String) -> bool:
	return abilities.has(ability_id)


func can_cast(ability_id: String, context: GameplayContext) -> bool:
	return get_cast_failure_reason(ability_id, context) == ""


func get_cast_failure_reason(ability_id: String, context: GameplayContext) -> String:
	if context == null:
		return "missing_context"
	if not abilities.has(ability_id):
		return "not_registered: %s" % ability_id
	var instance := abilities[ability_id] as AbilityInstance
	if instance == null:
		return "invalid_ability_instance: %s" % ability_id
	if not instance.enabled:
		return "disabled: %s" % ability_id
	var definition := get_definition(ability_id)
	if definition == null:
		return "missing_definition: %s" % ability_id
	if not instance.is_cooldown_ready():
		return "on_cooldown: %s" % ability_id
	if not _has_enough_cost(definition):
		return "insufficient_%s" % definition.cost_type
	context.ability_id = ability_id
	if not ConditionEvaluator.evaluate_all(definition.conditions, context):
		return ", ".join(ConditionEvaluator.collect_failures(definition.conditions, context))
	return ""


func cast(ability_id: String, context: GameplayContext) -> bool:
	if context == null:
		ability_failed.emit(ability_id, "missing_context")
		return false
	var failure := get_cast_failure_reason(ability_id, context)
	if failure != "":
		ability_failed.emit(ability_id, failure)
		return false
	var definition := get_definition(ability_id)
	var instance := abilities[ability_id] as AbilityInstance
	if definition == null or instance == null:
		ability_failed.emit(ability_id, "invalid_ability_data")
		return false
	_pay_cost(definition)
	ability_cast_started.emit(ability_id)
	if definition.cast_time > 0.0:
		_start_cast_action(definition, context)
	else:
		_execute_ability_effects(definition, context)
		_start_cooldown(instance, definition)
		ability_cast_finished.emit(ability_id)
	return true


func is_cooldown_ready(ability_id: String) -> bool:
	if not abilities.has(ability_id):
		return false
	return (abilities[ability_id] as AbilityInstance).is_cooldown_ready()


func get_cooldown_remaining(ability_id: String) -> float:
	if not abilities.has(ability_id):
		return 0.0
	return (abilities[ability_id] as AbilityInstance).cooldown_remaining


func get_definition(ability_id: String) -> AbilityDefinition:
	if ability_id.strip_edges() == "":
		return null
	if content == null:
		if ServiceRegistry.has_service("content"):
			content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(ability_id) as AbilityDefinition


func _execute_ability_effects(definition: AbilityDefinition, context: GameplayContext) -> void:
	if definition == null:
		push_error("AbilityController._execute_ability_effects: definition is null")
		return
	if context == null:
		push_error("AbilityController._execute_ability_effects: context is null")
		return
	var executor: EffectExecutor = null
	if ServiceRegistry.has_service("effects"):
		executor = ServiceRegistry.get_service("effects") as EffectExecutor
	if executor == null:
		executor = EffectExecutor.new()
	executor.execute_many(definition.effects, context)


func _start_cooldown(instance: AbilityInstance, definition: AbilityDefinition) -> void:
	if instance == null or definition == null:
		return
	var stats: StatsComponent = null
	if owner != null:
		stats = owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	var cdr := 0.0
	if stats != null:
		cdr = stats.get_stat_value("cooldown_reduction", 0.0)
	instance.start_cooldown(definition, cdr)
	cooldown_started.emit(definition.ability_id, instance.cooldown_remaining)


func _start_cast_action(definition: AbilityDefinition, context: GameplayContext) -> void:
	if definition == null or context == null:
		var failed_id := definition.ability_id if definition != null else ""
		ability_failed.emit(failed_id, "invalid_cast_context")
		return
	var action := CastAction.new()
	action.duration = definition.cast_time
	action.completed.connect(
		func(_a: GameAction) -> void:
			_execute_ability_effects(definition, context)
			_start_cooldown(abilities[definition.ability_id] as AbilityInstance, definition)
			ability_cast_finished.emit(definition.ability_id)
	)
	action.cancelled.connect(
		func(_a: GameAction, reason: String) -> void:
			ability_failed.emit(definition.ability_id, "cast_cancelled:%s" % reason)
	)
	var action_context := ActionContext.new()
	action_context.source = context.source
	action_context.target = context.target
	action_context.ability_id = definition.ability_id
	action_context.payload = context.payload.duplicate(true) if context.payload != null else {}
	action.start(action_context)
	active_cast_actions.append(action)


func _has_enough_cost(definition: AbilityDefinition) -> bool:
	if definition == null:
		return false
	if definition.cost_type == "none" or definition.cost_amount <= 0:
		return true
	if owner == null:
		return false
	var resources := (
		owner.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
	)
	if resources == null:
		return false
	return resources.has_resource(definition.cost_type, definition.cost_amount)


func _pay_cost(definition: AbilityDefinition) -> void:
	if definition == null:
		return
	if definition.cost_type == "none" or definition.cost_amount <= 0:
		return
	if owner == null:
		return
	var resources := (
		owner.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
	)
	if resources != null:
		resources.spend(definition.cost_type, definition.cost_amount)
