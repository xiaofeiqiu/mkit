class_name ExperienceComponent
extends Saveable
signal level_up(old_level: int, new_level: int)
signal xp_changed(current_xp: int, xp_to_next: int)
@export var curve: ExperienceCurve = null
@export var starting_level: int = 1
var current_level: int = 1
var current_xp: int = 0


func _ready() -> void:
	if save_id == "":
		save_id = "experience"
	current_level = starting_level


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	if curve == null or current_level >= curve.max_level:
		return
	current_xp += amount
	_check_level_ups()
	xp_changed.emit(current_xp, get_xp_to_next_level())


func get_xp_to_next_level() -> int:
	if curve == null:
		return 0
	return max(0, curve.get_xp_required(current_level) - current_xp)


func get_level_progress() -> float:
	if curve == null:
		return 0.0
	var required := curve.get_xp_required(current_level)
	if required <= 0:
		return 1.0
	return clampf(float(current_xp) / float(required), 0.0, 1.0)


func to_save_data() -> Dictionary:
	return {
		"current_level": current_level,
		"current_xp": current_xp,
	}


func from_save_data(data: Dictionary) -> void:
	current_level = data.get("current_level", starting_level)
	current_xp = data.get("current_xp", 0)


func _check_level_ups() -> void:
	if curve == null:
		return
	while current_level < curve.max_level:
		var required := curve.get_xp_required(current_level)
		if current_xp < required:
			break
		current_xp -= required
		var old_level := current_level
		current_level += 1
		level_up.emit(old_level, current_level)
