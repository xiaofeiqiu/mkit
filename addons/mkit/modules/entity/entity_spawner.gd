class_name EntitySpawner
extends Node

signal entity_spawned(entity: Node, definition_id: String)
signal entity_spawn_failed(definition_id: String, reason: String)

var content: ContentRegistry = null

func _ready() -> void:
	content = ServiceRegistry.get_service("content") as ContentRegistry

func spawn_entity(definition_id: String, parent: Node, position: Vector2 = Vector2.ZERO, runtime_id: String = "") -> Node:
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
	parent.add_child(entity)
	if entity is Node2D:
		(entity as Node2D).global_position = position

	_initialize_identity(entity, definition, runtime_id)
	_initialize_stats(entity, definition)
	_initialize_abilities(entity, definition)

	entity_spawned.emit(entity, definition_id)
	return entity

func _get_definition(definition_id: String) -> EntityDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(definition_id) as EntityDefinition

func _initialize_identity(entity: Node, definition: EntityDefinition, runtime_id: String) -> void:
	var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
	if identity == null:
		return
	identity.definition_id = definition.entity_definition_id
	identity.display_name = definition.display_name
	identity.faction = definition.default_faction
	identity.tags = definition.tags.duplicate()
	# Always assign a unique runtime id so multiple spawned instances don't share the same entity_id.
	if runtime_id != "":
		identity.entity_id = runtime_id
	else:
		identity.entity_id = "%s_%d" % [definition.entity_definition_id.replace(".", "_"), Time.get_ticks_usec()]

func _initialize_stats(entity: Node, definition: EntityDefinition) -> void:
	var stats := entity.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats == null:
		return
	for stat_id in definition.base_stats.keys():
		stats.set_base_stat(str(stat_id), float(definition.base_stats[stat_id]))

func _initialize_abilities(entity: Node, definition: EntityDefinition) -> void:
	var abilities := entity.get_node_or_null("Controllers/AbilityController") as AbilityController
	if abilities == null:
		return
	for ability_id in definition.starting_ability_ids:
		abilities.register_ability(ability_id)
