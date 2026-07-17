extends GutTest


const PLAYER_SCENE := "res://game/entities/player.tscn"
const BEAST_SCENE := "res://game/entities/field_beast.tscn"
const DEMO_SCENE := "res://game/village_rpg_demo.tscn"
const FIELD_SCENE := "res://game/scenes/field.tscn"
const CONTENT_DB := "res://game/resources/village_rpg_content.tres"
const PLAYER_ID := "player_001"
const BEAST_ID := "enemy.demo.field_beast"
const ENTITY_FIELD_BEAST := "entity.demo.field_beast"
const ENTITY_TRIAL_BEAST := "entity.demo.trial_beast"
const FIREBOLT := "ability.demo.firebolt"
const BURN := "status.demo.burn"
const FIELD_BLADE := "item.demo.field_blade"
const QUEST_ID := "quest.demo.field_report"
const QUEST_MANUAL_ID := "quest.demo.supply_request"
const QUEST_MANUAL_OBJECTIVE_ID := "obj.demo.receive_supply_note"
const ZONE_VILLAGE := "zone.demo.village"
const ZONE_ROOM := "zone.demo.village_room"
const ZONE_FIELD := "zone.demo.field"
const ROOM_TRIAL_01 := "room.demo.trial_01"
const ROOM_TRIAL_02 := "room.demo.trial_02"
const ROOM_TRIAL_03 := "room.demo.trial_03"
const REWARD_TRIAL_ATTACK := "reward.demo.trial_attack"
const UPGRADE_TRIAL_ATTACK := "upgrade.demo.trial_attack"
const SCENE8_BOOT_SAVE_PATH := "/tmp/mkit_scene8_bootstrap_save.json"
const SCENE8_S7_SAVE_PATH := "/tmp/mkit_scene8_s7_save.json"
const DAMAGE_NUMBER_SCENE := "res://game/ui/damage_number.tscn"
const HIT_VFX_SCENE := "res://game/ui/hit_vfx.tscn"
const ATTACK_SFX_ID := "sfx.demo.attack"
const ATTACK_SFX_PATH := "res://game/audio/demo_attack_slash.wav"
const DEMO_VILLAGE_BGM_PATH := "res://game/audio/demo_village_loop.wav"
const DEMO_ROOM_BGM_PATH := "res://game/audio/demo_room_loop.wav"
const DEMO_FIELD_BGM_PATH := "res://game/audio/demo_field_loop.wav"
const TOAST_SCREEN_ID := "demo.toast"

var _previous_current_scene: Node = null
var _current_scene_override: Node = null


func after_each() -> void:
	var tree := get_tree()
	if (
		tree != null
		and _current_scene_override != null
		and tree.current_scene == _current_scene_override
	):
		tree.current_scene = _previous_current_scene
	if _current_scene_override != null and is_instance_valid(_current_scene_override):
		if _current_scene_override.get_parent() != null:
			_current_scene_override.get_parent().remove_child(_current_scene_override)
		_current_scene_override.free()
	_current_scene_override = null
	_previous_current_scene = null
	IntTestHelpers.remove_file(SCENE8_BOOT_SAVE_PATH)
	IntTestHelpers.remove_file(SCENE8_S7_SAVE_PATH)
	IntTestHelpers.cleanup_service_registry()


# S0: the real player scene already carries a command -> HFSM -> action -> hitbox
# chain. This drives it end to end through the kernel pipeline instead of bare keys
# or a scripted DealDamageEffect: a MOVE command makes the Move state move the body,
# and ATTACK commands run a TimedAttackAction whose HitboxComponent overlaps the field
# beast HurtboxComponent, feeding CombatService until the beast dies.
func test_tc_int_scene8_00_command_hfsm_action_drives_combat_to_death() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var router := ServiceRegistry.get_port("commands") as CommandService
	var actions := ServiceRegistry.get_port("actions") as ActionService
	var events := ServiceRegistry.get_port("events") as EventService
	var audio := ServiceRegistry.get_port("audio") as AudioService
	var content := ServiceRegistry.get_port("content") as ContentService
	assert_not_null(router)
	assert_not_null(actions)
	assert_not_null(events)
	assert_not_null(audio)
	assert_not_null(content)
	audio.sfx_bus = "Master"
	var attack_definition := content.get_resource(ATTACK_SFX_ID) as AudioDefinition
	assert_not_null(attack_definition)
	var attack_stream := audio.sfx_map[ATTACK_SFX_ID] as AudioStream
	assert_not_null(attack_stream)
	assert_eq(attack_definition.stream, attack_stream)
	assert_eq(attack_stream.resource_path, ATTACK_SFX_PATH)

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as EntityRoot
	player.global_position = Vector2.ZERO
	add_child_autofree(player)

	var receiver := player.get_node("CommandReceiver") as CommandReceiver
	var state_machine := player.get_node("StateMachine") as Hfsm
	var player_stats := player.get_node("Components/StatsComponent") as StatsComponent
	# crit is the only random factor in the damage formula; zero it for a deterministic hit
	player_stats.set_base_stat("crit_chance", 0.0)

	assert_eq(receiver.receiver_id, PLAYER_ID)
	assert_eq(state_machine.get_current_path(), "Player/Idle")

	# --- MOVE: command -> CommandReceiver -> HFSM Move state moves the body ---
	var start_pos := player.global_position
	assert_true(
		router.dispatch(
			GameCommand.create(BuiltinCommands.MOVE, PLAYER_ID, PLAYER_ID, {"direction": Vector2.RIGHT})
		)
	)
	assert_eq(state_machine.get_current_path(), "Player/Move")
	assert_eq(state_machine.blackboard.get_value("facing", Vector2.ZERO), Vector2.RIGHT)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_gt(player.global_position.x, start_pos.x)
	assert_true(
		router.dispatch(GameCommand.create(BuiltinCommands.STOP_MOVE, PLAYER_ID, PLAYER_ID, {}))
	)
	assert_eq(state_machine.get_current_path(), "Player/Idle")

	# place the beast where the rightward swing hitbox (player + facing * 28) overlaps its hurtbox
	player.global_position = Vector2.ZERO
	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as EntityRoot
	_disable_beast_ai(beast)
	beast.global_position = Vector2(28.0, 0.0)
	add_child_autofree(beast)
	var beast_health := beast.get_node("Components/HealthComponent") as HealthComponent
	assert_false(beast_health.dead)
	assert_eq(beast_health.current_hp, 35.0)

	watch_signals(events)
	watch_signals(beast_health)
	# let the physics server register the hitbox/hurtbox overlap before the first swing
	await get_tree().physics_frame
	await get_tree().physics_frame

	# --- ATTACK 1: command -> Attack state -> TimedAttackAction -> hitbox -> CombatService ---
	var audio_child_count := audio.get_child_count()
	assert_true(router.dispatch(GameCommand.create(BuiltinCommands.ATTACK, PLAYER_ID, PLAYER_ID, {})))
	assert_eq(state_machine.get_current_path(), "Player/Attack")
	assert_eq(actions.active_actions.size(), 1)
	assert_eq(audio.get_child_count(), audio_child_count + 1)
	var attack_player := audio.get_child(audio.get_child_count() - 1) as AudioStreamPlayer
	assert_not_null(attack_player)
	assert_eq(attack_player.stream, attack_stream)
	var action := actions.active_actions[0]
	assert_true(action is TimedAttackAction)
	# ActionContext carries the swinging entity and its facing
	assert_eq(action.context.source, player)
	assert_eq(action.context.direction, Vector2.RIGHT)

	# step into the action's active window so the hitbox enables and scans the overlap
	actions._process(0.08)
	# 35 - (hitbox base 12 + StatsComponent attack_power 10), no crit/defense
	assert_eq(beast_health.current_hp, 13.0)
	assert_signal_emitted(beast_health, "damaged")
	assert_not_null(DomainEventAsserts.last_event(events, "damage_applied"))

	# finish the swing; the state machine returns to Idle and the action drains
	actions._process(0.25)
	assert_eq(actions.active_actions.size(), 0)
	assert_eq(state_machine.get_current_path(), "Player/Idle")

	# --- ATTACK 2: lethal hit -> HealthComponent.die -> EventService entity_died ---
	assert_true(router.dispatch(GameCommand.create(BuiltinCommands.ATTACK, PLAYER_ID, PLAYER_ID, {})))
	assert_eq(state_machine.get_current_path(), "Player/Attack")
	actions._process(0.08)
	assert_true(beast_health.dead)
	assert_eq(beast_health.current_hp, 0.0)
	assert_signal_emitted(beast_health, "died")
	var evt_entity_died_1 := DomainEventAsserts.last_event(events, "entity_died")
	assert_not_null(evt_entity_died_1)
	assert_eq(evt_entity_died_1.source_id, BEAST_ID)
	assert_eq(evt_entity_died_1.payload.get("entity_ref"), beast)

	actions._process(0.25)
	assert_eq(state_machine.get_current_path(), "Player/Idle")


# S1: the firebolt skill pipeline. The player scene registers ability.demo.firebolt from
# the live content database; casting it spends mana, channels through a CastAction (cast_time
# > 0) before its effects fire, then DealDamage + ApplyStatus burn the field beast and a
# cooldown starts. TargetInRangeCondition now lives on the damage/burn effects, so an
# out-of-range cast launches and pays cost but misses; CooldownReadyCondition blocks recasts.
func test_tc_int_scene8_01_firebolt_pipeline_spends_mana_misses_range_and_burns() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var actions := ServiceRegistry.get_port("actions") as ActionService
	assert_not_null(actions)

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as EntityRoot
	player.global_position = Vector2.ZERO
	add_child_autofree(player)

	var ability := player.get_node("Controllers/AbilityController") as AbilityController
	var input_reader := player.get_node("InputReader")
	var pool := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent
	# the shared player scene starts with firebolt from live content for the demo loop.
	assert_eq(str(input_reader.get("cast_ability_id")), FIREBOLT)
	assert_true(ability.has_ability(FIREBOLT))
	assert_eq(pool.get_current("mana"), 50.0)

	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as EntityRoot
	_disable_beast_ai(beast)
	add_child_autofree(beast)
	var beast_health := beast.get_node("Components/HealthComponent") as HealthComponent
	var beast_status := beast.get_node("Controllers/StatusEffectController") as StatusEffectController
	var effects := ServiceRegistry.get_port("effects") as EffectService
	effects.trace_enabled = true
	effects.clear_recent_results()
	watch_signals(ability)
	watch_signals(beast_health)

	# --- out of range: cast still starts, spends mana, finishes, but the effects miss ---
	beast.global_position = Vector2(400.0, 0.0)
	var ctx_far := GameplayContext.new().with_source(player).with_target(beast)
	assert_true(ability.can_cast(FIREBOLT, ctx_far))
	assert_eq(ability.get_cast_failure_reason(FIREBOLT, ctx_far), "")
	assert_true(ability.cast(FIREBOLT, ctx_far))
	assert_eq(pool.get_current("mana"), 40.0)
	assert_signal_emit_count(ability, "ability_cast_started", 1)
	assert_eq(actions.active_actions.size(), 1)
	assert_true(actions.active_actions[0] is CastAction)
	assert_eq(beast_health.current_hp, 35.0)
	assert_false(beast_status.has_status(BURN))
	actions._process(0.5)
	assert_eq(actions.active_actions.size(), 0)
	assert_signal_emit_count(ability, "ability_cast_finished", 1)
	assert_signal_emit_count(ability, "cooldown_started", 1)
	assert_signal_emit_count(beast_health, "damaged", 0)
	assert_eq(beast_health.current_hp, 35.0)
	assert_false(beast_status.has_status(BURN))
	var missed_effect_ids: Array[String] = []
	for result in effects.recent_results:
		if not result.success and result.failure_reason == "target_out_of_range":
			missed_effect_ids.append(result.effect_id)
	assert_true(missed_effect_ids.has("effect.demo.firebolt_damage"))
	assert_true(missed_effect_ids.has("effect.demo.firebolt_burn"))

	var ability_instance := ability.abilities[FIREBOLT] as AbilityInstance
	ability_instance.current_charges = 1
	ability_instance.cooldown_remaining = 0.0
	pool.set_current("mana", 50.0)

	# --- in range: cast pays mana up front and channels through a CastAction (cast_time > 0) ---
	beast.global_position = Vector2(80.0, 0.0)
	var ctx := GameplayContext.new().with_source(player).with_target(beast)
	assert_true(ability.can_cast(FIREBOLT, ctx))
	assert_true(ability.cast(FIREBOLT, ctx))
	# ResourcePoolComponent.spend is charged immediately
	assert_eq(pool.get_current("mana"), 40.0)
	assert_signal_emit_count(ability, "ability_cast_started", 2)
	assert_eq(actions.active_actions.size(), 1)
	assert_true(actions.active_actions[0] is CastAction)
	# the channel is still in flight: no damage, no burn, no finish yet
	assert_eq(beast_health.current_hp, 35.0)
	assert_false(beast_status.has_status(BURN))
	assert_signal_emit_count(ability, "ability_cast_finished", 1)

	# --- advance the channel past cast_time: DealDamage + ApplyStatus fire, cooldown starts ---
	actions._process(0.5)
	assert_eq(actions.active_actions.size(), 0)
	assert_signal_emit_count(ability, "ability_cast_finished", 2)
	assert_signal_emit_count(ability, "cooldown_started", 2)
	# 35 - (firebolt base 8 + player attack_power 10), no crit/defense
	assert_eq(beast_health.current_hp, 17.0)
	assert_signal_emit_count(beast_health, "damaged", 1)
	assert_true(beast_status.has_status(BURN))

	# --- CooldownReadyCondition now blocks the immediate re-cast ---
	assert_false(ability.is_cooldown_ready(FIREBOLT))
	var ctx_cd := GameplayContext.new().with_source(player).with_target(beast)
	assert_false(ability.cast(FIREBOLT, ctx_cd))
	assert_eq(ability.get_cast_failure_reason(FIREBOLT, ctx_cd), "on_cooldown: %s" % FIREBOLT)
	var cd_cond := CooldownReadyCondition.new()
	cd_cond.ability_id = FIREBOLT
	assert_false(cd_cond.evaluate(ctx_cd))


# S2: demo burn is now a full StatusEffectDefinition, not just an applied tag.
# It creates a StatusEffectInstance, applies a StatModifierDefinition-driven defense
# modifier while active, executes DealDamage + LogEffect on tick, removes the modifier
# when duration expires, and the elder dialogue exposes an ApplyStatModifierEffect
# blessing that CombatService reads through StatsComponent.
func test_tc_int_scene8_02_burn_ticks_logs_restores_stats_and_elder_blesses_attack() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_port("content") as ContentService
	var effects := ServiceRegistry.get_port("effects") as EffectService
	effects.trace_enabled = true
	var events := ServiceRegistry.get_port("events") as EventService
	var dialogue := ServiceRegistry.get_port("dialogue") as DialogueService
	assert_not_null(content)
	assert_not_null(effects)
	assert_not_null(events)
	assert_not_null(dialogue)

	var hp_def := content.get_resource("max_hp") as StatDefinition
	var attack_def := content.get_resource("attack_power") as StatDefinition
	var defense_def := content.get_resource("defense") as StatDefinition
	assert_not_null(hp_def)
	assert_not_null(attack_def)
	assert_not_null(defense_def)
	assert_eq(hp_def.default_value, 100.0)
	assert_eq(attack_def.default_value, 10.0)
	assert_eq(defense_def.default_value, 0.0)

	var burn_def := content.get_resource(BURN) as StatusEffectDefinition
	assert_not_null(burn_def)
	assert_eq(burn_def.effects_on_tick.size(), 2)
	assert_true(burn_def.effects_on_tick[0] is DealDamageEffect)
	assert_true(burn_def.effects_on_tick[1] is LogEffect)
	assert_eq(burn_def.stat_modifiers.size(), 1)
	assert_eq(burn_def.stat_modifiers[0].modifier_id, "mod.demo.burn_defense_down")

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as EntityRoot
	add_child_autofree(player)
	var player_stats := player.get_node("Components/StatsComponent") as StatsComponent
	player_stats.set_base_stat("attack_power", 0.0)
	player_stats.set_base_stat("crit_chance", 0.0)

	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as EntityRoot
	_disable_beast_ai(beast)
	add_child_autofree(beast)
	var beast_stats := beast.get_node("Components/StatsComponent") as StatsComponent
	var beast_health := beast.get_node("Components/HealthComponent") as HealthComponent
	var beast_status := beast.get_node("Controllers/StatusEffectController") as StatusEffectController
	beast_stats.set_base_stat("max_hp", 100.0)
	beast_stats.set_base_stat("defense", 4.0)
	beast_health.current_hp = 80.0
	watch_signals(beast_status)
	watch_signals(beast_stats)
	watch_signals(beast_health)
	watch_signals(events)

	var apply_burn := ApplyStatusEffect.new()
	apply_burn.effect_id = "effect.test.scene8.apply_burn"
	apply_burn.status_id = BURN
	var apply_result := effects.execute(
		apply_burn, GameplayContext.new().with_source(player).with_target(beast)
	)

	assert_true(apply_result.success)
	assert_true(beast_status.has_status(BURN))
	assert_true(beast_status.active_statuses[BURN] is StatusEffectInstance)
	assert_eq(beast_stats.get_stat_value("defense"), 2.0)
	assert_eq(_modifier_count(beast_stats, "defense"), 1)
	assert_signal_emitted_with_parameters(beast_status, "status_applied", [BURN, 1])
	assert_signal_emitted(beast_stats, "stat_changed")

	beast_status._process(1.0)

	assert_eq(beast_health.current_hp, 78.0)
	assert_signal_emitted_with_parameters(beast_status, "status_ticked", [BURN])
	assert_signal_emitted(beast_health, "damaged")
	assert_eq((effects.recent_results[-1] as EffectResult).effect_id, "effect.demo.burn_tick_log")
	assert_eq((events.recent_events[-1] as DomainEvent).event_type, "demo_burn_tick")
	assert_eq(str((events.recent_events[-1] as DomainEvent).payload.get("message", "")), "Demo burn tick")

	beast_status._process(3.1)

	assert_false(beast_status.has_status(BURN))
	assert_eq(beast_stats.get_stat_value("defense"), 4.0)
	assert_eq(_modifier_count(beast_stats, "defense"), 0)
	assert_signal_emitted_with_parameters(beast_status, "status_removed", [BURN])

	var elder_dialogue := content.get_resource("dialogue.demo.elder") as DialogueDefinition
	var offer := elder_dialogue.get_node("n.offer")
	assert_eq(offer.choices.size(), 3)
	assert_true(offer.choices[1].effects[0] is ApplyStatModifierEffect)

	var attack_before := player_stats.get_stat_value("attack_power")
	assert_true(dialogue.start("dialogue.demo.elder", GameplayContext.new().with_source(player)))
	dialogue.choose(1)
	assert_eq(player_stats.get_stat_value("attack_power"), attack_before + 5.0)
	assert_eq((effects.recent_results[-1] as EffectResult).effect_id, "effect.demo.elder_blessing_attack")

	beast_stats.set_base_stat("defense", 0.0)
	var request := DamageRequest.new()
	request.source = player
	request.target = beast
	request.base_amount = 10.0
	request.can_crit = false
	var damage := (ServiceRegistry.get_port("combat") as CombatService).resolve(request)
	assert_eq(damage.final_amount, 15.0)


# S3: the field blade is a weapon-slot equippable that the EquipmentController applies through
# the StatModifier path. Equipping it raises attack_power and the extra power flows straight into
# CombatService damage; unequipping restores both; and a Saveable round-trip on the controller
# re-applies the equipped item and its modifier.
func test_tc_int_scene8_03_field_blade_equip_boosts_attack_changes_damage_and_round_trips() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_port("content") as ContentService
	assert_not_null(content)

	# the blade content: a weapon-slot item carrying a +attack_power StatModifierDefinition
	var blade_def := content.get_resource(FIELD_BLADE) as ItemDefinition
	assert_not_null(blade_def)
	assert_eq(blade_def.equipment_slot, "weapon")
	assert_false(blade_def.stackable)
	assert_eq(blade_def.stat_modifiers.size(), 1)
	assert_eq(blade_def.stat_modifiers[0].stat_id, "attack_power")
	assert_eq(blade_def.stat_modifiers[0].value, 6.0)

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as EntityRoot
	add_child_autofree(player)
	var equipment := player.get_node("Controllers/EquipmentController") as EquipmentController
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController
	var stats := player.get_node("Components/StatsComponent") as StatsComponent
	stats.set_base_stat("crit_chance", 0.0)

	# a defenseless target to read combat damage off CombatService
	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as EntityRoot
	_disable_beast_ai(beast)
	add_child_autofree(beast)
	var beast_stats := beast.get_node("Components/StatsComponent") as StatsComponent
	beast_stats.set_base_stat("defense", 0.0)

	var attack_before := stats.get_stat_value("attack_power")
	var damage_before := _resolve_damage(player, beast)
	assert_eq(damage_before, attack_before + 10.0)

	# pick the blade up like field loot, then equip it into the weapon slot
	var blade := ItemInstance.create(FIELD_BLADE)
	assert_true(inventory.add_item(blade))
	watch_signals(equipment)
	watch_signals(stats)
	assert_true(equipment.can_equip(blade, "weapon"))
	assert_true(equipment.equip(blade, "weapon"))
	assert_signal_emitted_with_parameters(equipment, "equipment_changed", ["weapon", blade])
	assert_signal_emitted(stats, "stat_changed")

	# +6 attack_power from the weapon, and the extra power lands in resolved damage
	assert_eq(stats.get_stat_value("attack_power"), attack_before + 6.0)
	assert_eq(_resolve_damage(player, beast), damage_before + 6.0)
	assert_eq(equipment.get_equipped("weapon"), blade)

	# unequip restores both the stat and the damage
	assert_eq(equipment.unequip("weapon"), blade)
	assert_eq(stats.get_stat_value("attack_power"), attack_before)
	assert_eq(_resolve_damage(player, beast), damage_before)
	assert_null(equipment.get_equipped("weapon"))

	# equip/unequip is decoupled from the bag: the source ItemInstance survives the cycle at
	# quantity 1 and re-equips (guards the demo against mutating the equipped instance via the bag)
	var bag_blade := inventory.find_item_by_definition(FIELD_BLADE)
	assert_not_null(bag_blade)
	assert_eq(bag_blade.quantity, 1)
	assert_true(equipment.equip(bag_blade, "weapon"))
	assert_eq(stats.get_stat_value("attack_power"), attack_before + 6.0)
	assert_eq(equipment.unequip("weapon"), bag_blade)

	# Saveable round-trip: re-equip, snapshot, clear, restore -> item + modifier come back
	assert_true(equipment.equip(blade, "weapon"))
	var snapshot := equipment.to_save_data()
	equipment.unequip("weapon")
	assert_null(equipment.get_equipped("weapon"))
	assert_eq(stats.get_stat_value("attack_power"), attack_before)
	equipment.from_save_data(snapshot)
	var restored := equipment.get_equipped("weapon")
	assert_not_null(restored)
	assert_eq(restored.definition_id, FIELD_BLADE)
	assert_eq(stats.get_stat_value("attack_power"), attack_before + 6.0)


# S4: field beast is no longer a static child of field.tscn. Demo registers an
# EntityDefinition in live content, enters the field, and creates the beast through
# EntitySpawner so identity, tags and base stats all come from data.
func test_tc_int_scene8_04_field_beast_spawns_from_entity_definition() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_port("content") as ContentService
	assert_not_null(content)
	var definition := content.get_resource(ENTITY_FIELD_BEAST) as EntityDefinition
	assert_not_null(definition)
	assert_eq(definition.entity_definition_id, ENTITY_FIELD_BEAST)
	assert_eq(definition.scene_path, BEAST_SCENE)
	assert_eq(definition.default_faction, "enemy")
	assert_true(definition.tags.has("field_beast"))
	assert_true(definition.starting_ability_ids.is_empty())
	assert_eq(float(definition.base_stats.get("max_hp", 0.0)), 35.0)
	assert_eq(float(definition.base_stats.get("defense", -1.0)), 0.0)
	assert_eq(float(definition.base_stats.get("attack_power", -1.0)), 0.0)
	assert_eq(float(definition.base_stats.get("move_speed", 0.0)), 120.0)

	var field := (load(FIELD_SCENE) as PackedScene).instantiate()
	assert_not_null(field.get_node_or_null("FieldBeastSpawn"))
	assert_null(field.get_node_or_null("FieldBeast"))
	field.free()

	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()
	await _focus_demo_interactable(demo, "ToField/Interactable")
	demo.call("_toggle_field_portal")
	await _settle_scene8_world()

	var world := ServiceRegistry.get_port("world") as WorldService
	assert_eq(world.current_zone_id, ZONE_FIELD)
	var root := demo.call("_current_zone_root") as Node
	assert_not_null(root)
	var marker := root.get_node_or_null("FieldBeastSpawn") as Node2D
	assert_not_null(marker)
	var beast := root.get_node_or_null("FieldBeast") as EntityRoot
	assert_not_null(beast)
	_disable_beast_ai(beast)
	assert_eq(beast.global_position, marker.global_position)
	var combat_label := demo.get_node("HUD/StatsPanel/CombatInfo") as Label
	demo.call("_update_hud")
	assert_eq(combat_label.text, "Beast: HP 35/35")

	var identity := beast.get_node("EntityIdentity") as EntityIdentity
	assert_eq(identity.definition_id, ENTITY_FIELD_BEAST)
	assert_eq(identity.display_name, "Field Beast")
	assert_eq(identity.faction, "enemy")
	assert_true(identity.tags.has("enemy"))
	assert_true(identity.tags.has("living"))
	assert_true(identity.tags.has("field_beast"))
	var receiver := beast.get_node("CommandReceiver") as CommandReceiver
	assert_eq(receiver.receiver_id, identity.entity_id)
	var commands := ServiceRegistry.get_port("commands") as CommandService
	assert_true(commands._receivers.has(identity.entity_id))
	assert_false(commands._receivers.has(BEAST_ID))

	var stats := beast.get_node("Components/StatsComponent") as StatsComponent
	assert_eq(stats.get_stat_value("max_hp"), 35.0)
	assert_eq(stats.get_stat_value("defense"), 0.0)
	assert_eq(stats.get_stat_value("attack_power"), 0.0)
	assert_eq(stats.get_stat_value("move_speed"), 120.0)
	var save_data := stats.to_save_data()
	assert_true((save_data["base_overrides"] as Dictionary).is_empty())
	var health := beast.get_node("Components/HealthComponent") as HealthComponent
	assert_true(health.destroy_on_death)
	var status := beast.get_node("Controllers/StatusEffectController") as StatusEffectController

	var player := demo.get_node("Player") as EntityRoot
	var ability := player.get_node("Controllers/AbilityController") as AbilityController
	var pool := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent
	watch_signals(ability)

	player.global_position = beast.global_position + Vector2(-400.0, 0.0)
	demo.set("_firebolt_projectile_observed", false)
	demo.call("_cast_firebolt_command")
	assert_true(bool(demo.get("_firebolt_projectile_observed")))
	assert_true(await wait_for_signal(ability.ability_cast_finished, 1.0, "firebolt_miss"))
	assert_signal_emit_count(ability, "ability_cast_finished", 1)
	demo.call("_update_hud")
	assert_eq(pool.get_current("mana"), 40.0)
	assert_eq(health.current_hp, 35.0)
	assert_false(status.has_status(BURN))
	assert_eq(combat_label.text, "Beast: HP 35/35")

	var ability_instance := ability.abilities[FIREBOLT] as AbilityInstance
	ability_instance.current_charges = 1
	ability_instance.cooldown_remaining = 0.0
	pool.set_current("mana", 50.0)

	player.global_position = beast.global_position + Vector2(-80.0, 0.0)
	demo.set("_firebolt_projectile_observed", false)
	demo.call("_cast_firebolt_command")
	assert_true(bool(demo.get("_firebolt_projectile_observed")))
	assert_true(await wait_for_signal(ability.ability_cast_finished, 1.0, "firebolt"))
	assert_signal_emit_count(ability, "ability_cast_finished", 2)
	demo.call("_update_hud")
	assert_eq(pool.get_current("mana"), 40.0)
	assert_eq(health.current_hp, 17.0)
	assert_true(combat_label.text.contains("Beast: HP 17/35"))
	assert_true(combat_label.text.contains("burn"))

	var effects := ServiceRegistry.get_port("effects") as EffectService
	var lethal := DealDamageEffect.new()
	lethal.effect_id = "effect.test.scene8.destroy_field_beast"
	lethal.base_amount = 999.0
	lethal.can_crit = false
	assert_true(effects.execute(lethal, GameplayContext.new().with_source(player).with_target(beast)).success)
	assert_true(bool(demo.get("_field_beast_defeated")))
	demo.call("_update_hud")
	assert_eq(combat_label.text, "Beast: defeated")
	await get_tree().process_frame
	assert_false(is_instance_valid(beast))
	assert_null(root.get_node_or_null("FieldBeast"))


func test_tc_int_scene8_05_enemy_ai_approaches_attacks_and_damages_player() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()
	await _focus_demo_interactable(demo, "ToField/Interactable")
	demo.call("_toggle_field_portal")
	await _settle_scene8_world()

	var world := ServiceRegistry.get_port("world") as WorldService
	assert_eq(world.current_zone_id, ZONE_FIELD)

	var player := demo.get_node("Player") as EntityRoot
	var player_health := player.get_node("Components/HealthComponent") as HealthComponent
	var player_hurtbox := player.get_node_or_null("Components/HurtboxComponent") as HurtboxComponent
	assert_not_null(player_hurtbox)
	player.global_position = Vector2.ZERO
	player_health.current_hp = player_health.get_max_hp()

	var beast := demo.call("_field_beast") as EntityRoot
	assert_not_null(beast)
	beast.global_position = Vector2(110.0, 0.0)
	var brain := beast.get_node("Controllers/SimpleAIEnemyBrain") as SimpleAIEnemyBrain
	var receiver := beast.get_node("CommandReceiver") as CommandReceiver
	var state_machine := beast.get_node("StateMachine") as Hfsm
	var hitbox := beast.get_node("Components/HitboxComponent") as HitboxComponent
	assert_not_null(brain)
	assert_not_null(hitbox)
	assert_eq(hitbox.target_factions, ["player"])
	assert_true(brain is Brain)
	assert_true(brain.blackboard is Blackboard)
	assert_eq(brain.blackboard.get_value("target", null), player)

	# _ready already cached the target autonomously (asserted above); from here drive think()
	# explicitly so the assertions don't race the brain's own _process tick.
	brain.enabled = false

	var start_pos := beast.global_position
	brain.think()
	assert_eq(brain.blackboard.get_value("intent", ""), "approach")
	assert_eq(receiver.command_history[-1].command_type, BuiltinCommands.MOVE)
	assert_eq(state_machine.get_current_path(), "Enemy/Move")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_lt(beast.global_position.x, start_pos.x)

	beast.global_position = Vector2(28.0, 0.0)
	watch_signals(player_health)
	var events := ServiceRegistry.get_port("events") as EventService
	watch_signals(events)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hp_before := player_health.current_hp
	brain.think()
	assert_eq(brain.blackboard.get_value("intent", ""), "attack")
	assert_eq(receiver.command_history[-1].command_type, BuiltinCommands.ATTACK)
	assert_eq(state_machine.get_current_path(), "Enemy/Attack")

	var actions := ServiceRegistry.get_port("actions") as ActionService
	assert_eq(actions.active_actions.size(), 1)
	assert_true(actions.active_actions[0] is TimedAttackAction)
	actions._process(0.08)
	assert_lt(player_health.current_hp, hp_before)
	assert_eq(player_health.current_hp, hp_before - 8.0)
	assert_signal_emitted(player_health, "damaged")
	assert_not_null(DomainEventAsserts.last_event(events, "damage_applied"))
	actions._process(0.25)
	assert_eq(state_machine.get_current_path(), "Enemy/Idle")


func test_tc_int_scene8_06_trial_cave_run_rooms_rewards_and_upgrade() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_port("content") as ContentService
	var events := ServiceRegistry.get_port("events") as EventService
	assert_not_null(content)
	assert_not_null(events)

	var trial_entity := content.get_resource(ENTITY_TRIAL_BEAST) as EntityDefinition
	assert_not_null(trial_entity)
	assert_eq(trial_entity.scene_path, BEAST_SCENE)
	assert_true(trial_entity.tags.has("trial_beast"))
	assert_false(trial_entity.tags.has("field_beast"))

	var room_ids: Array[String] = [ROOM_TRIAL_01, ROOM_TRIAL_02, ROOM_TRIAL_03]
	for i in range(room_ids.size()):
		var room_def := content.get_resource(room_ids[i]) as RoomDefinition
		assert_not_null(room_def)
		assert_true(ResourceLoader.exists(room_def.scene_path, "PackedScene"))
		assert_eq(room_def.enemy_spawn_ids.size(), i + 1)
		assert_true(room_def.reward_pool_ids.has(REWARD_TRIAL_ATTACK))

	var reward := content.get_resource(REWARD_TRIAL_ATTACK) as RewardDefinition
	assert_not_null(reward)
	assert_eq(reward.effects.size(), 1)
	assert_true(reward.effects[0] is ApplyStatModifierEffect)

	var upgrade := content.get_resource(UPGRADE_TRIAL_ATTACK) as UpgradeDefinition
	assert_not_null(upgrade)
	assert_eq(upgrade.unlock_content_ids, [REWARD_TRIAL_ATTACK])
	assert_eq(upgrade.effects.size(), 1)
	assert_true(upgrade.effects[0] is ApplyStatModifierEffect)

	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()
	await _focus_demo_interactable(demo, "ToField/Interactable")
	demo.call("_toggle_field_portal")
	await _settle_scene8_world()

	var root := demo.call("_current_zone_root") as Node
	assert_not_null(root)
	assert_not_null(root.get_node_or_null("TrialCave"))
	assert_not_null(root.get_node_or_null("TrialCaveArea/Interactable"))

	var player := demo.get_node("Player") as EntityRoot
	var stats := player.get_node("Components/StatsComponent") as StatsComponent
	var attack_before := stats.get_stat_value("attack_power")
	var run_director := demo.get_node("RunDirector") as RunDirector
	assert_not_null(run_director)
	assert_eq(run_director.first_floor_room_pool, room_ids)
	assert_eq(run_director.run_length, 3)
	watch_signals(run_director)
	watch_signals(events)

	demo.call("_enter_trial_cave")
	await _settle_scene8_world()
	assert_null(run_director.run_state)

	await _focus_demo_interactable(demo, "TrialCaveArea/Interactable")
	demo.call("_enter_trial_cave")
	await _settle_scene8_world()

	assert_true(run_director.run_state is RunState)
	assert_true(run_director.room_graph is RoomGraph)
	assert_eq(run_director.run_state.seed, 8606)
	assert_eq(run_director.run_state.status, "active")
	assert_eq(run_director.room_graph.nodes.size(), 3)
	assert_true(run_director.room_graph.start_node is RoomNode)
	assert_true(run_director.room_graph.boss_node is RoomNode)
	assert_eq(run_director.run_state.room_history.size(), 1)
	assert_signal_emitted(run_director, "run_started")
	var evt_run_started_2 := DomainEventAsserts.last_event(events, "run_started")
	assert_not_null(evt_run_started_2)
	assert_eq(evt_run_started_2.source_id, run_director.run_state.run_id)
	assert_eq(evt_run_started_2.payload.get("seed"), 8606)

	for _room_index in range(3):
		var room := run_director.current_room_controller
		assert_not_null(room)
		assert_true(room is RoomController)
		assert_true(room.runtime is RoomRuntime)
		assert_true(room.runtime.entered)
		assert_false(room.runtime.cleared)
		assert_eq(room.runtime.definition_id, run_director.run_state.current_room_id)
		var active_room_def := content.get_resource(room.runtime.definition_id) as RoomDefinition
		assert_not_null(active_room_def)
		var expected_enemy_count := active_room_def.enemy_spawn_ids.size()
		assert_eq(room.active_enemies.size(), expected_enemy_count)
		assert_eq(room.runtime.active_enemy_ids.size(), expected_enemy_count)
		var enemy := room.active_enemies.values()[0] as Node
		var identity := enemy.get_node("EntityIdentity") as EntityIdentity
		assert_eq(identity.definition_id, ENTITY_TRIAL_BEAST)
		assert_true(identity.tags.has("trial_beast"))
		assert_false(identity.tags.has("field_beast"))

		demo.call("_defeat_trial_room_enemies")
		await _settle_scene8_world()

		assert_true(room.runtime.cleared)
		assert_eq(room.runtime.active_enemy_ids.size(), 0)
		assert_eq(run_director.run_state.status, "choosing_reward")
		assert_eq(room.runtime.reward_options.size(), 3)
		assert_true(room.runtime.reward_options[0] is RewardOption)
		assert_true(_reward_options_have(room.runtime.reward_options, REWARD_TRIAL_ATTACK))
		var reward_screen := demo.get("_reward_screen") as RewardSelectionUI
		assert_not_null(reward_screen)
		assert_eq(reward_screen.options.size(), 3)
		assert_eq(reward_screen.get_node("OptionContainer").get_child_count(), 3)

		var attack_index := int(demo.call("_trial_reward_index", REWARD_TRIAL_ATTACK))
		demo.call("_select_trial_reward", attack_index)
		await _settle_scene8_world()

	assert_eq(run_director.run_state.status, "completed")
	assert_eq(run_director.run_state.room_history.size(), 3)
	assert_eq(run_director.run_state.reward_history.size(), 3)
	assert_eq(run_director.run_state.reward_history, [REWARD_TRIAL_ATTACK, REWARD_TRIAL_ATTACK, REWARD_TRIAL_ATTACK])
	assert_true(run_director.run_state.temporary_upgrade_ids.has(UPGRADE_TRIAL_ATTACK))
	assert_eq(stats.get_stat_value("attack_power"), attack_before + 9.0)
	assert_eq(str(demo.get("_trial_run_finished_result")), "completed")
	assert_true(bool(demo.get("_trial_upgrade_reward_selected")))
	assert_eq((demo.get("_trial_room_entries") as Array).size(), 3)
	assert_eq(int(demo.get("_trial_rooms_cleared")), 3)
	assert_signal_emit_count(run_director, "room_enter_requested", 3)
	assert_signal_emit_count(run_director, "choosing_reward", 3)
	assert_eq(DomainEventAsserts.find_events(events, "reward_selected").size(), 3)
	assert_signal_emitted_with_parameters(run_director, "run_finished", ["completed"])
	var evt_run_finished_6 := DomainEventAsserts.last_event(events, "run_finished")
	assert_not_null(evt_run_finished_6)
	assert_eq(evt_run_finished_6.source_id, run_director.run_state.run_id)
	assert_eq(evt_run_finished_6.payload.get("result"), "completed")


func test_tc_int_scene8_07_save_manager_round_trips_player_components_and_scopes() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var save := ServiceRegistry.get_port("save") as SaveService
	assert_not_null(save)
	save.save_path = SCENE8_S7_SAVE_PATH

	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()
	assert_eq(save.save_version, 1)

	var player := demo.get_node("Player") as EntityRoot
	var stats := player.get_node("Components/StatsComponent") as StatsComponent
	var health := player.get_node("Components/HealthComponent") as HealthComponent
	var pool := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent
	var status := player.get_node("Controllers/StatusEffectController") as StatusEffectController
	var ability := player.get_node("Controllers/AbilityController") as AbilityController
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController
	var equipment := player.get_node("Controllers/EquipmentController") as EquipmentController

	player.global_position = Vector2(321.0, 123.0)
	stats.set_base_stat("attack_power", 14.0)
	health.current_hp = 47.0
	pool.set_current("mana", 23.0)
	assert_true(status.apply_status(BURN, player, 1, 3.25))
	assert_true(ability.has_ability(FIREBOLT))
	var ability_instance := ability.abilities[FIREBOLT] as AbilityInstance
	ability_instance.current_charges = 0
	ability_instance.cooldown_remaining = 1.25
	ability_instance.set_recharge_duration(2.0)
	assert_true(inventory.add_item(ItemInstance.create("item.demo.herb_potion", 2)))
	var blade := ItemInstance.create(FIELD_BLADE)
	blade.instance_id = "scene8_save_blade"
	assert_true(inventory.add_item(blade))
	assert_true(equipment.equip(blade, "weapon"))
	assert_eq(stats.get_stat_value("attack_power"), 20.0)

	watch_signals(save)
	assert_true(save.save_game(get_tree().root))
	assert_signal_emitted_with_parameters(save, "save_completed", [SCENE8_S7_SAVE_PATH])
	var saved := _read_json(SCENE8_S7_SAVE_PATH)
	assert_eq(int(saved.get("save_version", 0)), 1)
	var saved_roots: Dictionary = saved.get("roots", {})
	var saved_entities: Dictionary = saved.get("entities", {})
	var saved_scopes: Dictionary = saved.get("scopes", {})
	assert_false(saved_roots.has("demo_player"))
	assert_true(saved_entities.has(PLAYER_ID))
	assert_true(saved_roots.has("player_experience"))
	assert_true(saved_scopes.has("world.zone"))
	assert_true(saved_scopes.has("world.run"))
	assert_false(saved.has("payload"))
	assert_false(saved.has("scope_manifest"))
	assert_false(saved.has("save_scopes"))
	var saved_player: Dictionary = saved_entities[PLAYER_ID]
	assert_eq(saved_player.get("scene_path", ""), PLAYER_SCENE)
	var saved_components: Dictionary = saved_player.get("components", {})
	assert_true(saved_components.has("Position"))
	assert_true(saved_components.has("HealthComponent"))
	assert_true(saved_components.has("StatsComponent"))
	assert_true(saved_components.has("ResourcePoolComponent"))
	assert_true(saved_components.has("StatusEffectController"))
	assert_true(saved_components.has("AbilityController"))
	assert_true(saved_components.has("InventoryController"))
	assert_true(saved_components.has("EquipmentController"))

	status.remove_status(BURN)
	equipment.unequip("weapon")
	inventory.model.setup(inventory.capacity)
	stats.set_base_stat("attack_power", 1.0)
	health.current_hp = 1.0
	pool.set_current("mana", 0.0)
	ability.unregister_ability(FIREBOLT)
	player.global_position = Vector2.ZERO

	assert_true(save.load_game(get_tree().root))
	assert_signal_emitted_with_parameters(save, "load_completed", [SCENE8_S7_SAVE_PATH])
	assert_eq(player.global_position, Vector2(321.0, 123.0))
	assert_eq(health.current_hp, 47.0)
	assert_eq(pool.get_current("mana"), 23.0)
	assert_true(status.has_status(BURN))
	var restored_status := status.active_statuses[BURN] as StatusEffectInstance
	assert_eq(restored_status.source_id, PLAYER_ID)
	assert_almost_eq(restored_status.remaining_duration, 3.25, 0.001)
	assert_true(ability.has_ability(FIREBOLT))
	assert_almost_eq(ability.get_cooldown_remaining(FIREBOLT), 1.25, 0.001)
	assert_eq((ability.abilities[FIREBOLT] as AbilityInstance).current_charges, 0)
	assert_eq(inventory.find_item_by_definition("item.demo.herb_potion").quantity, 2)
	assert_eq(inventory.find_item_by_definition(FIELD_BLADE).instance_id, "scene8_save_blade")
	assert_eq(equipment.get_equipped("weapon").definition_id, FIELD_BLADE)
	assert_eq(stats.get_stat_value("attack_power"), 20.0)


func test_tc_int_scene8_09_presentation_tools_spawn_feedback_reuse_pool_and_debug_runtime() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var scene_root := _make_current_scene_root("Scene8S9World")
	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	scene_root.add_child(demo)
	await _settle_scene8_world()

	var time := ServiceRegistry.get_port("time") as TimeService
	var pool := ServiceRegistry.get_port("pool") as PoolService
	var effects := ServiceRegistry.get_port("effects") as EffectService
	var ui := ServiceRegistry.get_port("ui") as UIManager
	assert_not_null(time)
	assert_not_null(pool)
	assert_not_null(effects)
	assert_not_null(ui)

	var feedback := demo.get_node("FeedbackSystem") as FeedbackSystem
	var damage_numbers := feedback.get_node("DamageNumbers") as DamageNumberSystem
	var vfx := feedback.get_node("VFX") as VFXSpawner
	var overlay := demo.get_node("DebugOverlay") as DebugOverlay
	var audio := ServiceRegistry.get_port("audio") as AudioService
	var content := ServiceRegistry.get_port("content") as ContentService
	assert_not_null(audio)
	assert_not_null(content)
	assert_eq(feedback.audio, audio)
	assert_true(content.get_resource(ATTACK_SFX_ID) is AudioDefinition)
	assert_true(content.get_resource("bgm.demo.village") is AudioDefinition)
	assert_true(content.get_resource("sfx.demo.firebolt") is AudioDefinition)
	assert_true(audio.sfx_map.has(ATTACK_SFX_ID))
	assert_eq((audio.sfx_map[ATTACK_SFX_ID] as AudioStream).resource_path, ATTACK_SFX_PATH)
	assert_eq(
		(audio.music_map["bgm.demo.village"] as AudioStream).resource_path,
		DEMO_VILLAGE_BGM_PATH
	)
	assert_eq(
		(audio.music_map["bgm.demo.room"] as AudioStream).resource_path,
		DEMO_ROOM_BGM_PATH
	)
	assert_eq(
		(audio.music_map["bgm.demo.field"] as AudioStream).resource_path,
		DEMO_FIELD_BGM_PATH
	)
	assert_eq((audio.music_map["bgm.demo.village"] as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq((audio.music_map["bgm.demo.village"] as AudioStreamWAV).loop_begin, 0)
	assert_gt((audio.music_map["bgm.demo.village"] as AudioStreamWAV).loop_end, 0)
	assert_eq(audio.current_music_id, "bgm.demo.village")
	assert_not_null(audio.music_player)
	assert_true(audio.music_player.playing)
	assert_eq(audio.music_player.stream, audio.music_map["bgm.demo.village"])
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720)
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/mode")), "canvas_items")
	assert_eq(str(ProjectSettings.get_setting("display/window/stretch/aspect")), "expand")
	assert_true(damage_numbers.use_pool)
	assert_eq(damage_numbers.auto_release_seconds, 0.55)
	assert_true(vfx.use_pool)
	assert_eq(vfx.auto_free_seconds, 0.55)
	assert_eq(feedback.toast_screen_id, TOAST_SCREEN_ID)
	assert_eq(ui.screen_scene_map[TOAST_SCREEN_ID], "res://game/ui/toast_screen.tscn")
	assert_false(overlay.visible)
	assert_false(overlay.show_registered_services)

	var time_before := time.elapsed_gameplay_time
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(time.elapsed_gameplay_time, time_before)

	await _focus_demo_interactable(demo, "ToField/Interactable")
	demo.call("_toggle_field_portal")
	await _settle_scene8_world()
	var beast := demo.call("_field_beast") as EntityRoot
	assert_not_null(beast)
	var beast_health := beast.get_node("Components/HealthComponent") as HealthComponent
	beast_health.current_hp = 35.0
	var player := demo.get_node("Player") as EntityRoot
	var player_stats := player.get_node("Components/StatsComponent") as StatsComponent
	player_stats.set_base_stat("crit_chance", 0.0)

	var damage := DealDamageEffect.new()
	damage.effect_id = "effect.test.scene8.s9_hit"
	damage.base_amount = 5.0
	damage.can_crit = false
	var hit_result := effects.execute(damage, GameplayContext.new().with_source(player).with_target(beast))
	assert_true(hit_result.success)

	assert_eq(damage_numbers.get_child_count(), 1)
	var first_number := damage_numbers.get_child(0) as Node2D
	assert_not_null(first_number)
	assert_true(first_number.visible)
	assert_eq((first_number.get_node("Label") as Label).text, "15")
	assert_eq(first_number.global_position, beast.global_position + damage_numbers.default_offset)
	assert_eq(vfx.get_child_count(), 1)
	var first_vfx := vfx.get_child(0) as Node2D
	assert_not_null(first_vfx)
	assert_true(first_vfx.visible)
	assert_eq(first_vfx.global_position, beast.global_position)
	assert_true(bool(demo.get("_feedback_shake_observed")))
	assert_true(bool(demo.get("_spawn_scene_effect_succeeded")))
	var spawned_hit := scene_root.get_node_or_null("DemoHitVFX") as Node2D
	assert_not_null(spawned_hit)
	assert_true(spawned_hit.visible)
	assert_eq(spawned_hit.global_position, beast.global_position)

	await _wait_scene8_seconds(0.25)
	assert_true(first_number.visible)
	assert_true(first_vfx.visible)
	assert_true(spawned_hit.visible)
	await _wait_scene8_seconds(0.35)
	assert_false(first_number.visible)
	assert_false(first_vfx.visible)
	assert_false(spawned_hit.visible)
	var number_pool: Array = pool._pools.get(DAMAGE_NUMBER_SCENE, [])
	var vfx_pool: Array = pool._pools.get(HIT_VFX_SCENE, [])
	assert_true(number_pool.has(first_number))
	assert_true(vfx_pool.has(first_vfx))
	assert_true(vfx_pool.has(spawned_hit))
	assert_eq(damage_numbers.show_number(Vector2(40.0, 50.0), 7.0, false), first_number)
	var reused_vfx := vfx.spawn("hit", Vector2(60.0, 70.0))
	assert_not_null(reused_vfx)
	if reused_vfx != null:
		assert_true(reused_vfx == first_vfx or reused_vfx == spawned_hit)
		assert_eq((reused_vfx as Node2D).global_position, Vector2(60.0, 70.0))

	var lethal := DealDamageEffect.new()
	lethal.effect_id = "effect.test.scene8.s9_lethal"
	lethal.base_amount = 999.0
	lethal.can_crit = false
	var lethal_result := effects.execute(
		lethal, GameplayContext.new().with_source(player).with_target(beast)
	)
	assert_true(lethal_result.success)
	await get_tree().process_frame
	assert_true(bool(demo.get("_feedback_toast_observed")))
	assert_true(ui.is_screen_open(TOAST_SCREEN_ID))
	var toast := ui.active_screens[TOAST_SCREEN_ID] as Control
	assert_true((toast.get_node("Label") as Label).text.begins_with("Defeated "))
	await _wait_scene8_seconds(0.25)

	overlay.visible = true
	overlay.show_registered_services = true
	overlay._process(0.0)
	var overlay_text := (overlay.get_child(0) as Label).text
	assert_true(overlay_text.contains("Services:"))
	assert_true(overlay_text.contains("time"))
	assert_true(overlay_text.contains("pool"))
	assert_true(overlay_text.contains("ui"))
	assert_true(overlay_text.contains("Zone: %s" % ZONE_FIELD))
	assert_true(overlay_text.contains("Run: ready"))
	assert_true(overlay_text.contains("Runtime:"))


func test_tc_int_scene8_10_interaction_manual_quest_and_dash() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()

	var world := ServiceRegistry.get_port("world") as WorldService
	var dialogue := ServiceRegistry.get_port("dialogue") as DialogueService
	var quest := ServiceRegistry.get_port("quest") as QuestService
	var effects := ServiceRegistry.get_port("effects") as EffectService
	effects.trace_enabled = true
	var router := ServiceRegistry.get_port("commands") as CommandService
	var actions := ServiceRegistry.get_port("actions") as ActionService
	assert_not_null(world)
	assert_not_null(dialogue)
	assert_not_null(quest)
	assert_not_null(effects)
	assert_not_null(router)
	assert_not_null(actions)
	assert_eq(world.current_zone_id, ZONE_VILLAGE)

	var player := demo.get_node("Player") as EntityRoot
	var interaction := player.get_node("Components/InteractionComponent") as InteractionComponent
	var state_machine := player.get_node("StateMachine") as Hfsm
	assert_not_null(interaction)
	assert_not_null(state_machine)

	watch_signals(interaction)
	var to_room := await _focus_demo_interactable(demo, "ToRoom/Interactable")
	assert_true(to_room is Portal)
	assert_eq(interaction.current_interactable, to_room)
	assert_signal_emitted_with_parameters(interaction, "interactable_focused", [to_room])

	demo.call("_toggle_room_portal")
	await _settle_scene8_world()
	assert_eq(world.current_zone_id, ZONE_ROOM)
	assert_true(bool(demo.get("_portal_interaction_succeeded")))

	watch_signals(dialogue)
	watch_signals(quest)
	var elder := await _focus_demo_interactable(demo, "Elder/InteractionArea/Interactable")
	assert_true(elder is DialogueInteractable)
	assert_eq(interaction.current_interactable, elder)

	demo.call("_request_manual_task")
	await get_tree().process_frame

	var state := quest.get_state(QUEST_MANUAL_ID)
	assert_not_null(state)
	assert_eq(state.status, "turned_in")
	assert_eq(state.get_progress(QUEST_MANUAL_OBJECTIVE_ID), 1)
	assert_true(bool(demo.get("_manual_quest_completed")))
	assert_signal_emitted_with_parameters(dialogue, "dialogue_started", ["dialogue.demo.elder"])
	assert_signal_emitted_with_parameters(
		quest, "objective_advanced", [QUEST_MANUAL_ID, QUEST_MANUAL_OBJECTIVE_ID, 1, 1]
	)
	assert_signal_emitted_with_parameters(quest, "quest_completed", [QUEST_MANUAL_ID])
	assert_signal_emitted_with_parameters(quest, "quest_turned_in", [QUEST_MANUAL_ID])

	var result_ids: Array[String] = []
	for result in effects.recent_results:
		result_ids.append(result.effect_id)
	assert_true(result_ids.has("effect.demo.advance_supply_request"))
	assert_true(result_ids.has("effect.demo.complete_supply_request"))

	var start := player.global_position
	assert_true(
		router.dispatch(
			GameCommand.create(
				BuiltinCommands.DASH, PLAYER_ID, PLAYER_ID, {"direction": Vector2.RIGHT}
			)
		)
	)
	assert_eq(state_machine.get_current_path(), "Player/Dash")
	assert_eq(actions.active_actions.size(), 1)
	assert_true(actions.active_actions[0] is DashAction)
	actions._process(0.10)
	assert_gt(player.global_position.x, start.x)
	actions._process(0.20)
	assert_eq(actions.active_actions.size(), 0)
	assert_eq(state_machine.get_current_path(), "Player/Idle")


func test_tc_int_scene8_11_trial_cave_shortcuts_close_room_without_zone_mismatch() -> void:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	bootstrap.save_path = SCENE8_BOOT_SAVE_PATH
	add_child_autofree(bootstrap)

	var demo := (load(DEMO_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()

	var world := ServiceRegistry.get_port("world") as WorldService
	assert_not_null(world)
	await _focus_demo_interactable(demo, "ToField/Interactable")
	demo.call("_toggle_field_portal")
	await _settle_scene8_world()
	assert_eq(world.current_zone_id, ZONE_FIELD)

	var room_root := demo.get_node("RoomRoot") as Node2D
	var run_director := demo.get_node("RunDirector") as RunDirector
	assert_not_null(room_root)
	assert_not_null(run_director)

	demo.call("_enter_trial_cave")
	await _settle_scene8_world()
	assert_false(room_root.visible)
	assert_null(run_director.run_state)

	await _focus_demo_interactable(demo, "TrialCaveArea/Interactable")
	demo.call("_enter_trial_cave")
	await _settle_scene8_world()
	assert_true(room_root.visible)
	assert_gt(room_root.get_child_count(), 0)
	assert_eq(run_director.run_state.status, "active")

	demo.call("_toggle_field_portal")
	await _settle_scene8_world()
	assert_eq(world.current_zone_id, ZONE_FIELD)
	assert_eq((demo.call("_current_zone_root") as Node).name, "Field")
	assert_false(room_root.visible)
	assert_eq(room_root.get_child_count(), 0)
	assert_eq(run_director.run_state.status, "failed")
	assert_eq(str(demo.get("_trial_run_finished_result")), "failed:field_gate")
	assert_true((demo.get_node("HUD/StatsPanel/ZoneInfo") as Label).text.contains("Field"))

	await _focus_demo_interactable(demo, "TrialCaveArea/Interactable")
	demo.call("_enter_trial_cave")
	await _settle_scene8_world()
	assert_true(room_root.visible)
	assert_eq(run_director.run_state.status, "active")

	demo.call("_enter_trial_cave")
	await _settle_scene8_world()
	assert_eq(world.current_zone_id, ZONE_FIELD)
	assert_false(room_root.visible)
	assert_eq(run_director.run_state.status, "failed")
	assert_eq(str(demo.get("_trial_run_finished_result")), "failed:cave_toggle")


func _resolve_damage(source: Node, target: Node) -> float:
	var request := DamageRequest.new()
	request.source = source
	request.target = target
	request.base_amount = 10.0
	request.can_crit = false
	return (ServiceRegistry.get_port("combat") as CombatService).resolve(request).final_amount


func _disable_beast_ai(beast: Node) -> void:
	var brain := beast.get_node_or_null("Controllers/SimpleAIEnemyBrain") as SimpleAIEnemyBrain
	if brain != null:
		brain.enabled = false


func _modifier_count(stats: StatsComponent, stat_id: String) -> int:
	var modifiers: Array = stats.modifiers_by_stat.get(stat_id, [])
	return modifiers.size()


func _settle_scene8_world() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func _focus_demo_interactable(demo: Node, interactable_path: String) -> Interactable:
	var root := demo.call("_current_zone_root") as Node
	assert_not_null(root)
	var interactable := root.get_node_or_null(interactable_path) as Interactable
	assert_not_null(interactable)
	var area := interactable.get_parent() as Area2D
	assert_not_null(area)
	var player := demo.get_node("Player") as EntityRoot
	player.global_position = area.global_position + Vector2(1000.0, 0.0)
	await get_tree().physics_frame
	player.global_position = area.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	return interactable


func _wait_scene8_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _make_current_scene_root(root_name: String) -> Node2D:
	var root := Node2D.new()
	root.name = root_name
	var tree := get_tree()
	tree.root.add_child(root)
	_previous_current_scene = tree.current_scene
	_current_scene_override = root
	tree.current_scene = root
	return root


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	assert_true(parsed is Dictionary)
	return parsed if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()


func _reward_options_have(options: Array[RewardOption], reward_id: String) -> bool:
	for option in options:
		if option.reward_id == reward_id:
			return true
	return false
