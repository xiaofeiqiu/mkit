class_name FeedbackSystem
extends Node
@export var damage_number_system_path: NodePath
@export var vfx_spawner_path: NodePath
@export var audio_manager_path: NodePath
var damage_numbers: DamageNumberSystem
var vfx: VFXSpawner
var audio: AudioManager


func _ready() -> void:
	damage_numbers = get_node_or_null(damage_number_system_path) as DamageNumberSystem
	vfx = get_node_or_null(vfx_spawner_path) as VFXSpawner
	audio = get_node_or_null(audio_manager_path) as AudioManager
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events != null:
		events.damage_applied.connect(_on_damage_applied)
		events.entity_died.connect(_on_entity_died)


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


func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
	if entity_ref == null:
		return
	if vfx != null:
		vfx.spawn("death", entity_ref.global_position)
	if audio != null:
		audio.play_sfx("death")
