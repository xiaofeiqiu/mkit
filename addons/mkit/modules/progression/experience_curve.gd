class_name ExperienceCurve
extends Resource

@export var max_level: int = 20
## Manual per-level XP thresholds. xp_thresholds[0] = XP to go from lv1→lv2, etc.
## When empty, the formula (base_xp * growth_factor^(level-1)) is used instead.
@export var xp_thresholds: Array[int] = []
@export var base_xp: int = 100
@export var growth_factor: float = 1.5


## Returns XP required to advance FROM `level` to `level + 1`.
## Returns 0 when already at max_level.
func get_xp_required(level: int) -> int:
	if level >= max_level:
		return 0
	var index := level - 1
	if index < xp_thresholds.size():
		return xp_thresholds[index]
	return int(base_xp * pow(growth_factor, index))
