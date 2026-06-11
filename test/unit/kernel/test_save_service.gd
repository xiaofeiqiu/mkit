extends GutTest


class ProbeSaveable:
	extends Saveable
	var value: int = 0

	func to_save_data() -> Dictionary:
		return {"value": value}

	func from_save_data(data: Dictionary) -> void:
		value = int(data.get("value", value))


class ProbeComponent:
	extends SaveableComponent
	var value: int = 0

	func to_save_data() -> Dictionary:
		return {"value": value}

	func from_save_data(data: Dictionary) -> void:
		value = int(data.get("value", value))


class DuplicateKeyComponent:
	extends SaveableComponent
	var value: int = 0

	func get_save_key() -> String:
		return "duplicate"

	func to_save_data() -> Dictionary:
		return {"value": value}

	func from_save_data(data: Dictionary) -> void:
		value = int(data.get("value", value))


class DuckComponent:
	extends Node
	var value: int = 0

	func get_save_key() -> String:
		return name

	func to_save_data() -> Dictionary:
		return {"value": value}

	func from_save_data(data: Dictionary) -> void:
		value = int(data.get("value", value))


class OrderedSaveable:
	extends Saveable
	var log: Array = []

	func from_save_data(_data: Dictionary) -> void:
		log.append("root")


class OrderedComponent:
	extends SaveableComponent
	var log: Array = []

	func from_save_data(_data: Dictionary) -> void:
		log.append("component")


var _save_path := "/tmp/mkit_unit_save_service_entities.json"


func after_each() -> void:
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)
	if FileAccess.file_exists("%s.tmp" % _save_path):
		DirAccess.remove_absolute("%s.tmp" % _save_path)
	for child in ServiceRegistry.get_children():
		ServiceRegistry.remove_child(child)
		child.free()
	ServiceRegistry.clear()


func test_tc_save_01_writes_roots_entities_and_roundtrips_components() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	var root_save := ProbeSaveable.new()
	root_save.name = "RootSave"
	root_save.save_id = "root.probe"
	root_save.value = 7
	scene.add_child(root_save)
	var parts := _add_entity(scene, "player")
	var component := parts["component"] as ProbeComponent
	var duck := parts["duck"] as DuckComponent
	component.value = 11
	duck.value = 12
	var save := _make_save_service()
	save.profile_id = "profile.unit"

	assert_true(save.save_game(scene))
	var data := _read_json(_save_path)
	assert_eq(int(data.get("schema_version", 0)), 2)
	assert_eq(str(data.get("profile_id", "")), "profile.unit")
	assert_true(data.has("roots"))
	assert_true(data.has("entities"))
	assert_true(data.has("scopes"))
	assert_false(data.has("payload"))
	assert_false(data.has("scope_manifest"))
	assert_false(data.has("save_scopes"))
	var roots: Dictionary = data["roots"]
	var entities: Dictionary = data["entities"]
	assert_eq(int(roots["root.probe"]["value"]), 7)
	assert_true(entities.has("player"))
	var player_record: Dictionary = entities["player"]
	assert_eq(player_record["scene_path"], "res://game/entities/player.tscn")
	assert_eq(player_record["zone_id"], "village")
	var components: Dictionary = player_record["components"]
	assert_eq(int(components["ProbeComponent"]["value"]), 11)
	assert_eq(int(components["DuckComponent"]["value"]), 12)

	root_save.value = 0
	component.value = 0
	duck.value = 0
	assert_true(save.load_game(scene))
	assert_eq(root_save.value, 7)
	assert_eq(component.value, 11)
	assert_eq(duck.value, 12)


func test_tc_save_02_duplicate_root_ids_fail_save() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	var first := ProbeSaveable.new()
	first.save_id = "duplicate.root"
	scene.add_child(first)
	var second := ProbeSaveable.new()
	second.save_id = "duplicate.root"
	scene.add_child(second)
	var save := _make_save_service()

	assert_false(save.save_game(scene))
	assert_push_error("Duplicate root save id")


func test_tc_save_03_duplicate_entity_ids_fail_save() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	_add_entity(scene, "duplicate.entity")
	_add_entity(scene, "duplicate.entity")
	var save := _make_save_service()

	assert_false(save.save_game(scene))
	assert_push_error("Duplicate entity save id")


func test_tc_save_04_duplicate_component_keys_fail_save() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	var entity := Node2D.new()
	entity.name = "DuplicateComponentEntity"
	scene.add_child(entity)
	var first := DuplicateKeyComponent.new()
	first.name = "FirstDuplicate"
	entity.add_child(first)
	var second := DuplicateKeyComponent.new()
	second.name = "SecondDuplicate"
	entity.add_child(second)
	var agent := EntitySaveAgent.new()
	agent.entity_id = "entity.duplicate_component"
	entity.add_child(agent)
	var save := _make_save_service()

	assert_false(save.save_game(scene))
	assert_push_error("duplicate component save key")


func test_tc_save_05_legacy_payload_only_save_is_rejected() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	var parts := _add_entity(scene, "player")
	var component := parts["component"] as ProbeComponent
	var duck := parts["duck"] as DuckComponent
	component.value = 0
	duck.value = 0
	_write_json(
		_save_path,
		{
			"schema_version": 2,
			"save_version": 1,
			"payload": {
				"player": {
					"ProbeComponent": {"value": 31},
					"DuckComponent": {"value": 32},
				},
			},
		}
	)
	var save := _make_save_service()
	watch_signals(save)

	assert_false(save.load_game(scene))
	assert_signal_emitted_with_parameters(
		save, "load_failed", [_save_path, "Save file contains legacy field: payload"]
	)
	assert_eq(component.value, 0)
	assert_eq(duck.value, 0)


func test_tc_save_06_load_restores_roots_before_entities() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	var log: Array = []
	var root_save := OrderedSaveable.new()
	root_save.save_id = "world"
	root_save.restore_order = -100
	root_save.log = log
	scene.add_child(root_save)
	var entity := Node2D.new()
	entity.name = "OrderedEntity"
	scene.add_child(entity)
	var component := OrderedComponent.new()
	component.name = "OrderedComponent"
	component.log = log
	entity.add_child(component)
	var agent := EntitySaveAgent.new()
	agent.entity_id = "entity.ordered"
	agent.restore_order = 100
	entity.add_child(agent)
	_write_json(
		_save_path,
		{
			"schema_version": 2,
			"roots": {"world": {}},
			"entities": {
				"entity.ordered": {
					"components": {"OrderedComponent": {}},
				},
			},
			"scopes": {},
		}
	)
	var save := _make_save_service()

	assert_true(save.load_game(scene))
	assert_eq(log, ["root", "component"])


func test_tc_save_07_skips_replaced_service_registry_children() -> void:
	var stale := ProbeSaveable.new()
	stale.name = "StaleAudio"
	stale.save_id = "audio"
	stale.value = 1
	ServiceRegistry.add_child(stale)
	var active := ProbeSaveable.new()
	active.name = "ActiveAudio"
	active.save_id = "audio"
	active.value = 2
	add_child_autofree(active)
	ServiceRegistry.register_service(AudioService.SERVICE_ID, active)
	var save := _make_save_service()

	assert_true(save.save_game(get_tree().root))
	var data := _read_json(_save_path)
	var roots: Dictionary = data["roots"]
	assert_eq(int(roots["audio"]["value"]), 2)


func test_tc_save_08_migrates_schema_v1_current_shape() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	var root_save := ProbeSaveable.new()
	root_save.name = "RootSave"
	root_save.save_id = "root.probe"
	root_save.value = 0
	scene.add_child(root_save)
	_write_json(
		_save_path,
		{
			"schema_version": 1,
			"roots": {"root.probe": {"value": 41}},
		}
	)
	var save := _make_save_service()

	assert_true(save.load_game(scene))
	assert_eq(root_save.value, 41)


func test_tc_save_09_overwrites_existing_save_through_tmp_path() -> void:
	var scene := Node.new()
	add_child_autofree(scene)
	var root_save := ProbeSaveable.new()
	root_save.name = "RootSave"
	root_save.save_id = "root.probe"
	root_save.value = 9
	scene.add_child(root_save)
	_write_json(_save_path, {"schema_version": 2, "roots": {"old": {}}, "entities": {}, "scopes": {}})
	var save := _make_save_service()
	save.profile_id = "profile.replace"

	assert_true(save.save_game(scene))
	assert_false(FileAccess.file_exists("%s.tmp" % _save_path))
	var data := _read_json(_save_path)
	assert_eq(str(data.get("profile_id", "")), "profile.replace")
	var roots: Dictionary = data["roots"]
	assert_true(roots.has("root.probe"))
	assert_false(roots.has("old"))


func _add_entity(scene: Node, entity_id: String) -> Dictionary:
	var entity := Node2D.new()
	entity.name = "Entity_%s" % entity_id.replace(".", "_")
	scene.add_child(entity)
	var components := Node.new()
	components.name = "Components"
	entity.add_child(components)
	var component := ProbeComponent.new()
	component.name = "ProbeComponent"
	components.add_child(component)
	var duck := DuckComponent.new()
	duck.name = "DuckComponent"
	duck.add_to_group(EntitySaveAgent.ENTITY_SAVE_PARTICIPANT_GROUP)
	components.add_child(duck)
	var agent := EntitySaveAgent.new()
	agent.entity_id = entity_id
	agent.scene_path = "res://game/entities/player.tscn"
	agent.zone_id = "village"
	entity.add_child(agent)
	return {
		"entity": entity,
		"component": component,
		"duck": duck,
		"agent": agent,
	}


func _make_save_service() -> SaveService:
	var save := SaveService.new()
	save.save_path = _save_path
	add_child_autofree(save)
	return save


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
