class_name RunDirector
extends Node
signal run_started(run_state: RunState)
signal room_enter_requested(room_id: String)
signal choosing_reward(options: Array[RewardOption])
signal run_finished(result: String)
@export var first_floor_room_pool: Array[String] = []
@export var room_scene_container_path: NodePath = NodePath("../RoomRoot")
@export var player_group: String = "player"
@export var player_entity_id: String = "player_001"
@export var run_length: int = 3
var run_state: RunState = null
var room_graph: RoomGraph = null
var current_room_controller: RoomController = null
var _events_connected: bool = false


func _ready() -> void:
	_connect_events()


func _connect_events() -> void:
	if _events_connected:
		return
	var events: EventService = null
	if ServiceRegistry.has_service("events"):
		events = ServiceRegistry.get_service("events") as EventService
	if events != null:
		events.entity_died.connect(_on_entity_died)
		_events_connected = true


func start_run(seed: int = 0) -> void:
	if first_floor_room_pool.is_empty():
		fail_run("empty_room_pool")
		return
	if run_length <= 0:
		push_warning("RunDirector.start_run: run_length <= 0, forcing to 1")
		run_length = 1
	if seed == 0:
		seed = Time.get_ticks_usec()
	run_state = RunState.create(seed)
	run_state.status = "starting"
	var random: RandomService = null
	if ServiceRegistry.has_service("random"):
		random = ServiceRegistry.get_service("random") as RandomService
	if random != null:
		random.set_seed(seed)
	room_graph = DungeonGenerator.new().generate_linear(first_floor_room_pool, seed, run_length)
	run_state.status = "active"
	run_started.emit(run_state)
	var events: EventService = null
	if ServiceRegistry.has_service("events"):
		events = ServiceRegistry.get_service("events") as EventService
	if events != null:
		events.emit_run_started(run_state.run_id, seed)
	_connect_events()
	enter_next_room()


func _on_entity_died(entity_id: String, _entity_ref: Node) -> void:
	if run_state == null or run_state.status == "failed" or run_state.status == "completed":
		return
	if entity_id == player_entity_id:
		fail_run("player_died")


func enter_next_room() -> void:
	if run_state == null:
		fail_run("missing_run_state")
		return
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


func on_room_cleared(room_controller: RoomController) -> void:
	if run_state == null:
		return
	var options: Array[RewardOption] = []
	if room_controller != null and room_controller.runtime != null:
		options = room_controller.runtime.reward_options
	if options.is_empty():
		run_state.current_room_index += 1
		run_state.status = "active"
		enter_next_room()
		return
	run_state.status = "choosing_reward"
	choosing_reward.emit(options)


func select_reward(option: RewardOption) -> void:
	if run_state == null:
		fail_run("missing_run_state")
		return
	if option == null:
		push_warning("RunDirector.select_reward: option is null")
		return
	var coordinator := RewardCoordinator.new()
	coordinator.player_group = player_group
	var applied := coordinator.apply_reward(option, run_state.run_id, get_tree())
	if applied:
		run_state.reward_history.append(option.reward_id)
		run_state.current_room_index += 1
		run_state.status = "active"
		enter_next_room()


func complete_run() -> void:
	if run_state == null:
		push_warning("RunDirector.complete_run: run_state is null")
		return
	run_state.status = "completed"
	if room_graph != null:
		room_graph.clear()
		room_graph = null
	run_finished.emit("completed")
	var events: EventService = null
	if ServiceRegistry.has_service("events"):
		events = ServiceRegistry.get_service("events") as EventService
	if events != null:
		events.emit_run_finished(run_state.run_id, "completed")


func fail_run(reason: String) -> void:
	if reason.strip_edges() == "":
		reason = "unknown"
	if run_state != null:
		run_state.status = "failed"
	if room_graph != null:
		room_graph.clear()
		room_graph = null
	run_finished.emit("failed:%s" % reason)
	var events: EventService = null
	if ServiceRegistry.has_service("events"):
		events = ServiceRegistry.get_service("events") as EventService
	if events != null:
		events.emit_run_finished(
			run_state.run_id if run_state != null else "", "failed:%s" % reason
		)


func _load_room(room_definition_id: String) -> void:
	var container := get_node_or_null(room_scene_container_path)
	if container == null:
		fail_run("missing_room_container")
		return
	var loader := RoomLoader.new()
	var controller := loader.load_room(room_definition_id, container)
	if controller == null:
		fail_run(loader.last_error)
		return
	current_room_controller = controller
	current_room_controller.room_cleared.connect(
		func(_id): on_room_cleared(current_room_controller)
	)
	current_room_controller.enter_room()
