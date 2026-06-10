class_name RunDirector
extends Saveable
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
var _pending_room_runtime: RoomRuntime = null


func _ready() -> void:
	_connect_events()
	if save_id == "":
		save_id = "run_director"
	register_save_scopes()


func _exit_tree() -> void:
	unregister_save_scopes()


func _connect_events() -> void:
	if _events_connected:
		return
	var events := EventService.find()
	if events != null:
		events.entity_died.connect(_on_entity_died)
		_events_connected = true


func get_save_scopes() -> Array[String]:
	return ["world.run", "world.room", "world.reward"]


func get_save_payload_for_scope(scope: String) -> Dictionary:
	match scope.strip_edges():
		"world.run":
			return _get_run_scope_payload()
		"world.room":
			return _get_room_scope_payload()
		"world.reward":
			return _get_reward_scope_payload()
	return {}


func apply_save_payload_for_scope(scope: String, data: Dictionary) -> bool:
	match scope.strip_edges():
		"world.run":
			return _apply_run_scope_payload(data)
		"world.room":
			return _apply_room_scope_payload(data)
		"world.reward":
			return _apply_reward_scope_payload(data)
	return false


func _get_run_scope_payload() -> Dictionary:
	var payload := {}
	if run_state != null:
		payload["run_state"] = run_state.to_save_data()
	payload["run_length"] = run_length
	payload["first_floor_room_pool"] = first_floor_room_pool.duplicate()
	payload["player_entity_id"] = player_entity_id
	return payload


func _get_room_scope_payload() -> Dictionary:
	var payload := {
		"room_graph": _serialize_room_graph(),
		"current_room_runtime": {}
	}
	var runtime := _get_active_room_runtime()
	if runtime != null:
		payload["current_room_runtime"] = runtime.to_save_data()
	payload["pending_reward_ids"] = _extract_room_reward_ids(runtime)
	return payload


func _get_reward_scope_payload() -> Dictionary:
	var payload := {
		"reward_history": [],
		"pending_reward_ids": [],
		"active_room_runtime_id": ""
	}
	if run_state != null:
		payload["reward_history"] = run_state.reward_history.duplicate(true)
	var runtime := _get_active_room_runtime()
	if runtime != null:
		payload["pending_reward_ids"] = _extract_room_reward_ids(runtime)
		payload["active_room_runtime_id"] = runtime.room_runtime_id
	return payload


func _extract_room_reward_ids(runtime: RoomRuntime) -> Array[String]:
	var result: Array[String] = []
	if runtime == null:
		return result
	for option in runtime.reward_options:
		if option == null:
			continue
		result.append(str(option.reward_id))
	return result


func _apply_run_scope_payload(data: Dictionary) -> bool:
	var run_payload := data.get("run_state", {})
	if not (run_payload is Dictionary):
		return false
	if run_state == null:
		run_state = RunState.create(0)
	run_state.from_save_data(run_payload)
	run_length = int(data.get("run_length", run_length))
	var pool := data.get("first_floor_room_pool", run_state.first_floor_room_pool)
	if pool is Array:
		first_floor_room_pool = []
		for raw in pool:
			first_floor_room_pool.append(str(raw))
	player_entity_id = str(data.get("player_entity_id", player_entity_id))
	return true


func _apply_room_scope_payload(data: Dictionary) -> bool:
	var graph_payload := data.get("room_graph", {})
	_restore_room_graph(graph_payload if graph_payload is Dictionary else {})
	if run_graph_is_empty() and run_state != null and run_state.current_room_index >= 0:
		room_graph = DungeonGenerator.new().generate_linear(
			run_state.first_floor_room_pool,
			run_state.seed,
			run_state.run_length
		)
	var runtime_payload := data.get("current_room_runtime", {})
	if runtime_payload is Dictionary and not runtime_payload.is_empty():
		var runtime := RoomRuntime.new()
		runtime.from_save_data(runtime_payload)
		_pending_room_runtime = runtime
	else:
		_pending_room_runtime = null
	var runtime := _get_active_room_runtime()
	var pending_reward_ids := data.get("pending_reward_ids", [])
	if runtime != null and pending_reward_ids is Array:
		_replace_reward_options(runtime, pending_reward_ids)
	_restore_pending_runtime_to_current_controller()
	return true


func _apply_reward_scope_payload(data: Dictionary) -> bool:
	if run_state != null:
		var reward_history := data.get("reward_history", [])
		if reward_history is Array:
			var normalized_history: Array[String] = []
			for raw in reward_history:
				normalized_history.append(str(raw))
			run_state.reward_history = normalized_history
	var runtime := _get_active_room_runtime()
	var pending_reward_ids := data.get("pending_reward_ids", [])
	if runtime != null and pending_reward_ids is Array:
		_replace_reward_options(runtime, pending_reward_ids)
	var active_room_runtime_id := str(data.get("active_room_runtime_id", ""))
	if runtime != null and active_room_runtime_id != "":
		runtime.room_runtime_id = active_room_runtime_id
	return true


func _replace_reward_options(runtime: RoomRuntime, ids: Array) -> void:
	runtime.reward_options.clear()
	for raw in ids:
		var option := RewardOption.new()
		option.reward_id = str(raw)
		runtime.reward_options.append(option)


func _get_active_room_runtime() -> RoomRuntime:
	if current_room_controller != null:
		return current_room_controller.runtime
	return _pending_room_runtime


func _serialize_room_graph() -> Dictionary:
	if room_graph == null:
		return {}
	var nodes_data: Array[Dictionary] = []
	for node in room_graph.nodes:
		if node == null:
			continue
		var next_ids: Array[String] = []
		for next_node in node.next_nodes:
			if next_node != null:
				next_ids.append(str(next_node.node_id))
		nodes_data.append(
			{
				"node_id": node.node_id,
				"room_definition_id": node.room_definition_id,
				"room_type": node.room_type,
				"next_node_ids": next_ids
			}
		)
	return {
		"nodes": nodes_data,
		"start_node_id": room_graph.start_node.node_id if room_graph.start_node != null else "",
		"boss_node_id": room_graph.boss_node.node_id if room_graph.boss_node != null else "",
	}


func _restore_room_graph(data: Dictionary) -> void:
	var nodes_data := data.get("nodes", [])
	if not (nodes_data is Array) or nodes_data.is_empty():
		room_graph = null
		return
	var graph := RoomGraph.new()
	var by_id := {}
	for raw_node in nodes_data:
		if not (raw_node is Dictionary):
			continue
		var node := RoomNode.new()
		node.node_id = str(raw_node.get("node_id", ""))
		node.room_definition_id = str(raw_node.get("room_definition_id", ""))
		node.room_type = str(raw_node.get("room_type", "combat"))
		graph.nodes.append(node)
		by_id[node.node_id] = node
	for raw_node in nodes_data:
		if not (raw_node is Dictionary):
			continue
		var current_id := str(raw_node.get("node_id", ""))
		var node := by_id.get(current_id, null)
		if node == null:
			continue
		var next_ids: Array = raw_node.get("next_node_ids", [])
		if next_ids is Array:
			for raw_next in next_ids:
				var next_node := by_id.get(str(raw_next), null)
				if next_node == null:
					continue
				node.next_nodes.append(next_node)
				next_node.previous_nodes.append(node)
	var start_node_id := str(data.get("start_node_id", ""))
	var boss_node_id := str(data.get("boss_node_id", ""))
	if start_node_id != "" and by_id.has(start_node_id):
		graph.start_node = by_id[start_node_id]
	if boss_node_id != "" and by_id.has(boss_node_id):
		graph.boss_node = by_id[boss_node_id]
	if graph.start_node == null and graph.nodes.size() > 0:
		graph.start_node = graph.nodes[0]
	if graph.boss_node == null and graph.nodes.size() > 0:
		graph.boss_node = graph.nodes[graph.nodes.size() - 1]
	room_graph = graph


func run_graph_is_empty() -> bool:
	if room_graph == null:
		return true
	return room_graph.nodes.is_empty()


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
	var random: RandomService = ServiceRegistry.get_port(ServiceRegistry.SERVICE_RANDOM) as RandomService
	if random != null:
		random.set_seed(seed)
	room_graph = DungeonGenerator.new().generate_linear(first_floor_room_pool, seed, run_length)
	run_state.status = "active"
	run_started.emit(run_state)
	var events := EventService.find()
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
	var events := EventService.find()
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
	var events := EventService.find()
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
	_restore_pending_runtime_to_current_controller()
	current_room_controller.room_cleared.connect(
		func(_id): on_room_cleared(current_room_controller)
	)
	current_room_controller.enter_room()


func _restore_pending_runtime_to_current_controller() -> void:
	if _pending_room_runtime == null:
		return
	if current_room_controller == null or current_room_controller.room_definition_id == "":
		return
	if current_room_controller.runtime == null:
		current_room_controller.runtime = RoomRuntime.new()
	if current_room_controller.room_definition_id != _pending_room_runtime.definition_id:
		return
	current_room_controller.runtime.from_save_data(_pending_room_runtime.to_save_data())
	_pending_room_runtime = null
