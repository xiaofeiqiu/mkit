class_name FeedbackSystem
extends Node
signal toast_requested(message: String)
signal screen_shake_requested(strength: float)
@export var damage_number_system_path: NodePath
@export var vfx_spawner_path: NodePath
@export var audio_manager_path: NodePath
@export var ui_manager_path: NodePath
@export var toast_screen_id: String = ""
@export var damage_screen_shake_strength: float = 0.0
@export var death_toast_template: String = ""
var damage_numbers: DamageNumberSystem
var vfx: VFXSpawner
var audio: AudioService
var ui: UIManager


func _ready() -> void:
	damage_numbers = get_node_or_null(damage_number_system_path) as DamageNumberSystem
	vfx = get_node_or_null(vfx_spawner_path) as VFXSpawner
	audio = _resolve_audio()
	ui = get_node_or_null(ui_manager_path) as UIManager
	var events := ServiceRegistry.get_port(ServiceRegistry.SERVICE_EVENTS) as EventService
	if events != null:
		events.damage_applied.connect(_on_damage_applied)
		events.entity_died.connect(_on_entity_died)


func show_toast(message: String) -> Node:
	toast_requested.emit(message)
	if ui != null and toast_screen_id != "":
		return ui.open_screen(toast_screen_id, {"message": message}, false)
	return null


func request_screen_shake(strength: float = 1.0) -> void:
	screen_shake_requested.emit(strength)


func _resolve_audio() -> AudioService:
	if str(audio_manager_path) != "":
		var local_audio := get_node_or_null(audio_manager_path) as AudioService
		if local_audio != null:
			return local_audio
	return ServiceRegistry.get_port(ServiceRegistry.SERVICE_AUDIO) as AudioService


func _on_damage_applied(result) -> void:
	if result == null or result.target == null:
		return
	if damage_numbers != null:
		damage_numbers.show_number(
			result.target.global_position, result.final_amount, result.was_critical
		)
	if vfx != null:
		vfx.spawn("hit", result.target.global_position)
	if audio != null:
		audio.play_sfx("hit")
	if damage_screen_shake_strength > 0.0:
		request_screen_shake(damage_screen_shake_strength)


func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
	if entity_ref == null:
		return
	if vfx != null:
		vfx.spawn("death", entity_ref.global_position)
	if audio != null:
		audio.play_sfx("death")
	if death_toast_template != "":
		show_toast(death_toast_template % entity_id)
