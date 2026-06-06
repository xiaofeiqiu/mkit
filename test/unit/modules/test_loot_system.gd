extends GutTest


class StubContent:
	extends ContentRegistry
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class FixedRandom:
	extends RandomService
	var fixed: float = 0.0

	func randf() -> float:
		return fixed

	func randf_range(from: float, to: float) -> float:
		return from + fixed * (to - from)

	func randi_range(from: int, _to: int) -> int:
		return from


class _NeverCondition:
	extends Condition

	func evaluate(_ctx: GameplayContext) -> bool:
		return false


func _make_entry(content_id: String, weight: float, min_q: int = 1, max_q: int = 1) -> LootEntry:
	var e := LootEntry.new()
	e.content_id = content_id
	e.weight = weight
	e.min_quantity = min_q
	e.max_quantity = max_q
	e.conditions = []
	return e


func _make_table(
	entries: Array, rolls: int = 1, allow_empty: bool = false, empty_weight: float = 0.0
) -> LootTableDefinition:
	var t := LootTableDefinition.new()
	t.entries.assign(entries)
	t.rolls = rolls
	t.allow_empty = allow_empty
	t.empty_weight = empty_weight
	return t


var loot: LootSystem
var content: StubContent
var rng: FixedRandom
var ctx: GameplayContext


func before_each() -> void:
	loot = LootSystem.new()
	content = StubContent.new()
	add_child_autofree(content)
	rng = FixedRandom.new()
	ctx = GameplayContext.new()
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("random", rng)


func after_each() -> void:
	ServiceRegistry.clear()


# --- roll (direct table object) ---


func test_tc_loot_01_empty_table_returns_empty_result() -> void:
	var table := _make_table([], 1)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances.size(), 0)


func test_tc_loot_02_zero_rolls_returns_empty() -> void:
	var table := _make_table([_make_entry("coin", 1.0)], 0)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances.size(), 0)


func test_tc_loot_03_single_entry_table_always_returns_it() -> void:
	rng.fixed = 0.0
	var table := _make_table([_make_entry("gem", 1.0)], 1)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances.size(), 1)
	assert_eq(result.item_instances[0].definition_id, "gem")


func test_tc_loot_04_n_rolls_produce_n_items() -> void:
	var table := _make_table([_make_entry("coin", 1.0)], 3)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances.size(), 3)


func test_tc_loot_05_allow_empty_empty_bucket_when_roll_low() -> void:
	rng.fixed = 0.0
	var table := _make_table([_make_entry("gem", 10.0)], 1, true, 100.0)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances.size(), 0)
	assert_eq(result.debug_rolls[0].get("result"), "empty")


func test_tc_loot_06_weighted_roll_picks_heavier_entry() -> void:
	rng.fixed = 0.99
	var entries := [_make_entry("stone", 1.0), _make_entry("gold", 99.0)]
	var table := _make_table(entries, 1)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances[0].definition_id, "gold")


func test_tc_loot_07_quantity_rolled_at_min() -> void:
	var table := _make_table([_make_entry("arrow", 1.0, 3, 7)], 1)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances[0].quantity, 3)


# --- roll_table (via ContentRegistry) ---


func test_tc_loot_08_roll_table_missing_service_returns_empty() -> void:
	ServiceRegistry.unregister_service("content")
	var result := loot.roll_table("goblin_drops", ctx)
	assert_eq(result.item_instances.size(), 0)


func test_tc_loot_09_roll_table_unknown_id_returns_empty() -> void:
	var result := loot.roll_table("no_such_table", ctx)
	assert_eq(result.item_instances.size(), 0)


func test_tc_loot_10_roll_table_valid_table_produces_output() -> void:
	var table := _make_table([_make_entry("potion", 1.0)], 1)
	content._defs["chest_loot"] = table
	var result := loot.roll_table("chest_loot", ctx)
	assert_eq(result.item_instances.size(), 1)
	assert_eq(result.item_instances[0].definition_id, "potion")


func test_tc_loot_11_roll_table_empty_id_returns_empty() -> void:
	var result := loot.roll_table("", ctx)
	assert_eq(result.item_instances.size(), 0)


# --- condition filtering ---


func test_tc_loot_12_entries_with_failed_conditions_excluded() -> void:
	var e1 := _make_entry("gem", 1.0)
	e1.conditions = [_NeverCondition.new()]
	var e2 := _make_entry("coin", 1.0)
	rng.fixed = 0.0
	var table := _make_table([e1, e2], 1)
	var result := loot.roll(table, ctx)
	assert_eq(result.item_instances[0].definition_id, "coin")


# --- debug_rolls ---


func test_tc_loot_13_debug_rolls_has_one_entry_per_roll() -> void:
	var table := _make_table([_make_entry("gem", 1.0)], 3)
	var result := loot.roll(table, ctx)
	assert_eq(result.debug_rolls.size(), 3)
