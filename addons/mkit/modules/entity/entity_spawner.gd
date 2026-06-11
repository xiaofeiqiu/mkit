class_name EntitySpawner
extends Node
## 说明：`EntitySpawner` 是 实体系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在实体系统中复用这段契约或状态时使用它。
## 示例：`var instance := EntitySpawner.new()`

## 当 `EntitySpawner` 发生 `entity spawned` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal entity_spawned(entity: Node, definition_id: String)
## 当 `EntitySpawner` 发生 `entity spawn failed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal entity_spawn_failed(definition_id: String, reason: String)
## 运行时状态：`content` 表示 `EntitySpawner` 的字段值，由 `EntitySpawner` 的公开 API 读取或维护。
var content: ContentService = null


func _ready() -> void:
	content = Mkit.content()


## 执行 `spawn_entity` 对应的公开操作，并保持 `EntitySpawner` 的领域契约一致。
func spawn_entity(
	definition_id: String, parent: Node, position: Vector2 = Vector2.ZERO, runtime_id: String = ""
) -> Node:
	if definition_id.strip_edges() == "":
		entity_spawn_failed.emit(definition_id, "empty_definition_id")
		return null
	if parent == null:
		entity_spawn_failed.emit(definition_id, "missing_parent")
		return null
	var definition := _get_definition(definition_id)
	if definition == null:
		entity_spawn_failed.emit(definition_id, "missing_definition")
		return null
	if definition.scene_path == "":
		entity_spawn_failed.emit(definition_id, "missing_scene_path")
		return null
	var scene := load(definition.scene_path) as PackedScene
	if scene == null:
		entity_spawn_failed.emit(definition_id, "cannot_load_scene")
		return null
	var entity := scene.instantiate()
	if entity == null:
		entity_spawn_failed.emit(definition_id, "cannot_instantiate_scene")
		return null
	_initialize_identity(entity, definition, runtime_id)
	_initialize_command_receiver(entity)
	_initialize_stats(entity, definition)
	parent.add_child(entity)
	if entity is Node2D:
		(entity as Node2D).global_position = position
	_initialize_abilities(entity, definition)
	entity_spawned.emit(entity, definition_id)
	return entity


func _get_definition(definition_id: String) -> EntityDefinition:
	if definition_id.strip_edges() == "":
		return null
	if content == null:
		content = Mkit.content()
	if content == null:
		return null
	return content.get_resource(definition_id) as EntityDefinition


func _initialize_identity(entity: Node, definition: EntityDefinition, runtime_id: String) -> void:
	if entity == null or definition == null:
		return
	var identity := EntityContract.get_identity(entity)
	if identity == null:
		return
	identity.definition_id = definition.entity_definition_id
	identity.display_name = definition.display_name
	identity.faction = definition.default_faction
	identity.tags = definition.tags.duplicate()
	if runtime_id != "":
		identity.entity_id = runtime_id
	else:
		identity.entity_id = (
			"%s_%d" % [definition.entity_definition_id.replace(".", "_"), Time.get_ticks_usec()]
		)


func _initialize_command_receiver(entity: Node) -> void:
	if entity == null:
		return
	var identity := EntityContract.get_identity(entity)
	if identity == null or identity.entity_id == "":
		return
	var receiver := EntityContract.get_command_receiver(entity)
	if receiver == null:
		return
	receiver.configure_receiver_id(identity.entity_id)


func _initialize_stats(entity: Node, definition: EntityDefinition) -> void:
	if entity == null or definition == null:
		return
	var stats := EntityContract.get_component(entity, "StatsComponent") as StatsComponent
	if stats == null:
		return
	for stat_id in definition.base_stats.keys():
		stats.set_base_stat(str(stat_id), float(definition.base_stats[stat_id]))
	stats.mark_save_baseline()


func _initialize_abilities(entity: Node, definition: EntityDefinition) -> void:
	if entity == null or definition == null:
		return
	var ability_ids: Array[String] = []
	for ability_id in definition.starting_ability_ids:
		var id := str(ability_id).strip_edges()
		if id != "":
			ability_ids.append(id)
	if ability_ids.is_empty():
		return
	var abilities := EntityContract.get_controller(entity, "AbilityController") as AbilityController
	if abilities == null:
		return
	for ability_id in ability_ids:
		abilities.register_ability(ability_id)
