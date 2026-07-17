extends GutTest


class FixedRandom:
	extends RandomService
	var fixed: float = 0.0

	func randf() -> float:
		return fixed


func test_tc_rand_01_weighted_pick_uses_low_roll_for_first_weight_bucket() -> void:
	var random := FixedRandom.new()
	random.fixed = 0.0
	var entries := [{"id": "stone", "weight": 1.0}, {"id": "gold", "weight": 99.0}]
	var picked := random.weighted_pick(entries) as Dictionary
	assert_eq(picked.get("id", ""), "stone")


func test_tc_rand_02_weighted_pick_uses_high_roll_for_later_weight_bucket() -> void:
	var random := FixedRandom.new()
	random.fixed = 0.99
	var entries := [{"id": "stone", "weight": 1.0}, {"id": "gold", "weight": 99.0}]
	var picked := random.weighted_pick(entries) as Dictionary
	assert_eq(picked.get("id", ""), "gold")


func test_tc_rand_03_weighted_pick_ignores_non_positive_weights() -> void:
	var random := FixedRandom.new()
	random.fixed = 0.0
	var entries := [{"id": "bad", "weight": -10.0}, {"id": "empty", "weight": 0.0}]
	assert_null(random.weighted_pick(entries))


func test_tc_rand_04_chance_uses_service_rng() -> void:
	var random := FixedRandom.new()
	random.fixed = 0.25
	assert_true(random.chance(0.5))
	assert_false(random.chance(0.1))
