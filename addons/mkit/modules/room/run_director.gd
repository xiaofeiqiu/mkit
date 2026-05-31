class_name RunDirector
extends Node

## Purpose: Emits the `run_started` signal to notify external listeners of a state change.
## Example: `self.run_started.connect(_on_run_started)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal run_started(run_state: RunState)
## Purpose: Emits the `room_enter_requested` signal to notify external listeners of a state change.
## Example: `self.room_enter_requested.connect(_on_room_enter_requested)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal room_enter_requested(room_id: String)
## Purpose: Emits the `choosing_reward` signal to notify external listeners of a state change.
## Example: `self.choosing_reward.connect(_on_choosing_reward)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal choosing_reward(options: Array[RewardOption])
## Purpose: Emits the `run_finished` signal to notify external listeners of a state change.
## Example: `self.run_finished.connect(_on_run_finished)`
## Scenario: Use this in event-driven flows where UI, audio, or systems react without direct coupling.
signal run_finished(result: String)

## Purpose: Inspector-exposed configuration `first_floor_room_pool`.
## Example: `self.first_floor_room_pool = []`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var first_floor_room_pool: Array[String] = []
## Purpose: Inspector-exposed configuration `room_scene_container_path`.
## Example: `self.room_scene_container_path = NodePath(".")`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var room_scene_container_path: NodePath = NodePath("../RoomRoot")
## Purpose: Inspector-exposed configuration `player_group`.
## Example: `self.player_group = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var player_group: String = "player"
## Purpose: Inspector-exposed configuration `player_entity_id`.
## Example: `self.player_entity_id = "value"`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var player_entity_id: String = "player_001"
## Purpose: Inspector-exposed configuration `run_length`.
## Example: `self.run_length = 1`
## Scenario: Tune this in the Inspector or resource setup to adjust behavior without code changes.
@export var run_length: int = 3

## Purpose: Public runtime field `run_state`.
## Example: `self.run_state = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var run_state: RunState = null
## Purpose: Public runtime field `room_graph`.
## Example: `self.room_graph = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var room_graph: RoomGraph = null
## Purpose: Public runtime field `current_room_controller`.
## Example: `self.current_room_controller = null`
## Scenario: Read or update this when coordinating shared runtime state between systems or tests.
var current_room_controller: RoomController = null
var _events_connected: bool = false

## Purpose: Public method `start_run` for external gameplay integration.
## Example: `self.start_run(<seed>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func start_run(seed: int = 0) -> void:
	if seed == 0:
		seed = Time.get_ticks_usec()
	run_state = RunState.create(seed)
	run_state.status = "starting"

	var random := ServiceRegistry.get_service("random") as RandomService
	if random != null:
		random.set_seed(seed)

	room_graph = DungeonGenerator.new().generate_linear(first_floor_room_pool, seed, run_length)
	run_state.status = "active"
	run_started.emit(run_state)

	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.emit_run_started(run_state.run_id, seed)
		if not _events_connected:
			events.entity_died.connect(_on_entity_died)
			_events_connected = true

	enter_next_room()

func _on_entity_died(entity_id: String, _entity_ref: Node) -> void:
	if run_state == null or run_state.status == "failed" or run_state.status == "completed":
		return
	if entity_id == player_entity_id:
		fail_run("player_died")

## Purpose: Public method `enter_next_room` for external gameplay integration.
## Example: `self.enter_next_room()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func enter_next_room() -> void:
	if room_graph == null:
		fail_run("missing_room_graph")
		return

	var room_node := room_graph.get_room_at(run_state.current_room_index)
	if room_node == null:
		complete_run()
		return

	run_state.current_room_id = room_node.room_definition_id
	run_state.room_history.append(room_node.room_definition_id)
	room_enter_requested.emit(room_node.room_definition_id)
	_load_room(room_node.room_definition_id)

## Purpose: Public method `on_room_cleared` for external gameplay integration.
## Example: `self.on_room_cleared(<room_controller>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func on_room_cleared(room_controller: RoomController) -> void:
	run_state.status = "choosing_reward"
	choosing_reward.emit(room_controller.runtime.reward_options)

## Purpose: Public method `select_reward` for external gameplay integration.
## Example: `self.select_reward(<option>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func select_reward(option: RewardOption) -> void:
	var reward_system := RewardSystem.new()
	var ctx := GameplayContext.new()
	ctx.run_id = run_state.run_id
	var player := get_tree().get_first_node_in_group(player_group)
	ctx.source = player
	ctx.target = player
	var applied := reward_system.apply_selected(option, ctx)
	if applied:
		run_state.reward_history.append(option.reward_id)
		run_state.current_room_index += 1
		run_state.status = "active"
		enter_next_room()

## Purpose: Public method `complete_run` for external gameplay integration.
## Example: `self.complete_run()`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func complete_run() -> void:
	run_state.status = "completed"
	run_finished.emit("completed")
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.emit_run_finished(run_state.run_id, "completed")

## Purpose: Public method `fail_run` for external gameplay integration.
## Example: `self.fail_run(<reason>)`
## Scenario: Call this from other systems when this component needs to perform its main behavior.
func fail_run(reason: String) -> void:
	if run_state != null:
		run_state.status = "failed"
	run_finished.emit("failed:%s" % reason)
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.emit_run_finished(run_state.run_id if run_state != null else "", "failed:%s" % reason)

func _load_room(room_definition_id: String) -> void:
	var content := ServiceRegistry.get_service("content") as ContentRegistry
	if content == null:
		fail_run("missing_content_registry")
		return
	var def := content.get_resource(room_definition_id) as RoomDefinition
	if def == null:
		fail_run("missing_room_definition:%s" % room_definition_id)
		return

	var scene := load(def.scene_path) as PackedScene
	if scene == null:
		fail_run("missing_room_scene:%s" % def.scene_path)
		return

	var container := get_node_or_null(room_scene_container_path)
	if container == null:
		fail_run("missing_room_container")
		return

	for child in container.get_children():
		child.queue_free()

	var room := scene.instantiate()
	container.add_child(room)

	current_room_controller = room.get_node_or_null("RoomController") as RoomController
	if current_room_controller == null:
		fail_run("room_missing_controller")
		return

	current_room_controller.setup(room_definition_id)
	current_room_controller.room_cleared.connect(func(_id): on_room_cleared(current_room_controller))
	current_room_controller.enter_room()
