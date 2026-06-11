extends GutTest


const SAVE_PATH := "/tmp/mkit_combat_status_feedback_integration_save.json"


class FixedRandom:
	extends RandomService
	var fixed_value: float = 0.0

	func randf() -> float:
		return fixed_value

	func randi_range(from: int, _to: int) -> int:
		return from

	func randf_range(from: float, to: float) -> float:
		return fixed_value * (to - from) + from


class ProbeTickEffect:
	extends GameEffect
	var tick_count: int = 0
	var status_ids: Array[String] = []

	func _apply_impl(context: GameplayContext) -> EffectResult:
		tick_count += 1
		var status_id := str(context.get_payload_value("status_id", ""))
		status_ids.append(status_id)
		return EffectResult.ok(effect_id, {"status_id": status_id})


class ProbeDamageNumberSystem:
	extends DamageNumberSystem
	var calls: Array[Dictionary] = []

	func show_number(position: Vector2, amount: float, critical: bool = false) -> Node:
		calls.append({"position": position, "amount": amount, "critical": critical})
		return null


class ProbeVFXSpawner:
	extends VFXSpawner
	var calls: Array[Dictionary] = []

	func spawn(vfx_id: String, position: Vector2, direction: Vector2 = Vector2.ZERO) -> Node:
		calls.append({"vfx_id": vfx_id, "position": position, "direction": direction})
		return null


class ProbeAudioManager:
	extends AudioService
	var played: Array[String] = []

	func _ready() -> void:
		pass

	func play_sfx(audio_id: String, _volume_db: float = 0.0) -> void:
		played.append(audio_id)


const STATUS_ID := "status.int.defense_down"


func after_each() -> void:
	IntTestHelpers.remove_file(SAVE_PATH)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_cmb_01_hitbox_damage_status_and_feedback_event() -> void:
	var tick_probe := ProbeTickEffect.new()
	tick_probe.effect_id = "fx.int.status_tick"
	_boot_with_database(_make_database(tick_probe))
	ServiceRegistry.unregister_service("random")
	ServiceRegistry.register_service("random", FixedRandom.new())
	var events := ServiceRegistry.get_port("events") as EventService
	var feedback := _make_feedback_system()
	var damage_numbers := feedback.get_node("DamageNumbers") as ProbeDamageNumberSystem
	var vfx := feedback.get_node("VFX") as ProbeVFXSpawner
	var audio := feedback.get_node("Audio") as ProbeAudioManager
	var source := _make_entity("Source", "entity.int.source", "player", true, false, false)
	var target := _make_entity("Target", "entity.int.target", "enemy", false, true, false)
	source.global_position = Vector2.ZERO
	target.global_position = Vector2.ZERO
	var source_stats := source.get_node("Components/StatsComponent") as StatsComponent
	var target_stats := target.get_node("Components/StatsComponent") as StatsComponent
	var health := target.get_node("Components/HealthComponent") as HealthComponent
	var status := target.get_node("Controllers/StatusEffectController") as StatusEffectController
	source_stats.set_base_stat("attack_power", 4.0)
	source_stats.set_base_stat("crit_chance", 0.0)
	target_stats.set_base_stat("defense", 2.0)
	var hitbox := source.get_node("Components/HitboxComponent") as HitboxComponent
	hitbox.base_damage = 8.0
	hitbox.target_factions = ["enemy"]
	hitbox.on_hit_statuses = [
		{"status_id": STATUS_ID, "chance": 1.0, "stacks": 1, "duration": 0.3}
	]
	var hurtbox := target.get_node("Components/HurtboxComponent") as HurtboxComponent
	hurtbox.damage_multiplier = 1.5
	watch_signals(events)
	watch_signals(health)
	watch_signals(status)
	await get_tree().physics_frame
	await get_tree().physics_frame

	hitbox.set_active(true)
	await get_tree().physics_frame

	assert_eq(health.current_hp, 26.0)
	assert_signal_emitted(health, "damaged")
	assert_not_null(DomainEventAsserts.last_event(events, "damage_applied"))
	assert_signal_emitted_with_parameters(status, "status_applied", [STATUS_ID, 1])
	assert_true(status.has_status(STATUS_ID))
	assert_eq(target_stats.get_stat_value("defense"), 0.0)
	assert_eq(damage_numbers.calls.size(), 1)
	assert_eq(damage_numbers.calls[0].amount, 14.0)
	assert_eq(vfx.calls[0].vfx_id, "hit")
	assert_eq(audio.played[0], "hit")
	assert_eq((events.recent_events[-1] as DomainEvent).event_type, "damage_applied")

	status._process(0.11)

	assert_eq(tick_probe.tick_count, 1)
	assert_eq(tick_probe.status_ids[0], STATUS_ID)
	assert_signal_emitted_with_parameters(status, "status_ticked", [STATUS_ID])


func test_tc_int_cmb_02_heal_clamps_to_max_hp_and_emits() -> void:
	_boot_with_database(_make_database(null))
	var effects := ServiceRegistry.get_port("effects") as EffectService
	var source := _make_entity("Source", "entity.int.source", "player", false, false, false)
	var target := _make_entity("Target", "entity.int.target", "enemy", false, false, false)
	var target_stats := target.get_node("Components/StatsComponent") as StatsComponent
	var health := target.get_node("Components/HealthComponent") as HealthComponent
	target_stats.set_base_stat("max_hp", 75.0)
	health.current_hp = 40.0
	watch_signals(health)
	var heal := HealEffect.new()
	heal.effect_id = "fx.int.heal"
	heal.base_amount = 80.0
	var result := effects.execute(heal, GameplayContext.new().with_source(source).with_target(target))

	assert_true(result.success)
	assert_eq(health.current_hp, 75.0)
	assert_signal_emitted_with_parameters(health, "healed", [80.0, source])
	assert_signal_emitted_with_parameters(health, "health_changed", [75.0, 75.0])


func test_tc_int_cmb_03_lethal_damage_emits_death_and_updates_feedback() -> void:
	_boot_with_database(_make_database(null))
	var events := ServiceRegistry.get_port("events") as EventService
	var effects := ServiceRegistry.get_port("effects") as EffectService
	var feedback := _make_feedback_system()
	var vfx := feedback.get_node("VFX") as ProbeVFXSpawner
	var audio := feedback.get_node("Audio") as ProbeAudioManager
	var source := _make_entity("Source", "entity.int.source", "player", false, false, false)
	var target := _make_entity("Target", "entity.int.target", "enemy", false, false, false)
	var health := target.get_node("Components/HealthComponent") as HealthComponent
	health.current_hp = 20.0
	watch_signals(events)
	watch_signals(health)
	var damage := DealDamageEffect.new()
	damage.effect_id = "fx.int.lethal"
	damage.base_amount = 25.0
	damage.can_crit = false
	var result := effects.execute(damage, GameplayContext.new().with_source(source).with_target(target))

	assert_true(result.success)
	assert_true(health.dead)
	assert_eq(health.current_hp, 0.0)
	assert_signal_emitted(health, "died")
	var evt_entity_died_1 := DomainEventAsserts.last_event(events, "entity_died")
	assert_not_null(evt_entity_died_1)
	assert_eq(evt_entity_died_1.source_id, "entity.int.target")
	assert_eq(evt_entity_died_1.payload.get("entity_ref"), target)
	assert_eq(vfx.calls[0].vfx_id, "hit")
	assert_eq(vfx.calls[1].vfx_id, "death")
	assert_eq(audio.played[0], "hit")
	assert_eq(audio.played[1], "death")
	var evt_enemy_killed := DomainEventAsserts.last_event(events, QuestEvents.ENEMY_KILLED)
	assert_not_null(evt_enemy_killed)
	assert_eq((events.recent_events[-1] as DomainEvent).event_type, QuestEvents.ENEMY_KILLED)


func test_tc_int_cmb_04_status_duration_expiry_removes_stat_modifier() -> void:
	_boot_with_database(_make_database(null))
	var effects := ServiceRegistry.get_port("effects") as EffectService
	var source := _make_entity("Source", "entity.int.source", "player", false, false, false)
	var target := _make_entity("Target", "entity.int.target", "enemy", false, false, false)
	var target_stats := target.get_node("Components/StatsComponent") as StatsComponent
	var status := target.get_node("Controllers/StatusEffectController") as StatusEffectController
	target_stats.set_base_stat("defense", 5.0)
	watch_signals(status)
	watch_signals(target_stats)
	var apply_status := ApplyStatusEffect.new()
	apply_status.effect_id = "fx.int.apply_status"
	apply_status.status_id = STATUS_ID
	apply_status.duration_override = 0.1
	var result := effects.execute(
		apply_status, GameplayContext.new().with_source(source).with_target(target)
	)

	assert_true(result.success)
	assert_true(status.has_status(STATUS_ID))
	assert_eq(target_stats.get_stat_value("defense"), 3.0)
	assert_signal_emitted_with_parameters(status, "status_applied", [STATUS_ID, 1])

	status._process(0.11)

	assert_false(status.has_status(STATUS_ID))
	assert_eq(target_stats.get_stat_value("defense"), 5.0)
	assert_signal_emitted_with_parameters(status, "status_removed", [STATUS_ID])
	assert_signal_emitted(target_stats, "stat_changed")


func test_tc_int_cmb_05_debug_overlay_registers_debug_service_and_reads_target() -> void:
	_boot_with_database(_make_database(null))
	var events := ServiceRegistry.get_port("events") as EventService
	var target := _make_entity("Target", "entity.int.target", "enemy", false, false, true)
	var health := target.get_node("Components/HealthComponent") as HealthComponent
	health.current_hp = 42.0
	var receiver := target.get_node("CommandReceiver") as CommandReceiver
	var command := GameCommand.create("INT_DEBUG", "tester", "entity.int.target", {})
	receiver.receive_command(command)
	events.emit_domain_event(DomainEvent.create("debug_probe", "tester", "entity.int.target", {}))
	var overlay := DebugOverlay.new()
	overlay.watch_entity_path = target.get_path()
	overlay.visible_on_start = true
	add_child_autofree(overlay)
	overlay._process(0.0)
	var label := overlay.get_child(0) as Label
	var text := label.text

	assert_eq(ServiceRegistry.get_port("debug"), overlay)
	assert_true(text.contains("State: Root/Idle"))
	assert_true(text.contains("Last command: INT_DEBUG"))
	assert_true(text.contains("HP: 42 / 100"))
	assert_true(text.contains("Recent events: debug_probe"))


func _boot_with_database(database: ResourceDatabase) -> ModuleBootstrap:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [database]
	bootstrap.save_path = SAVE_PATH
	add_child_autofree(bootstrap)
	return bootstrap


func _make_database(tick_effect: GameEffect) -> ResourceDatabase:
	var modifier := StatModifierDefinition.new()
	modifier.modifier_id = "mod.int.defense_down"
	modifier.stat_id = "defense"
	modifier.operation = StatModifierDefinition.Operation.FLAT_ADD
	modifier.value = -2.0
	modifier.stacking_rule = StatModifierDefinition.StackingRule.REPLACE_SAME_SOURCE

	var modifiers: Array[StatModifierDefinition] = [modifier]
	var tick_effects: Array[GameEffect] = []
	if tick_effect != null:
		tick_effects.append(tick_effect)
	var status := StatusEffectDefinition.new()
	status.status_id = STATUS_ID
	status.display_name = "Integration Defense Down"
	status.duration = 0.3
	status.tick_interval = 0.1
	status.max_stacks = 3
	status.stack_rule = StatusEffectDefinition.StackRule.ADD_STACK
	status.stat_modifiers = modifiers
	status.effects_on_tick = tick_effects

	var resources: Array[Resource] = [status]
	return IntTestHelpers.make_resource_database("combat_status_feedback_int", resources)


func _make_feedback_system() -> FeedbackSystem:
	var feedback := FeedbackSystem.new()
	feedback.name = "FeedbackSystem"
	var damage_numbers := ProbeDamageNumberSystem.new()
	damage_numbers.name = "DamageNumbers"
	feedback.add_child(damage_numbers)
	var vfx := ProbeVFXSpawner.new()
	vfx.name = "VFX"
	feedback.add_child(vfx)
	var audio := ProbeAudioManager.new()
	audio.name = "Audio"
	feedback.add_child(audio)
	feedback.damage_number_system_path = NodePath("DamageNumbers")
	feedback.vfx_spawner_path = NodePath("VFX")
	feedback.audio_manager_path = NodePath("Audio")
	add_child_autofree(feedback)
	return feedback



func _make_entity(
	node_name: String,
	entity_id: String,
	faction: String,
	with_hitbox: bool,
	with_hurtbox: bool,
	with_debug_nodes: bool
) -> EntityRoot:
	var entity := IntTestHelpers.make_entity(node_name, entity_id, [], faction)
	var health := entity.get_node("Components/HealthComponent") as HealthComponent
	if health != null:
		health.current_hp = 40.0
	var components := entity.get_node("Components") as Node

	if with_hitbox:
		var hitbox := HitboxComponent.new()
		hitbox.name = "HitboxComponent"
		hitbox.collision_layer = 1
		hitbox.collision_mask = 2
		components.add_child(hitbox)
		IntTestHelpers.add_circle_collision_shape(hitbox, 12.0)

	if with_hurtbox:
		var hurtbox := HurtboxComponent.new()
		hurtbox.name = "HurtboxComponent"
		hurtbox.collision_layer = 2
		hurtbox.collision_mask = 1
		components.add_child(hurtbox)
		IntTestHelpers.add_circle_collision_shape(hurtbox, 12.0)

	var controllers := IntTestHelpers.ensure_child(entity, "Controllers")
	var status := controllers.get_node_or_null("StatusEffectController") as StatusEffectController
	if status == null:
		status = StatusEffectController.new()
		status.name = "StatusEffectController"
		controllers.add_child(status)

	if with_debug_nodes:
		_add_debug_nodes(entity)

	IntTestHelpers.assign_owner(entity, entity)
	add_child_autofree(entity)
	return entity


func _add_debug_nodes(entity: Node) -> void:
	var existing_machine := entity.get_node_or_null("StateMachine") as StateMachine
	if existing_machine != null:
		existing_machine.free()
	var existing_receiver := entity.get_node_or_null("CommandReceiver") as CommandReceiver
	if existing_receiver != null:
		existing_receiver.free()

	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	state_machine.initial_state_path = "Root/Idle"
	var root_state := State.new()
	root_state.state_id = "Root"
	root_state.name = "Root"
	var idle_state := State.new()
	idle_state.state_id = "Idle"
	idle_state.name = "Idle"
	root_state.add_child(idle_state)
	state_machine.add_child(root_state)
	entity.add_child(state_machine)

	var receiver := CommandReceiver.new()
	receiver.name = "CommandReceiver"
	receiver.auto_register = false
	entity.add_child(receiver)
