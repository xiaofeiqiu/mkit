class_name RoomController
extends Node

## Purpose: Emits the `room_entered` signal to notify external listeners of a state change.
## Example: `self.room_entered.connect(_on_room_entered)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal room_entered(room_id: String)
## Purpose: Emits the `room_cleared` signal to notify external listeners of a state change.
## Example: `self.room_cleared.connect(_on_room_cleared)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal room_cleared(room_id: String)
## Purpose: Emits the `reward_ready` signal to notify external listeners of a state change.
## Example: `self.reward_ready.connect(_on_reward_ready)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal reward_ready(options: Array[RewardOption])

## Purpose: Inspector-exposed configuration `room_definition_id`.
## Example: `self.room_definition_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var room_definition_id: String = ""
## Purpose: Inspector-exposed configuration `enemy_container_path`.
## Example: `self.enemy_container_path = NodePath(".")`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var enemy_container_path: NodePath = NodePath("../Enemies")
## Purpose: Inspector-exposed configuration `entity_spawner_path`.
## Example: `self.entity_spawner_path = NodePath(".")`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var entity_spawner_path: NodePath = NodePath("../EntitySpawner")
## Purpose: Inspector-exposed configuration `reward_count`.
## Example: `self.reward_count = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var reward_count: int = 3
## Purpose: Inspector-exposed configuration `spawn_positions`.
## Example: `self.spawn_positions = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var spawn_positions: Array[Vector2] = []

## Purpose: Public runtime field `runtime`.
## Example: `self.runtime = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var runtime: RoomRuntime = null
## Purpose: Public runtime field `active_enemies`.
## Example: `self.active_enemies = {}`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var active_enemies: Dictionary = {}
## Purpose: Public runtime field `content`.
## Example: `self.content = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var content: ContentRegistry = null
## Purpose: Public runtime field `entity_spawner`.
## Example: `self.entity_spawner = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var entity_spawner: EntitySpawner = null

func _ready() -> void:
	content = ServiceRegistry.get_service("content") as ContentRegistry
	entity_spawner = get_node_or_null(entity_spawner_path) as EntitySpawner
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.entity_died.connect(_on_entity_died)

## Purpose: Public method `setup` for external gameplay integration.
## Example: `self.setup(<definition_id>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func setup(definition_id: String) -> void:
	room_definition_id = definition_id
	runtime = RoomRuntime.create(definition_id)

## Purpose: Public method `enter_room` for external gameplay integration.
## Example: `self.enter_room()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func enter_room() -> void:
	runtime.entered = true
	spawn_enemies()
	room_entered.emit(runtime.room_runtime_id)

## Purpose: Public method `spawn_enemies` for external gameplay integration.
## Example: `self.spawn_enemies()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func spawn_enemies() -> void:
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

## Purpose: Public method `check_clear_condition` for external gameplay integration.
## Example: `self.check_clear_condition()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func check_clear_condition() -> void:
	if runtime == null or runtime.cleared:
		return
	if active_enemies.is_empty():
		runtime.cleared = true
		generate_reward()
		room_cleared.emit(runtime.room_runtime_id)
		var events := ServiceRegistry.get_service("events") as EventRouter
		if events != null:
			events.emit_room_cleared(runtime.room_runtime_id)

## Purpose: Public method `generate_reward` for external gameplay integration.
## Example: `self.generate_reward()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func generate_reward() -> void:
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

## Purpose: Public method `get_definition` for external gameplay integration.
## Example: `self.get_definition()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func get_definition() -> RoomDefinition:
	if content == null:
		content = ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		return null
	return content.get_resource(room_definition_id) as RoomDefinition

func _on_entity_died(entity_id: String, _entity_ref: Node) -> void:
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
	var identity := entity.get_node_or_null("EntityIdentity") as EntityIdentity
	return identity.entity_id if identity != null else entity.name
