class_name WorldService
extends Saveable
signal zone_changed(from_zone_id: String, to_zone_id: String)
const _MAX_FINALIZE_RETRIES: int = 1
@export var player_group: String = "player"
var current_zone_id: String = ""
var _pending_zone_id: String = ""
var _pending_spawn_id: String = ""
var scene_router: SceneService = null
var _connected_scene_router: SceneService = null


func _ready() -> void:
	if save_id == "":
		save_id = "world"
	_resolve_services()
	register_save_scopes()


func _exit_tree() -> void:
	unregister_save_scopes()


func get_save_scopes() -> Array[String]:
	return ["world.zone"]


func get_save_payload_for_scope(scope: String) -> Dictionary:
	if scope.strip_edges() != "world.zone":
		return {}
	return {
		"current_zone_id": current_zone_id,
		"pending_zone_id": _pending_zone_id,
		"pending_spawn_id": _pending_spawn_id
	}


func apply_save_payload_for_scope(scope: String, data: Dictionary) -> bool:
	if scope.strip_edges() != "world.zone":
		return false
	var previous_zone_id := current_zone_id
	current_zone_id = str(data.get("current_zone_id", current_zone_id))
	_pending_zone_id = str(data.get("pending_zone_id", _pending_zone_id))
	_pending_spawn_id = str(data.get("pending_spawn_id", _pending_spawn_id))
	_restore_loaded_zone_scene(previous_zone_id, current_zone_id)
	return true


func _resolve_services() -> void:
	if scene_router == null:
		scene_router = Mkit.scenes()
	_bind_scene_router()


func _bind_scene_router() -> void:
	if scene_router == _connected_scene_router:
		return
	if (
		_connected_scene_router != null
		and _connected_scene_router.scene_changed.is_connected(_on_scene_changed)
	):
		_connected_scene_router.scene_changed.disconnect(_on_scene_changed)
	_connected_scene_router = scene_router
	if scene_router != null and not scene_router.scene_changed.is_connected(_on_scene_changed):
		scene_router.scene_changed.connect(_on_scene_changed)


func go_to_zone(zone_id: String, spawn_id: String = "") -> bool:
	_resolve_services()
	if _pending_zone_id != "":
		return false
	var definition := get_zone(zone_id)
	if definition == null:
		return false
	if scene_router == null:
		return false
	_pending_zone_id = zone_id
	_pending_spawn_id = spawn_id if spawn_id != "" else definition.default_spawn_id
	if not scene_router.change_scene(definition.scene_path):
		_pending_zone_id = ""
		_pending_spawn_id = ""
		return false
	return true


func get_current_zone() -> ZoneDefinition:
	return get_zone(current_zone_id)


func get_zone(zone_id: String) -> ZoneDefinition:
	return ContentService.find_resource(zone_id) as ZoneDefinition


func place_player_at_spawn(spawn_id: String) -> bool:
	var spawn := _find_spawn_point(spawn_id)
	if spawn == null:
		return false
	var player := _find_player()
	if player == null:
		return false
	player.global_position = spawn.global_position
	return true


func _on_scene_changed(_scene_path: String) -> void:
	if _pending_zone_id == "":
		return
	_finalize_zone_entry.call_deferred(_MAX_FINALIZE_RETRIES)


func _finalize_zone_entry(retries_left: int) -> void:
	if _pending_zone_id == "":
		return
	if not place_player_at_spawn(_pending_spawn_id):
		if retries_left > 0:
			_finalize_zone_entry.call_deferred(retries_left - 1)
			return
		push_warning(
			(
				"WorldService: could not place player at spawn '%s' while entering zone '%s'"
				% [_pending_spawn_id, _pending_zone_id]
			)
		)
	var from_zone_id := current_zone_id
	var to_zone_id := _pending_zone_id
	_pending_zone_id = ""
	_pending_spawn_id = ""
	_publish_zone_entry(from_zone_id, to_zone_id)


func _restore_loaded_zone_scene(from_zone_id: String, to_zone_id: String) -> void:
	if to_zone_id == "":
		return
	_resolve_services()
	if scene_router == null or scene_router.current_scene_path == "":
		return
	var definition := get_zone(to_zone_id)
	if definition == null or definition.scene_path == "":
		return
	if scene_router.current_scene_path == definition.scene_path:
		return
	var saved_pending_zone_id := _pending_zone_id
	var saved_pending_spawn_id := _pending_spawn_id
	_pending_zone_id = ""
	_pending_spawn_id = ""
	if not scene_router.change_scene(definition.scene_path):
		_pending_zone_id = saved_pending_zone_id
		_pending_spawn_id = saved_pending_spawn_id
		return
	_publish_zone_entry(from_zone_id, to_zone_id)


func _publish_zone_entry(from_zone_id: String, to_zone_id: String) -> void:
	current_zone_id = to_zone_id
	zone_changed.emit(from_zone_id, to_zone_id)
	var events := Mkit.events()
	if events != null:
		events.emit_domain_event(WorldEvents.zone_changed(from_zone_id, to_zone_id))
		events.emit_domain_event(
			DomainEvent.create("zone_entered", to_zone_id, "", {"zone_id": to_zone_id})
		)
	var definition := get_zone(to_zone_id)
	if definition != null and definition.bgm_id != "":
		var audio := _get_audio()
		if audio != null:
			audio.play_music(definition.bgm_id)


func _find_spawn_point(spawn_id: String) -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(SpawnPoint.GROUP):
		var spawn := node as SpawnPoint
		if spawn != null and spawn.spawn_id == spawn_id:
			return spawn
	return null


func _find_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var players := tree.get_nodes_in_group(player_group)
	if players.is_empty():
		return null
	return players[0] as Node2D


func _get_audio() -> AudioService:
	return Mkit.audio()
