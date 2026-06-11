class_name AudioService
extends Saveable
## 说明：`AudioService` 是 基础服务 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(AudioService.SERVICE_ID, AudioService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `AudioService`。
const SERVICE_ID: String = "audio"
## 编辑器配置：`sfx_map` 表示 `AudioService` 的字段值，由 `AudioService` 的公开 API 读取或维护。
@export var sfx_map: Dictionary = {}
## 编辑器配置：`music_map` 表示 `AudioService` 的字段值，由 `AudioService` 的公开 API 读取或维护。
@export var music_map: Dictionary = {}
## 编辑器配置：`sfx_bus` 表示 `AudioService` 的字段值，由 `AudioService` 的公开 API 读取或维护。
@export var sfx_bus: String = "SFX"
## 编辑器配置：`music_bus` 表示 `AudioService` 的字段值，由 `AudioService` 的公开 API 读取或维护。
@export var music_bus: String = "Music"
## 编辑器配置：`music_fade_floor_db` 表示 `AudioService` 的字段值，由 `AudioService` 的公开 API 读取或维护。
@export var music_fade_floor_db: float = -80.0
## 运行时状态：`music_player` 表示 `AudioService` 的字段值，由 `AudioService` 的公开 API 读取或维护。
var music_player: AudioStreamPlayer = null
## 运行时状态：`current_music_id` 表示稳定 id，由 `AudioService` 的公开 API 读取或维护。
var current_music_id: String = ""
## 运行时状态：`bus_volumes` 表示 `AudioService` 的字段值，由 `AudioService` 的公开 API 读取或维护。
var bus_volumes: Dictionary = {}
var _music_tween: Tween = null


func _ready() -> void:
	if save_id == "":
		save_id = "audio"
	_ensure_music_player()
	_apply_bus_volumes()


## 注册 `audio_definition`，让后续查询或路由可以找到它，并保持 `AudioService` 的领域契约一致。
func register_audio_definition(definition: AudioDefinition) -> bool:
	if definition == null or definition.audio_id == "" or definition.stream == null:
		return false
	var stream := _prepare_stream(definition.stream, definition.loop)
	if definition.kind == AudioDefinition.AudioKind.MUSIC:
		music_map[definition.audio_id] = stream
		sfx_map.erase(definition.audio_id)
	else:
		sfx_map[definition.audio_id] = stream
		music_map.erase(definition.audio_id)
	return true


## 注册 `audio_definitions`，让后续查询或路由可以找到它，并保持 `AudioService` 的领域契约一致。
func register_audio_definitions(definitions: Array) -> int:
	var count := 0
	for raw in definitions:
		if register_audio_definition(raw as AudioDefinition):
			count += 1
	return count


## 执行 `play_sfx` 对应的公开操作，并保持 `AudioService` 的领域契约一致。
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


## 执行 `play_music` 对应的公开操作，并保持 `AudioService` 的领域契约一致。
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


## 执行 `stop_music` 对应的公开操作，并保持 `AudioService` 的领域契约一致。
func stop_music() -> void:
	if music_player != null:
		_stop_music_tween()
		music_player.stop()
		music_player.volume_db = 0.0
	current_music_id = ""


## 设置 `bus_volume` 对应的数据或对象，并保持 `AudioService` 的领域契约一致。
func set_bus_volume(bus: String, db: float) -> bool:
	var bus_name := bus.strip_edges()
	if bus_name == "":
		return false
	if not _apply_bus_volume(bus_name, db):
		return false
	bus_volumes[bus_name] = db
	return true


## 返回 `bus_volume` 对应的数据或对象，并保持 `AudioService` 的领域契约一致。
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


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `AudioService` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {"bus_volumes": bus_volumes.duplicate(true)}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `AudioService` 的领域契约一致。
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


func _prepare_stream(stream: AudioStream, loop: bool) -> AudioStream:
	var wav := stream as AudioStreamWAV
	if wav != null and loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = maxi(1, int(wav.get_length() * float(wav.mix_rate)))
	return stream


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
