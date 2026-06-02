class_name ExperienceCurve
extends Resource
@export var max_level: int = 20
@export var xp_thresholds: Array[int] = []
@export var base_xp: int = 100
@export var growth_factor: float = 1.5


func get_xp_required(level: int) -> int:
	if level >= max_level:
		return 0
	var index := level - 1
	if index < xp_thresholds.size():
		return xp_thresholds[index]
	return int(base_xp * pow(growth_factor, index))
