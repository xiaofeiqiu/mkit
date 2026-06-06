class_name RoomController
extends Node
signal room_entered(room_id: String)
signal room_cleared(room_id: String)
signal reward_ready(options: Array[RewardOption])
@export var room_definition_id: String = ""
@export var enemy_container_path: NodePath = NodePath("../Enemies")
@export var entity_spawner_path: NodePath = NodePath("../EntitySpawner")
@export var reward_count: int = 3
@export var spawn_positions: Array[Vector2] = []
var runtime: RoomRuntime = null
var active_enemies: Dictionary = {}
var content: ContentRegistry = null
var entity_spawner: EntitySpawner = null


func _ready() -> void:
	if ServiceRegistry.has_service("content"):
		content = ServiceRegistry.get_service("content") as ContentRegistry
	entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
	var events: EventRouter = null
	if ServiceRegistry.has_service("events"):
		events = ServiceRegistry.get_service("events") as EventRouter
	if events != null and not events.entity_died.is_connected(_on_entity_died):
		events.entity_died.connect(_on_entity_died)


func setup(definition_id: String) -> void:
	if definition_id.strip_edges() == "":
		push_warning("RoomController.setup: definition_id is empty")
		return
	room_definition_id = definition_id
	runtime = RoomRuntime.create(definition_id)


func enter_room() -> void:
	if runtime == null:
		if room_definition_id.strip_edges() == "":
			push_warning("RoomController.enter_room: missing runtime and room_definition_id")
			return
		runtime = RoomRuntime.create(room_definition_id)
	runtime.entered = true
	spawn_enemies()
	room_entered.emit(runtime.room_runtime_id)


func spawn_enemies() -> void:
	if runtime == null:
		push_error("RoomController.spawn_enemies: runtime is null")
		return
	var def := get_definition()
	if def == null:
		return
	var parent := get_node_or_null(enemy_container_path)
	if parent == null:
		push_error("RoomController: missing enemy container at %s" % enemy_container_path)
		return
	var spawner := _get_entity_spawner()
	if spawner == null:
		push_error("RoomController: missing EntitySpawner at %s" % entity_spawner_path)
		return
	var spawn_index := 0
	for enemy_def_id in def.enemy_spawn_ids:
		var pos := Vector2.ZERO
		if spawn_index < spawn_positions.size():
			pos = spawn_positions[spawn_index]
		var enemy := spawner.spawn_entity(enemy_def_id, parent, pos)
		if enemy == null:
			spawn_index += 1
			continue
		var entity_id := _get_entity_id(enemy)
		active_enemies[entity_id] = enemy
		runtime.active_enemy_ids.append(entity_id)
		spawn_index += 1


func check_clear_condition() -> void:
	if runtime == null or runtime.cleared:
		return
	if active_enemies.is_empty():
		runtime.cleared = true
		generate_reward()
		room_cleared.emit(runtime.room_runtime_id)
		var events: EventRouter = null
		if ServiceRegistry.has_service("events"):
			events = ServiceRegistry.get_service("events") as EventRouter
		if events != null:
			events.emit_room_cleared(runtime.room_runtime_id)


func generate_reward() -> void:
	if runtime == null:
		reward_ready.emit([])
		return
	if reward_count <= 0:
		runtime.reward_options = []
		reward_ready.emit([])
		return
	var def := get_definition()
	if def == null or def.reward_pool_ids.is_empty():
		reward_ready.emit([])
		return
	var reward_system := RewardSystem.new()
	var ctx := GameplayContext.new()
	ctx.room_id = runtime.room_runtime_id
	var options := reward_system.generate_options(def.reward_pool_ids, reward_count, ctx)
	runtime.reward_options = options
	reward_ready.emit(options)


func get_definition() -> RoomDefinition:
	if room_definition_id.strip_edges() == "":
		return null
	if content == null:
		if ServiceRegistry.has_service("content"):
			content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(room_definition_id) as RoomDefinition


func _on_entity_died(entity_id: String, _entity_ref: Node) -> void:
	if runtime == null:
		return
	if not active_enemies.has(entity_id):
		return
	active_enemies.erase(entity_id)
	runtime.active_enemy_ids.erase(entity_id)
	check_clear_condition()


func _get_entity_spawner() -> EntitySpawner:
	if entity_spawner != null:
		return entity_spawner
	entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
	return entity_spawner


func _get_entity_id(entity: Node) -> String:
	if entity == null:
		return ""
	var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
	return identity.entity_id if identity != null else entity.name
