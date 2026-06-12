class_name DemoAutoRunVerifier
extends RefCounted


const REWARD_TRIAL_ATTACK := "reward.demo.trial_attack"


func run(host, save_payload_verifier) -> bool:
	if host._auto_run_started:
		return false
	host._auto_run_started = true
	await host._settle_world()
	await _verify_debug_overlay(host)
	await host._focus_zone_interactable("ToRoom/Interactable")
	host._toggle_room_portal()
	await host._settle_world()
	await host._focus_zone_interactable("Elder/InteractionArea/Interactable")
	host._talk_or_advance_dialogue()
	await host.get_tree().process_frame
	host._talk_or_advance_dialogue()
	await host.get_tree().process_frame
	host._talk_or_advance_dialogue()
	await host._settle_world()
	await host._focus_zone_interactable("ToVillage/Interactable")
	host._toggle_room_portal()
	await host._settle_world()
	await host._focus_zone_interactable("ToField/Interactable")
	host._toggle_field_portal()
	await host._settle_world()
	await host._dash_player_once()
	await host._settle_world()
	await host._cast_firebolt_at_beast()
	await host._settle_world()
	await host._engage_field_beast_via_commands()
	await host._settle_world()
	await _run_trial(host)
	await host._settle_world()
	await host._focus_zone_interactable("ToVillage/Interactable")
	host._toggle_field_portal()
	await host._settle_world()
	await _wait_for_hit_vfx_cleanup(host)
	await host._focus_zone_interactable("ToRoom/Interactable")
	host._toggle_room_portal()
	await host._settle_world()
	await host._focus_zone_interactable("Elder/InteractionArea/Interactable")
	host._request_elder_blessing()
	await host._settle_world()
	await host._focus_zone_interactable("Elder/InteractionArea/Interactable")
	host._request_manual_task()
	await host._settle_world()
	await host._focus_zone_interactable("ToVillage/Interactable")
	host._toggle_room_portal()
	await host._settle_world()
	host._toggle_field_blade()
	await host._settle_world()
	host._toggle_field_blade()
	await host._settle_world()
	host._toggle_field_blade()
	await host._settle_world()
	await host._focus_zone_interactable("VillageSupply/Interactable")
	host._buy_potion()
	await host.get_tree().process_frame
	host._buy_potion()
	await host.get_tree().process_frame
	host._sell_claw()
	await host.get_tree().process_frame
	host._use_potion()
	await host.get_tree().process_frame
	await save_payload_verifier.roundtrip(host)
	var complete: bool = host._demo_loop_complete()
	if complete:
		host._log("[AUTO] demo RPG loop complete")
	else:
		host._log("[AUTO] missing: %s" % ", ".join(host._demo_missing_requirements()))
		host._log("[AUTO] demo RPG loop incomplete")
	host._cleanup_audio_players()
	await host._settle_shutdown()
	host.get_tree().quit(0 if complete else 1)
	return complete


func _run_trial(host) -> void:
	await host._focus_zone_interactable("TrialCaveArea/Interactable")
	host._enter_trial_cave()
	await host._settle_world()
	var guard := 0
	while not host._is_trial_terminal() and guard < 12:
		var run_director := host._run_director as RunDirector
		var status := run_director.run_state.status if run_director != null and run_director.run_state != null else ""
		if status == "active":
			_defeat_trial_room_enemies(host)
		elif status == "choosing_reward":
			host._select_trial_reward(_trial_reward_index(host, REWARD_TRIAL_ATTACK))
		await host._settle_world()
		guard += 1
	if not host._is_trial_completed():
		host._log("[TRIAL] auto run did not complete")


func _defeat_trial_room_enemies(host) -> void:
	var run_director := host._run_director as RunDirector
	if run_director == null or run_director.current_room_controller == null:
		host._log("[TRIAL] no active room")
		return
	var effects := host._effects as EffectService
	if effects == null:
		host._log("[TRIAL] effect service missing")
		return
	var room := run_director.current_room_controller
	if room.runtime == null:
		host._log("[TRIAL] active room has no runtime")
		return
	var enemy_ids := room.runtime.active_enemy_ids.duplicate()
	for enemy_id in enemy_ids:
		var enemy := room.active_enemies.get(enemy_id, null) as Node
		if enemy == null:
			continue
		var brain := enemy.get_node_or_null("Controllers/SimpleAIEnemyBrain") as SimpleAIEnemyBrain
		if brain != null:
			brain.enabled = false
		var damage := DealDamageEffect.new()
		damage.effect_id = "effect.demo.trial_strike"
		damage.base_amount = 999.0
		damage.can_crit = false
		effects.execute(damage, GameplayContext.new().with_source(host._player).with_target(enemy))


func _trial_reward_index(host, reward_id: String) -> int:
	for i in range(host._pending_trial_rewards.size()):
		if host._pending_trial_rewards[i].reward_id == reward_id:
			return i
	return 0


func _verify_debug_overlay(host) -> void:
	var debug_overlay := host._debug_overlay as DebugOverlay
	if debug_overlay == null:
		return
	debug_overlay.visible = true
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	var label: Label = null
	if debug_overlay.get_child_count() > 0:
		label = debug_overlay.get_child(0) as Label
	var text := label.text if label != null else ""
	host._debug_overlay_verified = (
		text.contains("Zone:")
		and text.contains("Run:")
		and text.contains("Runtime:")
		and text.contains("State:")
		and text.contains("HP:")
	)
	if host._debug_overlay_verified:
		host._log("[AUTO] debug overlay status verified")
	debug_overlay.visible = false


func _wait_for_hit_vfx_cleanup(host) -> void:
	var elapsed := 0.0
	while elapsed < 1.0 and host._visible_hit_vfx_count() > 0:
		await host.get_tree().process_frame
		elapsed += host.get_process_delta_time()
	host._hit_vfx_cleanup_verified = host._visible_hit_vfx_count() == 0
	if host._hit_vfx_cleanup_verified:
		host._log("[AUTO] hit VFX cleanup verified")
