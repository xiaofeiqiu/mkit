extends GutTest


const PLAYER_SCENE := "res://game/demo/entities/player/player.tscn"
const BEAST_SCENE := "res://game/demo/phase8/entities/field_beast.tscn"
const CONTENT_DB := "res://game/demo/phase8/resources/phase8_rpg_content.tres"
const PLAYER_ID := "player_001"
const BEAST_ID := "enemy.phase8.field_beast"
const FIREBOLT := "ability.phase8.firebolt"
const BURN := "status.phase8.burn"


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


func _modifier_count(stats: StatsComponent, stat_id: String) -> int:
	var modifiers: Array = stats.modifiers_by_stat.get(stat_id, [])
	return modifiers.size()
