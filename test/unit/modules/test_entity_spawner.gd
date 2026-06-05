extends GutTest


const STATS_SCENE_PATH := "res://test/unit/modules/tmp_entity_spawner_stats_probe.tscn"


class StubContent:
	extends ContentRegistry
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


func _make_def(id: String, scene: String = "") -> EntityDefinition:
	var d := EntityDefinition.new()
	d.entity_definition_id = id
	d.scene_path = scene
	d.base_stats = {}
	d.starting_ability_ids = []
	d.tags = []
	d.default_faction = "neutral"
	return d


var spawner: EntitySpawner
var content: StubContent
var parent_node: Node


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	ServiceRegistry.register_service("content", content)
	spawner = EntitySpawner.new()
	add_child_autofree(spawner)
	spawner._ready()
	parent_node = Node.new()
	add_child_autofree(parent_node)


func after_each() -> void:
	_remove_file(STATS_SCENE_PATH)
	_remove_file("%s.uid" % STATS_SCENE_PATH)
	ServiceRegistry.clear()


# --- spawn_entity failure paths ---


func test_tc_es_01_empty_definition_id_emits_spawn_failed() -> void:
	watch_signals(spawner)
	var result := spawner.spawn_entity("", parent_node)
	assert_null(result)
	assert_signal_emitted_with_parameters(
		spawner, "entity_spawn_failed", ["", "empty_definition_id"]
	)


func test_tc_es_02_null_parent_emits_spawn_failed() -> void:
	content._defs["slime"] = _make_def("slime")
	watch_signals(spawner)
	var result := spawner.spawn_entity("slime", null)
	assert_null(result)
	assert_signal_emitted_with_parameters(
		spawner, "entity_spawn_failed", ["slime", "missing_parent"]
	)


func test_tc_es_03_missing_definition_emits_spawn_failed() -> void:
	watch_signals(spawner)
	var result := spawner.spawn_entity("ghost", parent_node)
	assert_null(result)
	assert_signal_emitted_with_parameters(
		spawner, "entity_spawn_failed", ["ghost", "missing_definition"]
	)


func test_tc_es_04_empty_scene_path_emits_spawn_failed() -> void:
	content._defs["hollow"] = _make_def("hollow", "")
	watch_signals(spawner)
	var result := spawner.spawn_entity("hollow", parent_node)
	assert_null(result)
	assert_signal_emitted_with_parameters(
		spawner, "entity_spawn_failed", ["hollow", "missing_scene_path"]
	)


func test_tc_es_05_missing_content_service_emits_spawn_failed() -> void:
	ServiceRegistry.unregister_service("content")
	watch_signals(spawner)
	var result := spawner.spawn_entity("anything", parent_node)
	assert_null(result)
	assert_signal_emitted(spawner, "entity_spawn_failed")


func test_tc_es_06_spawned_definition_base_stats_are_save_baseline() -> void:
	_save_stats_scene()
	var definition := _make_def("stat_entity", STATS_SCENE_PATH)
	definition.base_stats = {"max_hp": 44.0, "attack_power": 12.0}
	content._defs["stat_entity"] = definition
	var entity := spawner.spawn_entity("stat_entity", parent_node)
	assert_not_null(entity)
	var stats := entity.get_node("Components/StatsComponent") as StatsComponent
	assert_eq(stats.get_stat_value("max_hp"), 44.0)
	assert_eq(stats.get_stat_value("attack_power"), 12.0)
	var data := stats.to_save_data()
	assert_true((data["base_overrides"] as Dictionary).is_empty())


func _save_stats_scene() -> void:
	var entity := Node.new()
	entity.name = "StatsEntity"
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	entity.add_child(identity)
	var components := Node.new()
	components.name = "Components"
	entity.add_child(components)
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	components.add_child(stats)
	_assign_owner(entity, entity)
	var scene := PackedScene.new()
	assert_eq(scene.pack(entity), OK)
	assert_eq(ResourceSaver.save(scene, STATS_SCENE_PATH), OK)
	entity.free()


func _assign_owner(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_assign_owner(child, owner_node)


func _remove_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
