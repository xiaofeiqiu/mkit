extends GutTest


class UpgradeProbeEffect:
	extends GameEffect
	var applied_count: int = 0
	var last_source: Node = null
	var last_payload: Dictionary = {}

	func _apply_impl(context: GameplayContext) -> EffectResult:
		applied_count += 1
		if context != null:
			last_source = context.source
			last_payload = context.payload.duplicate(true)
		return EffectResult.ok(effect_id, {"applied_count": applied_count})


class LegacyProgressionMigration:
	extends SaveMigration
	var applied_count: int = 0

	func _migrate_impl(data: Dictionary) -> Dictionary:
		applied_count += 1
		var payload: Dictionary = data.get("payload", {})
		var legacy_progression: Dictionary = payload.get("legacy_progression", {})
		var unlocked: Array[String] = []
		var legacy_unlocked: Array = legacy_progression.get("unlocked_content_ids", [])
		unlocked.assign(legacy_unlocked)
		var upgrade_id := str(legacy_progression.get("upgrade_id", ""))
		var currencies := {"crystal": int(legacy_progression.get("crystal", 0))}
		var upgrade_levels: Dictionary = {}
		upgrade_levels[upgrade_id] = int(legacy_progression.get("upgrade_level", 0))
		payload["progression"] = {
			"currencies": currencies,
			"upgrade_levels": upgrade_levels,
			"unlocked_content_ids": unlocked,
		}
		var legacy_experience: Dictionary = payload.get("legacy_experience", {})
		payload["experience"] = {
			"current_level": int(legacy_experience.get("level", 1)),
			"current_xp": int(legacy_experience.get("xp", 0)),
		}
		payload.erase("legacy_progression")
		payload.erase("legacy_experience")
		data["payload"] = payload
		return data


class ProbeAnalyticsService:
	extends AnalyticsService
	var tracked_events: Array[Dictionary] = []
	var user_properties: Dictionary = {}

	func track_event(event_name: String, properties: Dictionary = {}) -> void:
		tracked_events.append(
			{"event_name": event_name, "properties": properties.duplicate(true)}
		)

	func set_user_property(key: String, value: Variant) -> void:
		user_properties[key] = value


var _save_path: String = "/tmp/mkit_progression_save_platform_integration_save.json"


func after_each() -> void:
	IntTestHelpers.remove_file(_save_path)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_prog_01_xp_level_up_progression_unlock_and_save() -> void:
	var effect := UpgradeProbeEffect.new()
	effect.effect_id = "fx.int.upgrade_probe"
	_boot_with_database(_make_progression_database(effect))

	var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
	var save := ServiceRegistry.get_service("save") as SaveManager
	var effects := ServiceRegistry.get_service("effects") as EffectExecutor
	assert_not_null(progression)
	assert_not_null(save)
	assert_not_null(effects)
	save.save_path = _save_path

	var player := _make_player_with_experience()
	var experience := player.get_node("Components/ExperienceComponent") as ExperienceComponent
	assert_not_null(experience)

	watch_signals(experience)
	watch_signals(progression)
	watch_signals(save)

	experience.add_xp(35)
	assert_eq(experience.current_level, 3)
	assert_eq(experience.current_xp, 5)
	assert_eq(experience.get_xp_to_next_level(), 45)
	assert_signal_emitted_with_parameters(experience, "level_up", [1, 2], 0)
	assert_signal_emitted_with_parameters(experience, "level_up", [2, 3], 1)
	assert_signal_emitted_with_parameters(experience, "xp_changed", [5, 45])

	progression.add_currency("crystal", 100)
	var context := GameplayContext.new()
	context.with_source(player)
	context.with_payload_value("origin", "integration")
	assert_true(progression.can_unlock("upgrade.int.archive"))
	assert_true(progression.unlock_or_level_up("upgrade.int.archive", context))
	assert_eq(progression.get_currency("crystal"), 70)
	assert_eq(progression.state.get_upgrade_level("upgrade.int.archive"), 1)
	assert_true(progression.state.unlocked_content_ids.has("ability.int.archive"))
	assert_eq(effect.applied_count, 1)
	assert_eq(effect.last_source, player)
	assert_eq(effect.last_payload.get("origin", ""), "integration")
	assert_eq(effects.recent_results[-1].effect_id, "fx.int.upgrade_probe")
	assert_signal_emitted_with_parameters(
		progression, "content_unlocked", ["ability.int.archive"]
	)
	assert_signal_emitted_with_parameters(
		progression, "upgrade_level_changed", ["upgrade.int.archive", 1]
	)

	assert_true(save.save_game(get_tree().root))
	assert_signal_emitted_with_parameters(save, "save_completed", [_save_path])
	var saved := _read_json(_save_path)
	var payload: Dictionary = saved.get("payload", {})
	assert_true(payload.has("experience"))
	assert_true(payload.has("progression"))
	assert_false(payload.has("InventoryController"))
	assert_eq(int(payload["experience"]["current_level"]), 3)
	assert_eq(int(payload["progression"]["currencies"]["crystal"]), 70)

	experience.current_level = 1
	experience.current_xp = 0
	progression.state = ProgressionState.new()
	assert_true(save.load_game(get_tree().root))
	assert_signal_emitted_with_parameters(save, "load_completed", [_save_path])
	assert_eq(experience.current_level, 3)
	assert_eq(experience.current_xp, 5)
	assert_eq(progression.get_currency("crystal"), 70)
	assert_eq(progression.state.get_upgrade_level("upgrade.int.archive"), 1)
	assert_true(progression.state.unlocked_content_ids.has("ability.int.archive"))


func test_tc_int_prog_02_load_applies_migration_before_restore() -> void:
	_boot_with_database(ResourceDatabase.new())
	var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
	var save := ServiceRegistry.get_service("save") as SaveManager
	assert_not_null(progression)
	assert_not_null(save)
	save.save_path = _save_path
	save.save_version = 2
	var migration := LegacyProgressionMigration.new()
	migration.from_version = 1
	migration.to_version = 2
	var migrations: Array[SaveMigration] = [migration]
	save.migrations = migrations

	var player := _make_player_with_experience()
	var experience := player.get_node("Components/ExperienceComponent") as ExperienceComponent
	_write_json(
		_save_path,
		{
			"save_version": 1,
			"game_version": "0.0.1",
			"timestamp": "",
			"profile_id": "legacy_profile",
			"payload": {
				"legacy_progression": {
					"crystal": 42,
					"upgrade_id": "upgrade.int.legacy",
					"upgrade_level": 2,
					"unlocked_content_ids": ["ability.int.legacy"],
				},
				"legacy_experience": {
					"level": 4,
					"xp": 12,
				},
			},
		}
	)

	watch_signals(save)
	assert_true(save.load_game(get_tree().root))
	assert_signal_emitted_with_parameters(save, "load_completed", [_save_path])
	assert_eq(migration.applied_count, 1)
	assert_eq(progression.get_currency("crystal"), 42)
	assert_eq(progression.state.get_upgrade_level("upgrade.int.legacy"), 2)
	assert_true(progression.state.unlocked_content_ids.has("ability.int.legacy"))
	assert_eq(experience.current_level, 4)
	assert_eq(experience.current_xp, 12)


func test_tc_int_prog_03_analytics_probe_records_runtime_event() -> void:
	_boot_with_database(ResourceDatabase.new())
	var events := ServiceRegistry.get_service("events") as EventRouter
	assert_not_null(events)
	var analytics := ProbeAnalyticsService.new()
	analytics.name = "ProbeAnalyticsService"
	add_child_autofree(analytics)
	ServiceRegistry.unregister_service("analytics")
	ServiceRegistry.register_service("analytics", analytics)
	events.domain_event_emitted.connect(
		func(event: DomainEvent) -> void:
			var service := ServiceRegistry.get_service("analytics") as AnalyticsService
			service.track_event(event.event_type, event.payload)
	)

	events.emit_run_started("run.int.analytics", 7331)
	analytics.set_user_property("profile", "integration")

	assert_eq(analytics.tracked_events.size(), 1)
	assert_eq(analytics.tracked_events[0].get("event_name", ""), "run_started")
	assert_eq(analytics.tracked_events[0]["properties"]["seed"], 7331)
	assert_eq(analytics.user_properties.get("profile", ""), "integration")


func test_tc_int_prog_04_rewarded_ad_completion_grants_revival_or_reward() -> void:
	_boot_with_database(ResourceDatabase.new())
	var ads := ServiceRegistry.get_service("ads") as AdService
	var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
	assert_not_null(ads)
	assert_not_null(progression)
	var entity := _make_health_entity()
	var health := entity.get_node("Components/HealthComponent") as HealthComponent
	health.dead = true
	health.current_hp = 0.0
	ads.rewarded_ad_completed.connect(
		func(placement_id: String) -> void:
			if placement_id == "placement.int.revive":
				health.revive(0.25)
				progression.add_currency("revive_ticket", 1)
	)

	watch_signals(ads)
	assert_true(ads.is_rewarded_ad_ready("placement.int.revive"))
	ads.show_rewarded_ad("placement.int.revive")
	assert_true(await wait_for_signal(ads.rewarded_ad_completed, 1.0, "rewarded ad"))
	assert_signal_emitted_with_parameters(
		ads, "rewarded_ad_completed", ["placement.int.revive"]
	)
	assert_false(health.dead)
	assert_eq(health.current_hp, 25.0)
	assert_eq(progression.get_currency("revive_ticket"), 1)


func test_tc_int_prog_05_iap_purchase_restore_roundtrip() -> void:
	_boot_with_database(ResourceDatabase.new())
	var iap := ServiceRegistry.get_service("iap") as IAPService
	assert_not_null(iap)
	watch_signals(iap)

	var product_ids: Array[String] = ["product.int.starter", "product.int.premium"]
	iap.load_products(product_ids)
	assert_true(await wait_for_signal(iap.products_loaded, 1.0, "load products"))
	assert_signal_emitted(iap, "products_loaded")
	var loaded_params: Array = get_signal_parameters(iap, "products_loaded")
	assert_eq(loaded_params[0], product_ids)

	iap.purchase("product.int.starter")
	assert_true(await wait_for_signal(iap.purchase_completed, 1.0, "purchase"))
	assert_signal_emitted_with_parameters(
		iap, "purchase_completed", ["product.int.starter"]
	)
	assert_true(iap.is_purchased("product.int.starter"))

	iap.restore_purchases()
	assert_true(await wait_for_signal(iap.restore_completed, 1.0, "restore"))
	assert_signal_emitted(iap, "restore_completed")
	var restore_params: Array = get_signal_parameters(iap, "restore_completed")
	var restored_ids: Array = restore_params[0]
	assert_true(restored_ids.has("product.int.starter"))


func test_tc_int_prog_06_cloud_save_roundtrip_dictionary() -> void:
	_boot_with_database(ResourceDatabase.new())
	var cloud := ServiceRegistry.get_service("cloud_save") as CloudSaveService
	assert_not_null(cloud)
	assert_true(cloud.is_available())
	watch_signals(cloud)

	var data := {
		"save_version": 1,
		"profile_id": "profile.int",
		"payload": {
			"progression": {
				"currencies": {
					"crystal": 9,
				},
			},
		},
	}
	cloud.save_to_cloud("slot.int.progression", data)
	data["payload"]["progression"]["currencies"]["crystal"] = 0
	assert_true(await wait_for_signal(cloud.cloud_save_completed, 1.0, "cloud save"))
	assert_signal_emitted_with_parameters(
		cloud, "cloud_save_completed", ["slot.int.progression"]
	)

	cloud.load_from_cloud("slot.int.progression")
	assert_true(await wait_for_signal(cloud.cloud_load_completed, 1.0, "cloud load"))
	assert_signal_emitted(cloud, "cloud_load_completed")
	var load_params: Array = get_signal_parameters(cloud, "cloud_load_completed")
	assert_eq(load_params[0], "slot.int.progression")
	var loaded: Dictionary = load_params[1]
	assert_eq(loaded["payload"]["progression"]["currencies"]["crystal"], 9)


func _boot_with_database(database: ResourceDatabase) -> GameBootstrap:
	var bootstrap := GameBootstrap.new()
	var databases: Array[ResourceDatabase] = [database]
	bootstrap.resource_databases = databases
	add_child_autofree(bootstrap)
	return bootstrap


func _make_progression_database(effect: GameEffect) -> ResourceDatabase:
	var upgrade := UpgradeDefinition.new()
	upgrade.upgrade_id = "upgrade.int.archive"
	upgrade.display_name = "Integration Archive"
	upgrade.currency_id = "crystal"
	upgrade.max_level = 2
	var costs: Array[int] = [30, 60]
	upgrade.cost_by_level = costs
	upgrade.unlock_content_ids = ["ability.int.archive"]
	var effects: Array[GameEffect] = [effect]
	upgrade.effects = effects
	var resources: Array[Resource] = [upgrade]
	return IntTestHelpers.make_resource_database("progression_save_platform_int", resources)


func _make_experience_curve() -> ExperienceCurve:
	var curve := ExperienceCurve.new()
	curve.max_level = 5
	var thresholds: Array[int] = [10, 20, 50, 100]
	curve.xp_thresholds = thresholds
	return curve


func _make_player_with_experience() -> Node:
	var player := IntTestHelpers.make_inventory_entity("Player", "player.int.progression", 3)
	var components := player.get_node("Components") as Node
	var experience := ExperienceComponent.new()
	experience.name = "ExperienceComponent"
	experience.curve = _make_experience_curve()
	components.add_child(experience)
	IntTestHelpers.assign_owner(player, player)
	add_child_autofree(player)
	return player


func _make_health_entity() -> Node:
	var entity := IntTestHelpers.make_health_entity("AdReviveEntity", "entity.int.revive", 1.0)
	add_child_autofree(entity)
	return entity


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	return data
