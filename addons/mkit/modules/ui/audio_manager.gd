class_name AudioManager
extends Node
@export var sfx_map: Dictionary = {}
@export var music_map: Dictionary = {}
@export var sfx_bus: String = "SFX"
@export var music_bus: String = "Music"
var music_player: AudioStreamPlayer = null


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)


func play_sfx(audio_id: String, volume_db: float = 0.0) -> void:
	if not sfx_map.has(audio_id):
		return
	var player := AudioStreamPlayer.new()
	player.stream = sfx_map[audio_id]
	player.bus = sfx_bus
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func play_music(music_id: String, fade_seconds: float = 0.0) -> void:
	if music_player == null or not music_map.has(music_id):
		return
	music_player.stream = music_map[music_id]
	music_player.play()


func stop_music() -> void:
	if music_player != null:
		music_player.stop()
