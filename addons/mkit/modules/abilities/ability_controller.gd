class_name AbilityController
extends Node

## Purpose: Emits the `ability_registered` signal to notify external listeners of a state change.
## Example: `self.ability_registered.connect(_on_ability_registered)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal ability_registered(ability_id: String)
## Purpose: Emits the `ability_cast_started` signal to notify external listeners of a state change.
## Example: `self.ability_cast_started.connect(_on_ability_cast_started)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal ability_cast_started(ability_id: String)
## Purpose: Emits the `ability_cast_finished` signal to notify external listeners of a state change.
## Example: `self.ability_cast_finished.connect(_on_ability_cast_finished)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal ability_cast_finished(ability_id: String)
## Purpose: Emits the `ability_failed` signal to notify external listeners of a state change.
## Example: `self.ability_failed.connect(_on_ability_failed)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal ability_failed(ability_id: String, reason: String)
## Purpose: Emits the `cooldown_started` signal to notify external listeners of a state change.
## Example: `self.cooldown_started.connect(_on_cooldown_started)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal cooldown_started(ability_id: String, duration: float)

## Purpose: Inspector-exposed configuration `starting_ability_ids`.
## Example: `self.starting_ability_ids = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var starting_ability_ids: Array[String] = []

## Purpose: Public runtime field `abilities`.
## Example: `self.abilities = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var abilities: Dictionary = {}
## Purpose: Public runtime field `content`.
## Example: `self.content = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var content: ContentRegistry = null


func _ready() -> void:
	content = ServiceRegistry.get_service("content") as ContentRegistry
	for id in starting_ability_ids:
		register_ability(id)


func _process(delta: float) -> void:
	for instance: AbilityInstance in abilities.values():
		instance.tick(delta)


## Purpose: Public method `register_ability` for external gameplay integration.
## Example: `self.register_ability(<ability_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func register_ability(ability_id: String) -> bool:
	if abilities.has(ability_id):
		return true
	var definition := get_definition(ability_id)
	if definition == null:
		push_error("AbilityController: definition not found: %s" % ability_id)
		return false
	var instance := AbilityInstance.new()
	instance.setup(definition, owner)
	abilities[ability_id] = instance
	ability_registered.emit(ability_id)
	return true


## Purpose: Public method `has_ability` for external gameplay integration.
## Example: `self.has_ability(<ability_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func has_ability(ability_id: String) -> bool:
	return abilities.has(ability_id)


## Purpose: Public method `can_cast` for external gameplay integration.
## Example: `self.can_cast(<ability_id>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func can_cast(ability_id: String, context: GameplayContext) -> bool:
	return get_cast_failure_reason(ability_id, context) == ""


## Purpose: Public method `get_cast_failure_reason` for external gameplay integration.
## Example: `self.get_cast_failure_reason(<ability_id>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_cast_failure_reason(ability_id: String, context: GameplayContext) -> String:
	if not abilities.has(ability_id):
		return "not_registered: %s" % ability_id
	var instance := abilities[ability_id] as AbilityInstance
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


## Purpose: Public method `cast` for external gameplay integration.
## Example: `self.cast(<ability_id>, <context>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func cast(ability_id: String, context: GameplayContext) -> bool:
	var failure := get_cast_failure_reason(ability_id, context)
	if failure != "":
		ability_failed.emit(ability_id, failure)
		return false

	var definition := get_definition(ability_id)
	var instance := abilities[ability_id] as AbilityInstance

	_pay_cost(definition)
	ability_cast_started.emit(ability_id)

	if definition.cast_time > 0.0:
		_start_cast_action(definition, context)
	else:
		_execute_ability_effects(definition, context)
		_start_cooldown(instance, definition)
		ability_cast_finished.emit(ability_id)

	return true


## Purpose: Public method `is_cooldown_ready` for external gameplay integration.
## Example: `self.is_cooldown_ready(<ability_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func is_cooldown_ready(ability_id: String) -> bool:
	if not abilities.has(ability_id):
		return false
	return (abilities[ability_id] as AbilityInstance).is_cooldown_ready()


## Purpose: Public method `get_cooldown_remaining` for external gameplay integration.
## Example: `self.get_cooldown_remaining(<ability_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_cooldown_remaining(ability_id: String) -> float:
	if not abilities.has(ability_id):
		return 0.0
	return (abilities[ability_id] as AbilityInstance).cooldown_remaining


## Purpose: Public method `get_definition` for external gameplay integration.
## Example: `self.get_definition(<ability_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_definition(ability_id: String) -> AbilityDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(ability_id) as AbilityDefinition


func _execute_ability_effects(definition: AbilityDefinition, context: GameplayContext) -> void:
	var executor := ServiceRegistry.get_service("effects") as EffectExecutor
	if executor == null:
		executor = EffectExecutor.new()
	executor.execute_many(definition.effects, context)


func _start_cooldown(instance: AbilityInstance, definition: AbilityDefinition) -> void:
	var stats := owner.get_node_or_null("Components/StatsComponent") as StatsComponent
	var cdr := 0.0
	if stats != null:
		cdr = stats.get_stat_value("cooldown_reduction", 0.0)
	instance.start_cooldown(definition, cdr)
	cooldown_started.emit(definition.ability_id, instance.cooldown_remaining)


func _start_cast_action(definition: AbilityDefinition, context: GameplayContext) -> void:
	var action := CastAction.new()
	action.duration = definition.cast_time
	action.completed.connect(func(_a: GameAction) -> void:
		_execute_ability_effects(definition, context)
		_start_cooldown(abilities[definition.ability_id] as AbilityInstance, definition)
		ability_cast_finished.emit(definition.ability_id)
	)
	action.cancelled.connect(func(_a: GameAction, reason: String) -> void:
		ability_failed.emit(definition.ability_id, "cast_cancelled:%s" % reason)
	)
	var action_context := ActionContext.new()
	action_context.source = context.source
	action_context.target = context.target
	action_context.ability_id = definition.ability_id
	action_context.payload = context.payload.duplicate(true)
	var runner := ServiceRegistry.get_service("actions") as ActionRunner
	runner.start_action(action, action_context)


func _has_enough_cost(definition: AbilityDefinition) -> bool:
	if definition.cost_type == "none" or definition.cost_amount <= 0:
		return true
	var resources := owner.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
	if resources == null:
		return false
	return resources.has_resource(definition.cost_type, definition.cost_amount)


func _pay_cost(definition: AbilityDefinition) -> void:
	if definition.cost_type == "none" or definition.cost_amount <= 0:
		return
	var resources := owner.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
	if resources != null:
		resources.spend(definition.cost_type, definition.cost_amount)
