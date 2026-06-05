extends GutTest


const PLAYER_SCENE := "res://game/demo/entities/player/player.tscn"
const BEAST_SCENE := "res://game/demo/phase8/entities/field_beast.tscn"
const PHASE8_SCENE := "res://game/demo/phase8_village_rpg.tscn"
const FIELD_SCENE := "res://game/demo/phase8/scenes/field.tscn"
const CONTENT_DB := "res://game/demo/phase8/resources/phase8_rpg_content.tres"
const PLAYER_ID := "player_001"
const BEAST_ID := "enemy.phase8.field_beast"
const ENTITY_FIELD_BEAST := "entity.phase8.field_beast"
const FIREBOLT := "ability.phase8.firebolt"
const BURN := "status.phase8.burn"
const FIELD_BLADE := "item.phase8.field_blade"
const ZONE_FIELD := "zone.phase8.field"


func after_each() -> void:
	IntTestHelpers.cleanup_service_registry()
	CombatResolver._default = null


# S0: the real player scene already carries a command -> HFSM -> action -> hitbox
# chain. This drives it end to end through the kernel pipeline instead of bare keys
# or a scripted DealDamageEffect: a MOVE command makes the Move state move the body,
# and ATTACK commands run a TimedAttackAction whose HitboxComponent overlaps the field
# beast HurtboxComponent, feeding CombatResolver until the beast dies.
func test_tc_int_scene8_00_command_hfsm_action_drives_combat_to_death() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	add_child_autofree(bootstrap)

	var router := ServiceRegistry.get_service("commands") as CommandRouter
	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	var events := ServiceRegistry.get_service("events") as EventRouter
	assert_not_null(router)
	assert_not_null(actions)
	assert_not_null(events)

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody2D
	player.global_position = Vector2.ZERO
	add_child_autofree(player)

	var receiver := player.get_node("CommandReceiver") as CommandReceiver
	var state_machine := player.get_node("StateMachine") as StateMachine
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
	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as CharacterBody2D
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

	# --- ATTACK 1: command -> Attack state -> TimedAttackAction -> hitbox -> CombatResolver ---
	assert_true(router.dispatch(GameCommand.create(BuiltinCommands.ATTACK, PLAYER_ID, PLAYER_ID, {})))
	assert_eq(state_machine.get_current_path(), "Player/Attack")
	assert_eq(actions.active_actions.size(), 1)
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
	assert_signal_emitted(events, "damage_applied")

	# finish the swing; the state machine returns to Idle and the action drains
	actions._process(0.25)
	assert_eq(actions.active_actions.size(), 0)
	assert_eq(state_machine.get_current_path(), "Player/Idle")

	# --- ATTACK 2: lethal hit -> HealthComponent.die -> EventRouter entity_died ---
	assert_true(router.dispatch(GameCommand.create(BuiltinCommands.ATTACK, PLAYER_ID, PLAYER_ID, {})))
	assert_eq(state_machine.get_current_path(), "Player/Attack")
	actions._process(0.08)
	assert_true(beast_health.dead)
	assert_eq(beast_health.current_hp, 0.0)
	assert_signal_emitted(beast_health, "died")
	assert_signal_emitted_with_parameters(events, "entity_died", [BEAST_ID, beast])

	actions._process(0.25)
	assert_eq(state_machine.get_current_path(), "Player/Idle")


# S1: the firebolt skill pipeline. The player scene registers ability.phase8.firebolt from
# the live content database; casting it spends mana, channels through a CastAction (cast_time
# > 0) before its effects fire, then DealDamage + ApplyStatus burn the field beast and a
# cooldown starts. TargetInRangeCondition gates an out-of-range cast and CooldownReadyCondition
# blocks the immediate re-cast.
func test_tc_int_scene8_01_firebolt_pipeline_spends_mana_gates_range_and_burns() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	add_child_autofree(bootstrap)

	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	assert_not_null(actions)

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody2D
	player.global_position = Vector2.ZERO
	add_child_autofree(player)

	var ability := player.get_node("Controllers/AbilityController") as AbilityController
	var input_reader := player.get_node("InputReader")
	var pool := player.get_node("Components/ResourcePoolComponent") as ResourcePoolComponent
	# the shared player scene stays generic; Scene8 registers firebolt from live content.
	assert_eq(str(input_reader.get("cast_ability_id")), "")
	assert_false(ability.has_ability(FIREBOLT))
	assert_true(ability.register_ability(FIREBOLT))
	assert_true(ability.has_ability(FIREBOLT))
	assert_eq(pool.get_current("mana"), 50.0)

	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as CharacterBody2D
	_disable_beast_ai(beast)
	add_child_autofree(beast)
	var beast_health := beast.get_node("Components/HealthComponent") as HealthComponent
	var beast_status := beast.get_node("Controllers/StatusEffectController") as StatusEffectController

	# --- TargetInRangeCondition gates a cast beyond the 120px firebolt range ---
	beast.global_position = Vector2(400.0, 0.0)
	var ctx_far := GameplayContext.new().with_source(player).with_target(beast)
	assert_false(ability.can_cast(FIREBOLT, ctx_far))
	assert_eq(ability.get_cast_failure_reason(FIREBOLT, ctx_far), "target_out_of_range")

	# --- in range: cast pays mana up front and channels through a CastAction (cast_time > 0) ---
	beast.global_position = Vector2(80.0, 0.0)
	watch_signals(ability)
	watch_signals(beast_health)
	var ctx := GameplayContext.new().with_source(player).with_target(beast)
	assert_true(ability.can_cast(FIREBOLT, ctx))
	assert_true(ability.cast(FIREBOLT, ctx))
	# ResourcePoolComponent.spend is charged immediately
	assert_eq(pool.get_current("mana"), 40.0)
	assert_signal_emitted(ability, "ability_cast_started")
	assert_eq(actions.active_actions.size(), 1)
	assert_true(actions.active_actions[0] is CastAction)
	# the channel is still in flight: no damage, no burn, no finish yet
	assert_eq(beast_health.current_hp, 35.0)
	assert_false(beast_status.has_status(BURN))
	assert_signal_not_emitted(ability, "ability_cast_finished")

	# --- advance the channel past cast_time: DealDamage + ApplyStatus fire, cooldown starts ---
	actions._process(0.5)
	assert_eq(actions.active_actions.size(), 0)
	assert_signal_emitted(ability, "ability_cast_finished")
	assert_signal_emitted(ability, "cooldown_started")
	# 35 - (firebolt base 8 + player attack_power 10), no crit/defense
	assert_eq(beast_health.current_hp, 17.0)
	assert_signal_emitted(beast_health, "damaged")
	assert_true(beast_status.has_status(BURN))

	# --- CooldownReadyCondition now blocks the immediate re-cast ---
	assert_false(ability.is_cooldown_ready(FIREBOLT))
	var ctx_cd := GameplayContext.new().with_source(player).with_target(beast)
	assert_false(ability.cast(FIREBOLT, ctx_cd))
	assert_eq(ability.get_cast_failure_reason(FIREBOLT, ctx_cd), "on_cooldown: %s" % FIREBOLT)
	var cd_cond := CooldownReadyCondition.new()
	cd_cond.ability_id = FIREBOLT
	ctx_cd.ability_id = FIREBOLT
	assert_false(cd_cond.evaluate(ctx_cd))


# S2: phase8 burn is now a full StatusEffectDefinition, not just an applied tag.
# It creates a StatusEffectInstance, applies a StatModifierDefinition-driven defense
# modifier while active, executes DealDamage + LogEffect on tick, removes the modifier
# when duration expires, and the elder dialogue exposes an ApplyStatModifierEffect
# blessing that CombatResolver reads through StatsComponent.
func test_tc_int_scene8_02_burn_ticks_logs_restores_stats_and_elder_blesses_attack() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_service("content") as ContentRegistry
	var effects := ServiceRegistry.get_service("effects") as EffectExecutor
	var events := ServiceRegistry.get_service("events") as EventRouter
	var dialogue := ServiceRegistry.get_service("dialogue") as DialogueController
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
	assert_eq(burn_def.stat_modifiers[0].modifier_id, "mod.phase8.burn_defense_down")

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody2D
	add_child_autofree(player)
	var player_stats := player.get_node("Components/StatsComponent") as StatsComponent
	player_stats.set_base_stat("attack_power", 0.0)
	player_stats.set_base_stat("crit_chance", 0.0)

	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as CharacterBody2D
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
	assert_eq((effects.recent_results[-1] as EffectResult).effect_id, "effect.phase8.burn_tick_log")
	assert_eq((events.recent_events[-1] as DomainEvent).event_type, "phase8_burn_tick")
	assert_eq(str((events.recent_events[-1] as DomainEvent).payload.get("message", "")), "Phase8 burn tick")

	beast_status._process(3.1)

	assert_false(beast_status.has_status(BURN))
	assert_eq(beast_stats.get_stat_value("defense"), 4.0)
	assert_eq(_modifier_count(beast_stats, "defense"), 0)
	assert_signal_emitted_with_parameters(beast_status, "status_removed", [BURN])

	var elder_dialogue := content.get_resource("dialogue.phase8.elder") as DialogueDefinition
	var offer := elder_dialogue.get_node("n.offer")
	assert_eq(offer.choices.size(), 2)
	assert_true(offer.choices[1].effects[0] is ApplyStatModifierEffect)

	var attack_before := player_stats.get_stat_value("attack_power")
	assert_true(dialogue.start("dialogue.phase8.elder", GameplayContext.new().with_source(player)))
	dialogue.choose(1)
	assert_eq(player_stats.get_stat_value("attack_power"), attack_before + 5.0)
	assert_eq((effects.recent_results[-1] as EffectResult).effect_id, "effect.phase8.elder_blessing_attack")

	beast_stats.set_base_stat("defense", 0.0)
	var request := DamageRequest.new()
	request.source = player
	request.target = beast
	request.base_amount = 10.0
	request.can_crit = false
	var damage := CombatResolver.get_default().resolve(request)
	assert_eq(damage.final_amount, 15.0)


# S3: the field blade is a weapon-slot equippable that the EquipmentController applies through
# the StatModifier path. Equipping it raises attack_power and the extra power flows straight into
# CombatResolver damage; unequipping restores both; and a Saveable round-trip on the controller
# re-applies the equipped item and its modifier.
func test_tc_int_scene8_03_field_blade_equip_boosts_attack_changes_damage_and_round_trips() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_service("content") as ContentRegistry
	assert_not_null(content)

	# the blade content: a weapon-slot item carrying a +attack_power StatModifierDefinition
	var blade_def := content.get_resource(FIELD_BLADE) as ItemDefinition
	assert_not_null(blade_def)
	assert_eq(blade_def.equipment_slot, "weapon")
	assert_false(blade_def.stackable)
	assert_eq(blade_def.stat_modifiers.size(), 1)
	assert_eq(blade_def.stat_modifiers[0].stat_id, "attack_power")
	assert_eq(blade_def.stat_modifiers[0].value, 6.0)

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as CharacterBody2D
	add_child_autofree(player)
	var equipment := player.get_node("Controllers/EquipmentController") as EquipmentController
	var inventory := player.get_node("Controllers/InventoryController") as InventoryController
	var stats := player.get_node("Components/StatsComponent") as StatsComponent
	stats.set_base_stat("crit_chance", 0.0)

	# a defenseless target to read combat damage off CombatResolver
	var beast := (load(BEAST_SCENE) as PackedScene).instantiate() as CharacterBody2D
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


# S4: field beast is no longer a static child of field.tscn. Phase8 registers an
# EntityDefinition in live content, enters the field, and creates the beast through
# EntitySpawner so identity, tags and base stats all come from data.
func test_tc_int_scene8_04_field_beast_spawns_from_entity_definition() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	add_child_autofree(bootstrap)

	var content := ServiceRegistry.get_service("content") as ContentRegistry
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

	var demo := (load(PHASE8_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()
	demo.call("_toggle_field_portal")
	await _settle_scene8_world()

	var world := ServiceRegistry.get_service("world") as WorldRouter
	assert_eq(world.current_zone_id, ZONE_FIELD)
	var root := demo.call("_current_zone_root") as Node
	assert_not_null(root)
	var marker := root.get_node_or_null("FieldBeastSpawn") as Node2D
	assert_not_null(marker)
	var beast := root.get_node_or_null("FieldBeast") as Node2D
	assert_not_null(beast)
	assert_eq(beast.global_position, marker.global_position)

	var identity := beast.get_node("EntityIdentity") as EntityIdentity
	assert_eq(identity.definition_id, ENTITY_FIELD_BEAST)
	assert_eq(identity.display_name, "Field Beast")
	assert_eq(identity.faction, "enemy")
	assert_true(identity.tags.has("enemy"))
	assert_true(identity.tags.has("living"))
	assert_true(identity.tags.has("field_beast"))
	var receiver := beast.get_node("CommandReceiver") as CommandReceiver
	assert_eq(receiver.receiver_id, identity.entity_id)
	var commands := ServiceRegistry.get_service("commands") as CommandRouter
	assert_true(commands._receivers.has(identity.entity_id))
	assert_false(commands._receivers.has(BEAST_ID))

	var stats := beast.get_node("Components/StatsComponent") as StatsComponent
	assert_eq(stats.get_stat_value("max_hp"), 35.0)
	assert_eq(stats.get_stat_value("defense"), 0.0)
	assert_eq(stats.get_stat_value("attack_power"), 0.0)
	assert_eq(stats.get_stat_value("move_speed"), 120.0)
	var save_data := stats.to_save_data()
	assert_true((save_data["base_overrides"] as Dictionary).is_empty())


func test_tc_int_scene8_05_enemy_ai_approaches_attacks_and_damages_player() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [load(CONTENT_DB) as ResourceDatabase]
	add_child_autofree(bootstrap)

	var demo := (load(PHASE8_SCENE) as PackedScene).instantiate()
	add_child_autofree(demo)
	await _settle_scene8_world()
	demo.call("_toggle_field_portal")
	await _settle_scene8_world()

	var world := ServiceRegistry.get_service("world") as WorldRouter
	assert_eq(world.current_zone_id, ZONE_FIELD)

	var player := demo.get_node("Player") as CharacterBody2D
	var player_health := player.get_node("Components/HealthComponent") as HealthComponent
	var player_hurtbox := player.get_node_or_null("Components/HurtboxComponent") as HurtboxComponent
	assert_not_null(player_hurtbox)
	player.global_position = Vector2.ZERO
	player_health.current_hp = player_health.get_max_hp()

	var beast := demo.call("_field_beast") as CharacterBody2D
	assert_not_null(beast)
	beast.global_position = Vector2(110.0, 0.0)
	var brain := beast.get_node("Controllers/SimpleAIEnemyBrain") as SimpleAIEnemyBrain
	var receiver := beast.get_node("CommandReceiver") as CommandReceiver
	var state_machine := beast.get_node("StateMachine") as StateMachine
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
	var events := ServiceRegistry.get_service("events") as EventRouter
	watch_signals(events)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hp_before := player_health.current_hp
	brain.think()
	assert_eq(brain.blackboard.get_value("intent", ""), "attack")
	assert_eq(receiver.command_history[-1].command_type, BuiltinCommands.ATTACK)
	assert_eq(state_machine.get_current_path(), "Enemy/Attack")

	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	assert_eq(actions.active_actions.size(), 1)
	assert_true(actions.active_actions[0] is TimedAttackAction)
	actions._process(0.08)
	assert_lt(player_health.current_hp, hp_before)
	assert_eq(player_health.current_hp, hp_before - 8.0)
	assert_signal_emitted(player_health, "damaged")
	assert_signal_emitted(events, "damage_applied")
	actions._process(0.25)
	assert_eq(state_machine.get_current_path(), "Enemy/Idle")


func _resolve_damage(source: Node, target: Node) -> float:
	var request := DamageRequest.new()
	request.source = source
	request.target = target
	request.base_amount = 10.0
	request.can_crit = false
	return CombatResolver.get_default().resolve(request).final_amount


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
