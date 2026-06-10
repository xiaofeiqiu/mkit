extends GutTest


var _tres_path: String = "res://test/integration/mkit_int_runtime_boot_path_item.tres"
var _save_path: String = "/tmp/mkit_runtime_bootstrap_integration_save.json"
var _master_bus_index: int = -1
var _master_original_db: float = 0.0
var _master_volume_captured: bool = false


class EntityDuckComponent:
	extends Node
	var value: int = 0

	func get_save_key() -> String:
		return name

	func to_save_data() -> Dictionary:
		return {"value": value}

	func from_save_data(data: Dictionary) -> void:
		value = int(data.get("value", value))


func after_each() -> void:
	if _master_volume_captured and _master_bus_index >= 0:
		AudioServer.set_bus_volume_db(_master_bus_index, _master_original_db)
	_master_volume_captured = false
	IntTestHelpers.remove_file(_tres_path)
	IntTestHelpers.remove_file(_save_path)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_boot_01_boot_registers_all_services() -> void:
	var bootstrap := _boot_with_databases()
	assert_not_null(bootstrap)

	assert_true(ServiceRegistry.get_service("events") is EventService)
	assert_true(ServiceRegistry.get_service("content") is ContentService)
	assert_true(ServiceRegistry.get_service("random") is RandomService)
	assert_true(ServiceRegistry.get_service("time") is TimeService)
	assert_true(ServiceRegistry.get_service("actions") is ActionService)
	assert_true(ServiceRegistry.get_service("effects") is EffectService)
	assert_true(ServiceRegistry.get_service("commands") is CommandService)
	assert_true(ServiceRegistry.get_service("scenes") is SceneService)
	assert_true(ServiceRegistry.get_service("pool") is PoolService)
	assert_true(ServiceRegistry.get_service("save") is SaveService)
	assert_true(ServiceRegistry.get_service("progression") is ProgressionService)
	assert_true(ServiceRegistry.get_service("analytics") is AnalyticsService)
	assert_true(ServiceRegistry.get_service("ads") is AdService)
	assert_true(ServiceRegistry.get_service("iap") is IAPService)
	assert_true(ServiceRegistry.get_service("cloud_save") is CloudSaveService)
	assert_true(ServiceRegistry.get_service("quest") is QuestService)
	assert_true(ServiceRegistry.get_service("shop") is ShopService)
	assert_true(ServiceRegistry.get_service("dialogue") is DialogueService)
	assert_true(ServiceRegistry.get_service("world") is WorldService)
	assert_true(ServiceRegistry.get_service("audio") is AudioService)

	var events := ServiceRegistry.get_service("events") as EventService
	watch_signals(events)
	events.emit_domain_event(WorldEvents.room_cleared("room.int.bootstrap"))
	var evt_room_cleared_1 := DomainEventAsserts.last_event(events, "room_cleared")
	assert_not_null(evt_room_cleared_1)
	assert_eq(evt_room_cleared_1.source_id, "room.int.bootstrap")
	assert_eq(events.recent_events[-1].event_type, "room_cleared")

	var content := ServiceRegistry.get_service("content") as ContentService
	assert_true(content.validate_all().success)

	var random := ServiceRegistry.get_service("random") as RandomService
	random.set_seed(17)
	assert_true(random.chance(1.0))

	var time := ServiceRegistry.get_service("time") as TimeService
	time.set_gameplay_time_scale(2.0)
	assert_eq(time.advance(0.5), 1.0)

	var actions := ServiceRegistry.get_service("actions") as ActionService
	var source := Node.new()
	add_child_autofree(source)
	actions.cancel_actions_for_source(source, "int_boot")
	assert_eq(actions.active_actions.size(), 0)

	var effects := ServiceRegistry.get_service("effects") as EffectService
	var probe := IntTestHelpers.ProbeEffect.new()
	probe.effect_id = "fx.int.boot.probe"
	probe.result_payload = {"probe": true}
	var effect_result := effects.execute(probe, GameplayContext.new())
	assert_true(effect_result.success)
	assert_eq(effects.recent_results.size(), 1)

	var commands := ServiceRegistry.get_service("commands") as CommandService
	assert_eq(commands.broadcast(GameCommand.create("INT_BOOT"), []), 0)

	var scenes := ServiceRegistry.get_service("scenes") as SceneService
	watch_signals(scenes)
	assert_false(scenes.change_scene(""))
	assert_signal_emitted_with_parameters(scenes, "scene_change_failed", ["", "empty_scene_path"])

	var pool := ServiceRegistry.get_service("pool") as PoolService
	pool.clear_pool("res://test/integration/missing_int_pool_scene.tscn")

	var save := ServiceRegistry.get_service("save") as SaveService
	save.save_path = _save_path
	assert_true(save.save_game(ServiceRegistry))

	var progression := ServiceRegistry.get_service("progression") as ProgressionService
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

	var quest := ServiceRegistry.get_service("quest") as QuestService
	assert_null(quest.get_state("quest.int.missing"))

	var shop := ServiceRegistry.get_service("shop") as ShopService
	shop.close_shop()
	assert_null(shop.current_shop)

	var dialogue := ServiceRegistry.get_service("dialogue") as DialogueService
	assert_false(dialogue.start("", GameplayContext.new()))
	assert_false(dialogue.is_active())

	var world := ServiceRegistry.get_service("world") as WorldService
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

	var content := ServiceRegistry.get_service("content") as ContentService
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

	var content := ServiceRegistry.get_service("content") as ContentService
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


func test_tc_int_boot_05_audio_bus_volume_saves_and_loads_through_bootstrap() -> void:
	_boot_with_databases()
	_capture_master_volume()
	var audio := ServiceRegistry.get_service("audio") as AudioService
	var save := ServiceRegistry.get_service("save") as SaveService
	assert_not_null(audio)
	assert_not_null(save)
	save.save_path = _save_path

	assert_true(audio.set_bus_volume("Master", -6.0))
	watch_signals(save)
	assert_true(save.save_game(ServiceRegistry))
	assert_signal_emitted_with_parameters(save, "save_completed", [_save_path])

	assert_true(audio.set_bus_volume("Master", -2.0))
	assert_almost_eq(audio.get_bus_volume("Master"), -2.0, 0.001)

	assert_true(save.load_game(ServiceRegistry))
	assert_signal_emitted_with_parameters(save, "load_completed", [_save_path])
	assert_almost_eq(audio.get_bus_volume("Master"), -6.0, 0.001)
	assert_almost_eq(AudioServer.get_bus_volume_db(_master_bus_index), -6.0, 0.001)


func test_tc_int_boot_06_configured_save_path_loads_profile() -> void:
	var writer_progression := ProgressionService.new()
	writer_progression.save_id = "progression"
	add_child_autofree(writer_progression)
	writer_progression.add_currency("gold", 11)
	var writer_save := SaveService.new()
	writer_save.save_path = _save_path
	assert_true(writer_save.save_game(self))
	writer_save.free()
	remove_child(writer_progression)
	writer_progression.queue_free()
	await get_tree().process_frame

	_boot_with_databases([], _save_path)

	var save := ServiceRegistry.get_service("save") as SaveService
	var progression := ServiceRegistry.get_service("progression") as ProgressionService
	assert_not_null(save)
	assert_not_null(progression)
	assert_eq(save.save_path, _save_path)
	assert_eq(progression.get_currency("gold"), 11)


func test_tc_int_boot_07_boot_registers_audio_definitions_from_content() -> void:
	var sfx_stream := AudioStreamGenerator.new()
	var sfx := AudioDefinition.new()
	sfx.audio_id = "sfx.int.boot"
	sfx.stream = sfx_stream
	var music_stream := _make_wav_stream(96)
	var music := AudioDefinition.new()
	music.audio_id = "music.int.boot"
	music.stream = music_stream
	music.kind = AudioDefinition.AudioKind.MUSIC
	music.loop = true
	var resources: Array[Resource] = [sfx, music]
	var database := IntTestHelpers.make_resource_database("runtime_audio_int", resources)

	_boot_with_databases([database])

	var audio := ServiceRegistry.get_service("audio") as AudioService
	assert_not_null(audio)
	assert_eq(audio.sfx_map["sfx.int.boot"], sfx_stream)
	assert_eq(audio.music_map["music.int.boot"], music_stream)
	assert_eq(music_stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(music_stream.loop_begin, 0)
	assert_gt(music_stream.loop_end, 0)


func test_tc_int_boot_08_save_service_roots_entities_roundtrip() -> void:
	_boot_with_databases()
	var save := ServiceRegistry.get_service("save") as SaveService
	var progression := ServiceRegistry.get_service("progression") as ProgressionService
	assert_not_null(save)
	assert_not_null(progression)
	save.save_path = _save_path

	var entity := IntTestHelpers.make_health_entity("SaveEntity", "entity.int.save", 50.0)
	add_child_autofree(entity)
	var health := entity.get_node("Components/HealthComponent") as HealthComponent
	var duck := EntityDuckComponent.new()
	duck.name = "RuntimeDuck"
	duck.value = 17
	duck.add_to_group(EntitySaveAgent.ENTITY_SAVE_PARTICIPANT_GROUP)
	entity.get_node("Components").add_child(duck)
	var agent := EntitySaveAgent.new()
	agent.entity_id = "entity.int.save"
	agent.scene_path = "res://game/entities/save_entity.tscn"
	agent.zone_id = "zone.int.save"
	entity.add_child(agent)

	progression.add_currency("gold", 19)
	assert_true(save.save_game(get_tree().root))
	var saved: Dictionary = _read_json(_save_path)
	assert_eq(int(saved.get("schema_version", 0)), 2)
	var roots: Dictionary = saved.get("roots", {})
	var entities: Dictionary = saved.get("entities", {})
	assert_true(roots.has("progression"))
	assert_true(entities.has("entity.int.save"))
	var record: Dictionary = entities["entity.int.save"]
	assert_eq(record["scene_path"], "res://game/entities/save_entity.tscn")
	assert_eq(record["zone_id"], "zone.int.save")
	var components: Dictionary = record["components"]
	assert_true(components.has("HealthComponent"))
	assert_true(components.has("StatsComponent"))
	assert_eq(int(components["RuntimeDuck"]["value"]), 17)

	progression.state = ProgressionState.new()
	health.current_hp = 1.0
	duck.value = 0
	assert_true(save.load_game(get_tree().root))
	assert_eq(progression.get_currency("gold"), 19)
	assert_eq(health.current_hp, 50.0)
	assert_eq(duck.value, 17)


func _boot_with_databases(
	databases: Array[ResourceDatabase] = [], profile_save_path: String = ""
) -> ModuleBootstrap:
	var bootstrap := ModuleBootstrap.new()
	bootstrap.resource_databases = databases
	bootstrap.save_path = profile_save_path if profile_save_path != "" else _save_path
	add_child_autofree(bootstrap)
	return bootstrap


func _capture_master_volume() -> void:
	_master_bus_index = AudioServer.get_bus_index("Master")
	if _master_bus_index >= 0:
		_master_original_db = AudioServer.get_bus_volume_db(_master_bus_index)
		_master_volume_captured = true


func _make_wav_stream(sample_count: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	stream.data = data
	return stream


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
