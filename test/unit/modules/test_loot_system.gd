extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}
	var _types: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)

	func get_all_by_type(type_name: String) -> Array:
		return _types.get(type_name, [])


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


var loot: LootService
var content: StubContent
var rng: FixedRandom
var ctx: GameplayContext
var events: EventService


func before_each() -> void:
	loot = LootService.new()
	content = StubContent.new()
	add_child_autofree(content)
	rng = FixedRandom.new()
	events = EventService.new()
	add_child_autofree(events)
	ctx = GameplayContext.new()
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("random", rng)
	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("loot", loot)


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


# --- roll_table (via ContentService) ---


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


# --- death loot rules ---


func test_tc_loot_14_death_rule_content_id() -> void:
	var rule := DeathLootRuleDefinition.new()
	rule.rule_id = "death_loot.goblin"
	assert_eq(rule.get_content_id(), "death_loot.goblin")


func test_tc_loot_15_death_rule_matches_definition_faction_tags_and_conditions() -> void:
	var rule := _make_death_rule("death_loot.beast", ["entity.beast"], ["enemy"], ["beast"], [])
	var event := _make_death_event("enemy_01", "entity.beast", "enemy", ["beast", "living"])
	assert_true(rule.matches_death_event(event, GameplayContext.new()))

	rule.required_tags = ["boss"]
	assert_false(rule.matches_death_event(event, GameplayContext.new()))

	rule.required_tags = ["beast"]
	rule.excluded_tags = ["living"]
	assert_false(rule.matches_death_event(event, GameplayContext.new()))

	rule.excluded_tags = []
	rule.conditions = [_NeverCondition.new()]
	assert_false(rule.matches_death_event(event, GameplayContext.new()))


func test_tc_loot_16_death_loot_service_rolls_matching_rules_and_emits_drop() -> void:
	var table := _make_table([_make_entry("fang", 1.0)], 1)
	table.loot_table_id = "loot.beast"
	content._defs["loot.beast"] = table
	var rule := _make_death_rule("death_loot.beast", ["entity.beast"], ["enemy"], ["beast"], ["loot.beast"])
	content._types["DeathLootRuleDefinition"] = [rule]
	var service := DeathLootService.new()
	add_child_autofree(service)
	watch_signals(events)

	var drops := service.process_death_event(
		_make_death_event("enemy_01", "entity.beast", "enemy", ["beast"])
	)

	assert_eq(drops.size(), 1)
	assert_eq(drops[0].rule_id, "death_loot.beast")
	assert_eq(drops[0].loot_table_id, "loot.beast")
	assert_eq(drops[0].roll_result.item_instances[0].definition_id, "fang")
	assert_eq(service.recent_drops.size(), 1)
	var evt := events.recent_events[events.recent_events.size() - 1]
	assert_eq(evt.event_type, LootEvents.LOOT_DROPPED)
	assert_eq(evt.payload.get("drop"), drops[0])


func test_tc_loot_17_death_loot_service_respects_priority_and_stop_after_match() -> void:
	var high_table := _make_table([_make_entry("rare", 1.0)], 1)
	high_table.loot_table_id = "loot.high"
	var low_table := _make_table([_make_entry("common", 1.0)], 1)
	low_table.loot_table_id = "loot.low"
	content._defs["loot.high"] = high_table
	content._defs["loot.low"] = low_table
	var low := _make_death_rule("death_loot.low", [], ["enemy"], [], ["loot.low"])
	low.priority = 1
	var high := _make_death_rule("death_loot.high", [], ["enemy"], [], ["loot.high"])
	high.priority = 10
	high.stop_after_match = true
	content._types["DeathLootRuleDefinition"] = [low, high]
	var service := DeathLootService.new()
	add_child_autofree(service)

	var drops := service.process_death_event(
		_make_death_event("enemy_01", "entity.beast", "enemy", ["beast"])
	)

	assert_eq(drops.size(), 1)
	assert_eq(drops[0].rule_id, "death_loot.high")
	assert_eq(drops[0].roll_result.item_instances[0].definition_id, "rare")


func test_tc_loot_18_death_loot_service_ignores_empty_roll_results() -> void:
	var table := _make_table([], 1)
	table.loot_table_id = "loot.empty"
	content._defs["loot.empty"] = table
	content._types["DeathLootRuleDefinition"] = [
		_make_death_rule("death_loot.empty", [], ["enemy"], [], ["loot.empty"])
	]
	var service := DeathLootService.new()
	add_child_autofree(service)

	var drops := service.process_death_event(
		_make_death_event("enemy_01", "entity.beast", "enemy", ["beast"])
	)

	assert_eq(drops.size(), 0)
	assert_true(events.recent_events.is_empty())


func _make_death_rule(
	rule_id: String,
	definition_ids: Array[String],
	factions: Array[String],
	required_tags: Array[String],
	loot_table_ids: Array[String]
) -> DeathLootRuleDefinition:
	var rule := DeathLootRuleDefinition.new()
	rule.rule_id = rule_id
	rule.entity_definition_ids = definition_ids
	rule.factions = factions
	rule.required_tags = required_tags
	rule.loot_table_ids = loot_table_ids
	return rule


func _make_death_event(
	entity_id: String, definition_id: String, faction: String, tags: Array[String]
) -> DomainEvent:
	return DomainEvent.create(
		CombatEvents.ENTITY_DIED,
		entity_id,
		"",
		{
			"entity_id": entity_id,
			"definition_id": definition_id,
			"faction": faction,
			"tags": tags,
			"killer_id": "player_01",
		}
	)
