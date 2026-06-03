extends GutTest


class PassingCondition:
	extends Condition

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return true


class FailingCondition:
	extends Condition
	var reason: String = "blocked_by_condition"

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return false

	func get_failure_reason(_context: GameplayContext) -> String:
		return reason


class ProbeEffect:
	extends GameEffect
	var calls: Array[String] = []
	var payload_key: String = "marker"

	func _apply_impl(context: GameplayContext) -> EffectResult:
		calls.append(effect_id)
		return EffectResult.ok(
			effect_id, {"value": str(context.get_payload_value(payload_key, ""))}
		)


class FailingEffect:
	extends GameEffect
	var calls: Array[String] = []
	var reason: String = "probe_failure"

	func _apply_impl(_context: GameplayContext) -> EffectResult:
		calls.append(effect_id)
		return EffectResult.fail(effect_id, reason)


class TraceEventEffect:
	extends GameEffect
	var event_type: String = "int_trace"

	func _apply_impl(context: GameplayContext) -> EffectResult:
		var payload := {
			"trace_id": str(context.get_payload_value("trace_id", "")),
			"marker": str(context.get_payload_value("marker", "")),
			"ability_id": context.ability_id,
			"position": context.position,
			"direction": context.direction
		}
		var events: EventRouter = null
		if ServiceRegistry.has_service("events"):
			events = ServiceRegistry.get_service("events") as EventRouter
		if events != null:
			events.emit_domain_event(
				DomainEvent.create(event_type, _get_entity_id(context.source), "", payload)
			)
		return EffectResult.ok(effect_id, payload)

	func _get_entity_id(entity: Node) -> String:
		if entity == null:
			return ""
		var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
		return identity.entity_id if identity != null else str(entity.name)


class PipelineIdleState:
	extends State
	var transition_trace: Array[String] = []

	func enter(_context: Dictionary = {}) -> void:
		transition_trace.append("enter:idle")

	func exit(_context: Dictionary = {}) -> void:
		transition_trace.append("exit:idle")

	func handle_command(command: GameCommand) -> bool:
		if command.command_type != BuiltinCommands.CAST_ABILITY:
			return false
		var gameplay_context := GameplayContext.from_command(command, owner_entity)
		var action_context := ActionContext.from_command(command, owner_entity)
		blackboard.set_value("last_command_type", command.command_type)
		blackboard.set_value("payload_marker", str(command.payload.get("marker", "")))
		blackboard.set_value(
			"gameplay_context_marker", str(gameplay_context.get_payload_value("marker", ""))
		)
		blackboard.set_value(
			"action_context_marker", str(action_context.get_payload_value("marker", ""))
		)
		blackboard.set_value("gameplay_context_position", gameplay_context.position)
		blackboard.set_value("action_context_direction", action_context.direction)
		return request_transition("root/cast", {"command": command, "reason": command.command_type})


class PipelineCastState:
	extends State
	var transition_trace: Array[String] = []

	func enter(context: Dictionary = {}) -> void:
		transition_trace.append("enter:cast")
		var command := context.get("command", null) as GameCommand
		if command == null:
			blackboard.set_value("last_cast_result", false)
			blackboard.set_value("last_cast_failure", "missing_command")
			return
		var gameplay_context := GameplayContext.from_command(command, owner_entity)
		var action_context := ActionContext.from_command(command, owner_entity)
		blackboard.set_value("cast_context_ability_id", gameplay_context.ability_id)
		blackboard.set_value(
			"cast_action_context_trace_id", str(action_context.get_payload_value("trace_id", ""))
		)
		var abilities := (
			owner_entity.get_node_or_null("Controllers/AbilityController") as AbilityController
		)
		if abilities == null:
			blackboard.set_value("last_cast_result", false)
			blackboard.set_value("last_cast_failure", "missing_ability_controller")
			return
		if not abilities.ability_cast_finished.is_connected(_on_ability_cast_finished):
			abilities.ability_cast_finished.connect(_on_ability_cast_finished)
		if not abilities.ability_failed.is_connected(_on_ability_failed):
			abilities.ability_failed.connect(_on_ability_failed)
		var result := abilities.cast(gameplay_context.ability_id, gameplay_context)
		blackboard.set_value("last_cast_result", result)

	func exit(_context: Dictionary = {}) -> void:
		transition_trace.append("exit:cast")

	func _on_ability_cast_finished(ability_id: String) -> void:
		blackboard.set_value("last_finished_ability_id", ability_id)
		request_transition("root/idle", {"reason": "cast_finished"})

	func _on_ability_failed(ability_id: String, reason: String) -> void:
		blackboard.set_value("last_failed_ability_id", ability_id)
		blackboard.set_value("last_cast_failure", reason)


func after_each() -> void:
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_game_01_command_to_ability_to_inventory_event() -> void:
	_boot_gameplay()
	var player := _make_player(["ability.int.grant"])
	var router := ServiceRegistry.get_service("commands") as CommandRouter
	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	var events := ServiceRegistry.get_service("events") as EventRouter
	var receiver := player.get_node("CommandReceiver") as CommandReceiver
	var state_machine := player.get_node("StateMachine") as StateMachine
	var abilities := player.get_node("Controllers/AbilityController") as AbilityController
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController
	var resources := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent

	watch_signals(router)
	watch_signals(actions)
	watch_signals(events)
	watch_signals(abilities)
	watch_signals(inventory)
	watch_signals(resources)

	var command := GameCommand.create(
		BuiltinCommands.CAST_ABILITY,
		"input",
		"player.int",
		{
			"ability_id": "ability.int.grant",
			"marker": "grant-main",
			"position": Vector2(12.0, 8.0),
			"direction": Vector2.RIGHT
		}
	)
	assert_true(router.dispatch(command))
	assert_true(command.consumed)
	assert_eq(receiver.command_history.size(), 1)
	assert_eq(receiver.command_history[0], command)
	assert_eq(state_machine.get_current_path(), "root/cast")
	assert_signal_emitted(router, "command_dispatched")
	assert_signal_not_emitted(router, "command_failed")
	assert_signal_emitted(actions, "action_started")
	assert_signal_emitted_with_parameters(abilities, "ability_cast_started", ["ability.int.grant"])
	assert_signal_emitted_with_parameters(resources, "resource_spent", ["mana", 12.0])
	assert_eq(resources.get_current("mana"), 18.0)
	assert_null(inventory.find_item_by_definition("item.int.reward"))
	assert_eq(actions.active_actions.size(), 1)
	assert_eq(actions.active_actions[0].context.get_payload_value("marker", ""), "grant-main")

	actions._process(0.3)

	var item := inventory.find_item_by_definition("item.int.reward")
	assert_not_null(item)
	assert_eq(item.quantity, 3)
	assert_eq(actions.active_actions.size(), 0)
	assert_eq(state_machine.get_current_path(), "root/idle")
	assert_true(abilities.get_cooldown_remaining("ability.int.grant") > 0.0)
	assert_signal_emitted(actions, "action_completed")
	assert_signal_emitted_with_parameters(
		abilities, "ability_cast_finished", ["ability.int.grant"]
	)
	assert_signal_emitted(inventory, "item_added")
	assert_signal_emitted(inventory, "inventory_changed")
	assert_signal_emitted_with_parameters(events, "inventory_changed", ["player.int"])
	assert_eq(_latest_event(events).event_type, "inventory_changed")
	assert_eq(_latest_event(events).payload.get("item_id", ""), "item.int.reward")

	resources.restore("mana", 99.0)
	assert_signal_emitted(resources, "resource_restored")
	assert_eq(resources.get_current("mana"), 40.0)


func test_tc_int_game_02_failed_condition_blocks_effects_and_emits_failure() -> void:
	_boot_gameplay()
	var player := _make_player(["ability.int.blocked"])
	var router := ServiceRegistry.get_service("commands") as CommandRouter
	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	var effects := ServiceRegistry.get_service("effects") as EffectExecutor
	var abilities := player.get_node("Controllers/AbilityController") as AbilityController
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController
	var resources := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent
	var state_machine := player.get_node("StateMachine") as StateMachine

	watch_signals(router)
	watch_signals(actions)
	watch_signals(abilities)
	watch_signals(inventory)
	watch_signals(resources)

	var command := GameCommand.create(
		BuiltinCommands.CAST_ABILITY,
		"input",
		"player.int",
		{"ability_id": "ability.int.blocked", "marker": "blocked"}
	)
	assert_true(router.dispatch(command))
	assert_true(command.consumed)
	assert_eq(state_machine.get_current_path(), "root/cast")
	assert_signal_not_emitted(router, "command_failed")
	assert_signal_emitted_with_parameters(
		abilities, "ability_failed", ["ability.int.blocked", "blocked_by_condition"]
	)
	assert_signal_not_emitted(actions, "action_started")
	assert_signal_not_emitted(inventory, "item_added")
	assert_signal_not_emitted(resources, "resource_spent")
	assert_null(inventory.find_item_by_definition("item.int.reward"))
	assert_eq(resources.get_current("mana"), 30.0)
	assert_eq(actions.active_actions.size(), 0)
	assert_eq(effects.recent_results.size(), 0)
	assert_eq(state_machine.blackboard.get_value("last_cast_failure", ""), "blocked_by_condition")


func test_tc_int_game_03_time_pause_blocks_action_progress() -> void:
	_boot_gameplay()
	var player := _make_player(["ability.int.grant"])
	var router := ServiceRegistry.get_service("commands") as CommandRouter
	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	var time := ServiceRegistry.get_service("time") as TimeService
	var abilities := player.get_node("Controllers/AbilityController") as AbilityController
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController

	watch_signals(actions)
	watch_signals(abilities)
	watch_signals(inventory)

	var command := GameCommand.create(
		BuiltinCommands.CAST_ABILITY,
		"input",
		"player.int",
		{"ability_id": "ability.int.grant", "marker": "pause"}
	)
	assert_true(router.dispatch(command))
	var action := actions.active_actions[0] as GameAction

	time.set_paused(true)
	actions._process(1.0)
	assert_eq(action.elapsed, 0.0)
	assert_eq(actions.active_actions.size(), 1)
	assert_null(inventory.find_item_by_definition("item.int.reward"))
	assert_signal_not_emitted(abilities, "ability_cast_finished")

	time.set_paused(false)
	time.set_gameplay_time_scale(0.5)
	actions._process(0.2)
	assert_true(absf(action.elapsed - 0.1) < 0.001)
	assert_eq(actions.active_actions.size(), 1)

	time.set_gameplay_time_scale(1.0)
	actions._process(0.2)
	assert_eq(actions.active_actions.size(), 0)
	assert_not_null(inventory.find_item_by_definition("item.int.reward"))
	assert_signal_emitted_with_parameters(
		abilities, "ability_cast_finished", ["ability.int.grant"]
	)
	assert_signal_emitted(actions, "action_completed")


func test_tc_int_game_04_effect_chain_stop_on_failure_preserves_previous_results() -> void:
	_boot_gameplay()
	var effects := ServiceRegistry.get_service("effects") as EffectExecutor
	var first := ProbeEffect.new()
	first.effect_id = "fx.int.first"
	var failing := FailingEffect.new()
	failing.effect_id = "fx.int.fail"
	failing.reason = "expected_stop"
	var skipped := ProbeEffect.new()
	skipped.effect_id = "fx.int.skipped"
	var context := GameplayContext.new().with_payload_value("marker", "chain")
	var chain: Array[GameEffect] = [first, failing, skipped]

	var results := effects.execute_many(chain, context, true)

	assert_eq(results.size(), 2)
	assert_true(results[0].success)
	assert_eq(results[0].effect_id, "fx.int.first")
	assert_eq(results[0].payload.get("value", ""), "chain")
	assert_false(results[1].success)
	assert_eq(results[1].failure_reason, "expected_stop")
	assert_eq(first.calls, ["fx.int.first"])
	assert_eq(failing.calls, ["fx.int.fail"])
	assert_eq(skipped.calls, [])
	assert_eq(effects.recent_results.size(), 2)
	assert_eq(effects.recent_results[0], results[0])
	assert_eq(effects.recent_results[1], results[1])


func test_tc_int_game_05_command_payload_context_blackboard_effect_event_trace() -> void:
	_boot_gameplay()
	var player := _make_player(["ability.int.trace"])
	var router := ServiceRegistry.get_service("commands") as CommandRouter
	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	var effects := ServiceRegistry.get_service("effects") as EffectExecutor
	var events := ServiceRegistry.get_service("events") as EventRouter
	var state_machine := player.get_node("StateMachine") as StateMachine

	var command := GameCommand.create(
		BuiltinCommands.CAST_ABILITY,
		"script",
		"player.int",
		{
			"ability_id": "ability.int.trace",
			"trace_id": "trace-77",
			"marker": "context",
			"position": Vector2(4.0, 5.0),
			"direction": Vector2.DOWN
		}
	)
	assert_true(router.dispatch(command))
	assert_eq(state_machine.blackboard.get_value("last_command_type", ""), BuiltinCommands.CAST_ABILITY)
	assert_eq(state_machine.blackboard.get_value("payload_marker", ""), "context")
	assert_eq(state_machine.blackboard.get_value("gameplay_context_marker", ""), "context")
	assert_eq(state_machine.blackboard.get_value("action_context_marker", ""), "context")
	assert_eq(state_machine.blackboard.get_value("gameplay_context_position", Vector2.ZERO), Vector2(4.0, 5.0))
	assert_eq(state_machine.blackboard.get_value("action_context_direction", Vector2.ZERO), Vector2.DOWN)
	assert_eq(state_machine.blackboard.get_value("cast_context_ability_id", ""), "ability.int.trace")
	assert_eq(state_machine.blackboard.get_value("cast_action_context_trace_id", ""), "trace-77")
	assert_eq(actions.active_actions.size(), 1)
	assert_eq(actions.active_actions[0].context.get_payload_value("trace_id", ""), "trace-77")

	actions._process(0.2)

	var event := _find_event(events, "int_trace")
	var result := effects.recent_results[-1] as EffectResult
	assert_not_null(event)
	assert_eq(event.source_id, "player.int")
	assert_eq(event.payload.get("trace_id", ""), "trace-77")
	assert_eq(event.payload.get("marker", ""), "context")
	assert_eq(event.payload.get("ability_id", ""), "ability.int.trace")
	assert_eq(event.payload.get("position", Vector2.ZERO), Vector2(4.0, 5.0))
	assert_eq(event.payload.get("direction", Vector2.ZERO), Vector2.DOWN)
	assert_eq(result.effect_id, "fx.int.trace")
	assert_eq(result.payload.get("trace_id", ""), "trace-77")
	assert_eq(state_machine.blackboard.get_value("last_finished_ability_id", ""), "ability.int.trace")


func test_tc_int_game_06_equip_applies_and_unequip_reverts_stat_modifier() -> void:
	_boot_gameplay()
	var player := _make_player([])
	var stats := player.get_node("Components/StatsComponent") as StatsComponent
	var equipment := player.get_node("Controllers/EquipmentController") as EquipmentController
	var item := ItemInstance.create("item.int.training_blade", 1)

	watch_signals(stats)
	watch_signals(equipment)

	assert_eq(stats.get_stat_value("attack_power"), 10.0)
	assert_true(equipment.equip(item, "weapon"))
	assert_eq(equipment.get_equipped("weapon"), item)
	assert_eq(stats.get_stat_value("attack_power"), 14.0)
	assert_signal_emitted_with_parameters(equipment, "equipment_changed", ["weapon", item])
	assert_signal_emitted(stats, "stat_changed")

	var removed := equipment.unequip("weapon")
	assert_eq(removed, item)
	assert_null(equipment.get_equipped("weapon"))
	assert_eq(stats.get_stat_value("attack_power"), 10.0)
	assert_signal_emit_count(equipment, "equipment_changed", 2)


func _boot_gameplay() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [_make_database()]
	add_child_autofree(bootstrap)


func _make_database() -> ResourceDatabase:
	var reward_item := ItemDefinition.new()
	reward_item.item_id = "item.int.reward"
	reward_item.stackable = true
	reward_item.max_stack = 99

	var blade_modifier := StatModifierDefinition.new()
	blade_modifier.modifier_id = "mod.int.training_blade.attack"
	blade_modifier.stat_id = "attack_power"
	blade_modifier.operation = StatModifierDefinition.Operation.FLAT_ADD
	blade_modifier.value = 4.0

	var blade := ItemDefinition.new()
	blade.item_id = "item.int.training_blade"
	blade.stackable = false
	blade.max_stack = 1
	blade.equipment_slot = "weapon"
	blade.stat_modifiers = [blade_modifier]

	var grant_effect := GrantItemEffect.new()
	grant_effect.effect_id = "fx.int.grant_reward"
	grant_effect.item_id = "item.int.reward"
	grant_effect.quantity = 3
	grant_effect.give_to_source = true

	var grant_ability := AbilityDefinition.new()
	grant_ability.ability_id = "ability.int.grant"
	grant_ability.cooldown = 2.0
	grant_ability.charges = 1
	grant_ability.cost_type = "mana"
	grant_ability.cost_amount = 12.0
	grant_ability.cast_time = 0.25
	grant_ability.conditions = [PassingCondition.new()]
	grant_ability.effects = [grant_effect]

	var blocked_effect := GrantItemEffect.new()
	blocked_effect.effect_id = "fx.int.blocked_reward"
	blocked_effect.item_id = "item.int.reward"
	blocked_effect.quantity = 1
	blocked_effect.give_to_source = true

	var blocked_ability := AbilityDefinition.new()
	blocked_ability.ability_id = "ability.int.blocked"
	blocked_ability.cooldown = 1.0
	blocked_ability.cost_type = "mana"
	blocked_ability.cost_amount = 5.0
	blocked_ability.cast_time = 0.25
	blocked_ability.conditions = [FailingCondition.new()]
	blocked_ability.effects = [blocked_effect]

	var trace_effect := TraceEventEffect.new()
	trace_effect.effect_id = "fx.int.trace"

	var trace_ability := AbilityDefinition.new()
	trace_ability.ability_id = "ability.int.trace"
	trace_ability.cooldown = 0.0
	trace_ability.cast_time = 0.1
	trace_ability.conditions = [PassingCondition.new()]
	trace_ability.effects = [trace_effect]

	var resources: Array[Resource] = [reward_item, blade, grant_ability, blocked_ability, trace_ability]
	return IntTestHelpers.make_resource_database("gameplay_int", resources)


func _make_player(ability_ids: Array[String]) -> Node:
	var player := Node.new()
	player.name = "Player"

	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "player.int"
	player.add_child(identity)

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	state_machine.initial_state_path = "root/idle"
	state_machine.auto_start = true
	var root := State.new()
	root.state_id = "root"
	var trace: Array[String] = []
	var idle := PipelineIdleState.new()
	idle.state_id = "idle"
	idle.transition_trace = trace
	var cast := PipelineCastState.new()
	cast.state_id = "cast"
	cast.transition_trace = trace
	root.add_child(idle)
	root.add_child(cast)
	state_machine.add_child(root)
	player.add_child(state_machine)

	var receiver := CommandReceiver.new()
	receiver.name = "CommandReceiver"
	receiver.receiver_id = "player.int"
	receiver.auto_register = false
	player.add_child(receiver)

	var components := Node.new()
	components.name = "Components"
	player.add_child(components)

	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	stats.base_stats = {
		"max_hp": 100.0,
		"attack_power": 10.0,
		"defense": 0.0,
		"move_speed": 160.0,
		"max_mana": 40.0,
		"max_stamina": 100.0,
		"attack_speed": 1.0,
		"crit_chance": 0.0,
		"crit_damage": 1.5,
		"cooldown_reduction": 0.0,
		"luck": 0.0,
		"damage_multiplier": 1.0,
		"healing_multiplier": 1.0
	}
	components.add_child(stats)

	var resource_pool := ResourcePoolComponent.new()
	resource_pool.name = "ResourcePoolComponent"
	resource_pool.starting_values = {"mana": 30.0}
	components.add_child(resource_pool)

	var controllers := Node.new()
	controllers.name = "Controllers"
	player.add_child(controllers)

	var abilities := AbilityController.new()
	abilities.name = "AbilityController"
	abilities.starting_ability_ids = ability_ids
	controllers.add_child(abilities)

	var inventory := InventoryController.new()
	inventory.name = "InventoryController"
	inventory.capacity = 8
	controllers.add_child(inventory)

	var equipment := EquipmentController.new()
	equipment.name = "EquipmentController"
	controllers.add_child(equipment)

	var presentation := Node.new()
	presentation.name = "Presentation"
	player.add_child(presentation)
	IntTestHelpers.add_animation_player(player)

	IntTestHelpers.assign_owner(player, player)
	add_child_autofree(player)
	(ServiceRegistry.get_service("commands") as CommandRouter).register_receiver("player.int", receiver)
	return player


func _latest_event(events: EventRouter) -> DomainEvent:
	if events.recent_events.is_empty():
		return null
	return events.recent_events[-1]


func _find_event(events: EventRouter, event_type: String) -> DomainEvent:
	for event in events.recent_events:
		if event.event_type == event_type:
			return event
	return null
