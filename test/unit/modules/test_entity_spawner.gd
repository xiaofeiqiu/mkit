extends GutTest


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

# TC-ES-06 through TC-ES-10 require a real PackedScene on disk — integration only, skipped here.
