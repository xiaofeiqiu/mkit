class_name AudioService
extends Saveable
@export var sfx_map: Dictionary = {}
@export var music_map: Dictionary = {}
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"
@export var music_fade_floor_db: float = -80.0
var music_player: AudioStreamPlayer = null
var current_music_id: String = ""
var bus_volumes: Dictionary = {}
var _music_tween: Tween = null


func _ready() -> void:
	if save_id == "":
		save_id = "audio"
	_ensure_music_player()
	_apply_bus_volumes()


func play_sfx(audio_id: String, volume_db: float = 0.0) -> void:
	if not sfx_map.has(audio_id):
		return
	var stream := sfx_map[audio_id] as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = sfx_bus
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func play_music(music_id: String, fade_seconds: float = 0.0) -> void:
	if not music_map.has(music_id):
		return
	var stream := music_map[music_id] as AudioStream
	if stream == null:
		return
	_ensure_music_player()
	if music_player == null:
		return
	music_player.bus = music_bus
	_stop_music_tween()
	if current_music_id == music_id and music_player.playing:
		music_player.volume_db = 0.0
		return
	if fade_seconds <= 0.0:
		_start_music_stream(stream, music_id, 0.0)
		return
	if music_player.stream == null or not music_player.playing:
		_start_music_stream(stream, music_id, music_fade_floor_db)
		_music_tween = create_tween()
		_music_tween.tween_property(music_player, "volume_db", 0.0, fade_seconds)
		_music_tween.tween_callback(_clear_music_tween)
		return
	var half_fade := max(fade_seconds * 0.5, 0.001)
	_music_tween = create_tween()
	_music_tween.tween_property(music_player, "volume_db", music_fade_floor_db, half_fade)
	_music_tween.tween_callback(_start_music_stream.bind(stream, music_id, music_fade_floor_db))
	_music_tween.tween_property(music_player, "volume_db", 0.0, half_fade)
	_music_tween.tween_callback(_clear_music_tween)


func stop_music() -> void:
	if music_player != null:
		_stop_music_tween()
		music_player.stop()
		music_player.volume_db = 0.0
	current_music_id = ""


func set_bus_volume(bus: String, db: float) -> bool:
	var bus_name := bus.strip_edges()
	if bus_name == "":
		return false
	if not _apply_bus_volume(bus_name, db):
		return false
	bus_volumes[bus_name] = db
	return true


func get_bus_volume(bus: String) -> float:
	var bus_name := bus.strip_edges()
	if bus_name == "":
		return 0.0
	if bus_volumes.has(bus_name):
		return float(bus_volumes[bus_name])
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return 0.0
	return AudioServer.get_bus_volume_db(index)


func to_save_data() -> Dictionary:
	return {"bus_volumes": bus_volumes.duplicate(true)}


func from_save_data(data: Dictionary) -> void:
	var raw: Dictionary = data.get("bus_volumes", {})
	bus_volumes.clear()
	for key in raw:
		var bus_name := str(key)
		var db := float(raw[key])
		if _apply_bus_volume(bus_name, db):
			bus_volumes[bus_name] = db


func _ensure_music_player() -> void:
	if music_player != null:
		return
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)


func _start_music_stream(stream: AudioStream, music_id: String, volume_db: float) -> void:
	if music_player == null:
		return
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()
	current_music_id = music_id


func _stop_music_tween() -> void:
	if _music_tween != null:
		_music_tween.kill()
		_music_tween = null


func _clear_music_tween() -> void:
	_music_tween = null


func _apply_bus_volumes() -> void:
	for key in bus_volumes:
		_apply_bus_volume(str(key), float(bus_volumes[key]))


func _apply_bus_volume(bus_name: String, db: float) -> bool:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return false
	AudioServer.set_bus_volume_db(index, db)
	return true
