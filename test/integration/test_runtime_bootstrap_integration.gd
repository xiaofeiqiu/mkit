extends GutTest


var _tres_path: String = "res://test/integration/mkit_int_runtime_boot_path_item.tres"
var _save_path: String = "/tmp/mkit_runtime_bootstrap_integration_save.json"


func after_each() -> void:
	IntTestHelpers.remove_file(_tres_path)
	IntTestHelpers.remove_file(_save_path)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_boot_01_boot_registers_all_services() -> void:
	var bootstrap := _boot_with_databases()
	assert_not_null(bootstrap)

	assert_true(ServiceRegistry.get_service("events") is EventRouter)
	assert_true(ServiceRegistry.get_service("content") is ContentRegistry)
	assert_true(ServiceRegistry.get_service("random") is RandomService)
	assert_true(ServiceRegistry.get_service("time") is TimeService)
	assert_true(ServiceRegistry.get_service("actions") is ActionRunner)
	assert_true(ServiceRegistry.get_service("effects") is EffectExecutor)
	assert_true(ServiceRegistry.get_service("commands") is CommandRouter)
	assert_true(ServiceRegistry.get_service("scenes") is SceneRouter)
	assert_true(ServiceRegistry.get_service("pool") is ObjectPool)
	assert_true(ServiceRegistry.get_service("save") is SaveManager)
	assert_true(ServiceRegistry.get_service("progression") is ProgressionSystem)
	assert_true(ServiceRegistry.get_service("analytics") is AnalyticsService)
	assert_true(ServiceRegistry.get_service("ads") is AdService)
	assert_true(ServiceRegistry.get_service("iap") is IAPService)
	assert_true(ServiceRegistry.get_service("cloud_save") is CloudSaveService)
	assert_true(ServiceRegistry.get_service("quest") is QuestSystem)
	assert_true(ServiceRegistry.get_service("shop") is ShopController)
	assert_true(ServiceRegistry.get_service("world") is WorldRouter)
	assert_true(ServiceRegistry.get_service("audio") is AudioManager)

	var events := ServiceRegistry.get_service("events") as EventRouter
	watch_signals(events)
	events.emit_room_cleared("room.int.bootstrap")
	assert_signal_emitted_with_parameters(events, "room_cleared", ["room.int.bootstrap"])
	assert_eq(events.recent_events[-1].event_type, "room_cleared")

	var content := ServiceRegistry.get_service("content") as ContentRegistry
	assert_true(content.validate_all().success)

	var random := ServiceRegistry.get_service("random") as RandomService
	random.set_seed(17)
	assert_true(random.chance(1.0))

	var time := ServiceRegistry.get_service("time") as TimeService
	time.set_gameplay_time_scale(2.0)
	assert_eq(time.advance(0.5), 1.0)

	var actions := ServiceRegistry.get_service("actions") as ActionRunner
	var source := Node.new()
	add_child_autofree(source)
	actions.cancel_actions_for_source(source, "int_boot")
	assert_eq(actions.active_actions.size(), 0)

	var effects := ServiceRegistry.get_service("effects") as EffectExecutor
	var probe := IntTestHelpers.ProbeEffect.new()
	probe.effect_id = "fx.int.boot.probe"
	probe.result_payload = {"probe": true}
	var effect_result := effects.execute(probe, GameplayContext.new())
	assert_true(effect_result.success)
	assert_eq(effects.recent_results.size(), 1)

	var commands := ServiceRegistry.get_service("commands") as CommandRouter
	assert_eq(commands.broadcast(GameCommand.create("INT_BOOT"), []), 0)

	var scenes := ServiceRegistry.get_service("scenes") as SceneRouter
	watch_signals(scenes)
	assert_false(scenes.change_scene(""))
	assert_signal_emitted_with_parameters(scenes, "scene_change_failed", ["", "empty_scene_path"])

	var pool := ServiceRegistry.get_service("pool") as ObjectPool
	pool.clear_pool("res://test/integration/missing_int_pool_scene.tscn")

	var save := ServiceRegistry.get_service("save") as SaveManager
	save.save_path = _save_path
	assert_true(save.save_game(ServiceRegistry))

	var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
	progression.add_currency("gold", 3)
	assert_eq(progression.get_currency("gold"), 3)

	var analytics := ServiceRegistry.get_service("analytics") as AnalyticsService
	analytics.track_event("int_boot", {"service": "analytics"})

	var ads := ServiceRegistry.get_service("ads") as AdService
	assert_true(ads.is_rewarded_ad_ready("placement.int"))

	var iap := ServiceRegistry.get_service("iap") as IAPService
	assert_false(iap.is_purchased("product.int"))

	var cloud_save := ServiceRegistry.get_service("cloud_save") as CloudSaveService
	assert_true(cloud_save.is_available())

	var quest := ServiceRegistry.get_service("quest") as QuestSystem
	assert_null(quest.get_state("quest.int.missing"))

	var shop := ServiceRegistry.get_service("shop") as ShopController
	shop.close_shop()
	assert_null(shop.current_shop)

	var world := ServiceRegistry.get_service("world") as WorldRouter
	assert_eq(world.current_zone_id, "")
	assert_null(world.get_current_zone())


func test_tc_int_boot_02_boot_loads_memory_resource_database_and_validation_passes() -> void:
	var item := IntTestHelpers.make_item_definition("item.int.memory")
	var ability := IntTestHelpers.make_ability_definition("ability.int.memory", "", 0.25)
	var resources: Array[Resource] = [item, ability]
	var databases: Array[ResourceDatabase] = [
		IntTestHelpers.make_resource_database("runtime_memory_int", resources)
	]
	_boot_with_databases(databases)

	var content := ServiceRegistry.get_service("content") as ContentRegistry
	assert_true(content.has("item.int.memory"))
	assert_true(content.has("ability.int.memory"))
	assert_eq(content.get_resource("item.int.memory"), item)
	assert_eq(content.get_resource("ability.int.memory"), ability)
	assert_eq(content.get_all_by_type("item_definition").size(), 1)
	assert_eq(content.get_all_by_type("ability_definition").size(), 1)
	assert_true(content.validate_all().success)


func test_tc_int_boot_03_boot_loads_tres_resource_path_and_validation_passes() -> void:
	var item := IntTestHelpers.make_item_definition("item.int.path")
	assert_eq(ResourceSaver.save(item, _tres_path), OK)
	var resources: Array[Resource] = []
	var resource_paths: Array[String] = [_tres_path]
	var database := IntTestHelpers.make_resource_database(
		"runtime_path_int", resources, resource_paths
	)
	var databases: Array[ResourceDatabase] = [database]
	_boot_with_databases(databases)

	var content := ServiceRegistry.get_service("content") as ContentRegistry
	var loaded := content.get_resource("item.int.path") as ItemDefinition
	assert_not_null(loaded)
	assert_eq(loaded.item_id, "item.int.path")
	assert_eq(loaded.resource_path, _tres_path)
	assert_true(content.has("item.int.path"))
	assert_eq(content.get_all_by_type("item_definition").size(), 1)
	assert_true(content.validate_all().success)


func test_tc_int_boot_04_boot_is_idempotent_when_services_already_registered() -> void:
	var bootstrap := _boot_with_databases()
	var events := ServiceRegistry.get_service("events")
	var actions := ServiceRegistry.get_service("actions")
	var child_count := ServiceRegistry.get_child_count()

	bootstrap.boot()

	assert_eq(ServiceRegistry.get_service("events"), events)
	assert_eq(ServiceRegistry.get_service("actions"), actions)
	assert_eq(ServiceRegistry.get_child_count(), child_count)


func _boot_with_databases(databases: Array[ResourceDatabase] = []) -> GameBootstrap:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = databases
	add_child_autofree(bootstrap)
	return bootstrap
