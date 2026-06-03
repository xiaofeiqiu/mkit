extends GutTest


class StubContent:
	extends ContentRegistry
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class StubSceneRouter:
	extends SceneRouter
	var changed_paths: Array[String] = []
	var auto_emit: bool = false
	var return_value: bool = true

	func change_scene(scene_path: String) -> bool:
		changed_paths.append(scene_path)
		if not return_value:
			scene_change_failed.emit(scene_path, "stub_fail")
			return false
		current_scene_path = scene_path
		if auto_emit:
			scene_changed.emit(scene_path)
		return true


class AudioProbe:
	extends AudioManager
	var played: Array[String] = []

	func play_music(music_id: String, _fade_seconds: float = 0.0) -> void:
		played.append(music_id)


var content: StubContent
var scenes: StubSceneRouter
var events: EventRouter


func before_each() -> void:
	content = StubContent.new()
	scenes = StubSceneRouter.new()
	add_child_autofree(scenes)
	events = EventRouter.new()
	add_child_autofree(events)
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("scenes", scenes)
	ServiceRegistry.register_service("events", events)


func after_each() -> void:
	ServiceRegistry.clear()


# --- helpers ---


func _make_world() -> WorldRouter:
	var world := WorldRouter.new()
	add_child_autofree(world)
	return world


func _make_zone(
	zone_id: String, scene_path: String, default_spawn: String = "default", bgm: String = ""
) -> ZoneDefinition:
	var zone := ZoneDefinition.new()
	zone.zone_id = zone_id
	zone.scene_path = scene_path
	zone.default_spawn_id = default_spawn
	zone.bgm_id = bgm
	content._defs[zone_id] = zone
	return zone


func _make_spawn(spawn_id: String, pos: Vector2) -> SpawnPoint:
	var spawn := SpawnPoint.new()
	spawn.spawn_id = spawn_id
	spawn.position = pos
	add_child_autofree(spawn)
	return spawn


func _make_player(pos: Vector2 = Vector2.ZERO) -> Node2D:
	var player := Node2D.new()
	player.name = "Player"
	player.position = pos
	player.add_to_group("player")
	add_child_autofree(player)
	return player


# --- go_to_zone records scene change + pending spawn (default fallback + failure) ---


func test_tc_world_01_go_to_zone_changes_scene_and_sets_pending_spawn() -> void:
	_make_zone("zone.village", "res://village.tscn", "village_center")
	var world := _make_world()

	assert_true(world.go_to_zone("zone.village", "gate"))
	assert_eq(scenes.changed_paths.size(), 1)
	assert_eq(scenes.changed_paths[0], "res://village.tscn")
	assert_eq(world._pending_zone_id, "zone.village")
	assert_eq(world._pending_spawn_id, "gate")

	assert_true(world.go_to_zone("zone.village"))
	assert_eq(world._pending_spawn_id, "village_center")

	scenes.return_value = false
	assert_false(world.go_to_zone("zone.village", "gate"))
	assert_eq(world._pending_zone_id, "")
	assert_eq(world._pending_spawn_id, "")


# --- placement moves the player to the matching spawn point ---


func test_tc_world_02_player_placed_at_matching_spawn_point() -> void:
	var world := _make_world()
	var player := _make_player(Vector2(5, 5))
	_make_spawn("gate", Vector2(100, 40))
	_make_spawn("center", Vector2(200, 80))

	assert_true(world.place_player_at_spawn("gate"))
	assert_eq(player.global_position, Vector2(100, 40))

	assert_true(world.place_player_at_spawn("center"))
	assert_eq(player.global_position, Vector2(200, 80))

	assert_false(world.place_player_at_spawn("missing"))
	assert_eq(player.global_position, Vector2(200, 80))

	player.remove_from_group("player")
	assert_false(world.place_player_at_spawn("gate"))


# --- finalize emits zone_changed / zone_entered + triggers BGM ---


func test_tc_world_03_zone_changed_event_and_bgm_triggered() -> void:
	var audio := AudioProbe.new()
	add_child_autofree(audio)
	ServiceRegistry.register_service("audio", audio)
	_make_zone("zone.field", "res://field.tscn", "field_entry", "bgm.field")
	scenes.auto_emit = true
	var world := _make_world()
	var player := _make_player(Vector2(1, 1))
	_make_spawn("field_entry", Vector2(300, 90))

	watch_signals(world)
	watch_signals(events)
	assert_true(world.go_to_zone("zone.field", "field_entry"))
	await get_tree().process_frame
	await get_tree().process_frame

	assert_eq(world.current_zone_id, "zone.field")
	assert_eq(player.global_position, Vector2(300, 90))
	assert_signal_emitted_with_parameters(world, "zone_changed", ["", "zone.field"])
	assert_signal_emitted_with_parameters(events, "zone_changed", ["", "zone.field"])
	assert_eq(audio.played.size(), 1)
	assert_eq(audio.played[0], "bgm.field")
	var last := events.recent_events[-1]
	assert_eq(last.event_type, "zone_entered")
	assert_eq(str(last.payload.get("zone_id", "")), "zone.field")
	assert_eq(world.get_current_zone().zone_id, "zone.field")


# --- missing / empty zone fails gracefully, no scene change, no events ---


func test_tc_world_04_missing_zone_definition_fails_gracefully() -> void:
	var world := _make_world()
	watch_signals(world)

	assert_false(world.go_to_zone("zone.unknown", "anywhere"))
	assert_eq(scenes.changed_paths.size(), 0)
	assert_eq(world._pending_zone_id, "")
	assert_eq(world.current_zone_id, "")
	assert_signal_not_emitted(world, "zone_changed")

	assert_false(world.go_to_zone("", "anywhere"))
	assert_eq(scenes.changed_paths.size(), 0)
	assert_null(world.get_current_zone())
