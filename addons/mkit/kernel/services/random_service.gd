class_name RandomService
extends RefCounted

var seed_value: int = 0
var rng := RandomNumberGenerator.new()


func set_seed(value: int) -> void:
	seed_value = value
	rng.seed = value


func randomize_seed() -> int:
	rng.randomize()
	seed_value = rng.seed
	return seed_value


func randf() -> float:
	return rng.randf()


func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)


func randf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)


func chance(probability: float) -> bool:
	return randf() < clamp(probability, 0.0, 1.0)


func weighted_pick(entries: Array, weight_property: String = "weight"):
	var total := 0.0
	for entry in entries:
		total += float(entry.get(weight_property))
	if total <= 0.0:
		return null

	var roll := randf_range(0.0, total)
	var cursor := 0.0
	for entry in entries:
		cursor += float(entry.get(weight_property))
		if roll <= cursor:
			return entry
	return entries[-1] if not entries.is_empty() else null
