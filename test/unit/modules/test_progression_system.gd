extends GutTest


class StubContent:
	extends ContentRegistry
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


func _make_upgrade(
	id: String,
	cost: int = 10,
	currency: String = "gold",
	max_level: int = 3,
	prereqs: Array[String] = []
) -> UpgradeDefinition:
	var def := UpgradeDefinition.new()
	def.upgrade_id = id
	def.currency_id = currency
	def.cost_by_level = []
	for _l in max_level:
		def.cost_by_level.append(cost)
	def.max_level = max_level
	def.prerequisite_upgrade_ids = prereqs
	def.unlock_content_ids = []
	def.effects = []
	return def


var progression: ProgressionSystem
var content: StubContent


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	ServiceRegistry.register_service("content", content)
	progression = ProgressionSystem.new()
	add_child_autofree(progression)
	progression._ready()


func after_each() -> void:
	ServiceRegistry.clear()


# --- add_currency / get_currency ---


func test_tc_prog_01_add_currency_increases_balance_and_emits() -> void:
	watch_signals(progression)
	progression.add_currency("gold", 100)
	assert_eq(progression.get_currency("gold"), 100)
	assert_signal_emitted_with_parameters(progression, "currency_changed", ["gold", 100])


func test_tc_prog_02_add_currency_accumulates() -> void:
	progression.add_currency("gold", 50)
	progression.add_currency("gold", 30)
	assert_eq(progression.get_currency("gold"), 80)


func test_tc_prog_03_add_zero_is_noop() -> void:
	watch_signals(progression)
	progression.add_currency("gold", 0)
	assert_signal_not_emitted(progression, "currency_changed")
	assert_eq(progression.get_currency("gold"), 0)


func test_tc_prog_04_add_currency_empty_id_ignored() -> void:
	progression.add_currency("", 50)
	assert_eq(progression.get_currency(""), 0)


func test_tc_prog_05_get_currency_zero_for_unknown() -> void:
	assert_eq(progression.get_currency("unknown"), 0)


func test_tc_prog_06_add_negative_reduces_balance() -> void:
	progression.add_currency("gold", 100)
	progression.add_currency("gold", -30)
	assert_eq(progression.get_currency("gold"), 70)


# --- spend_currency ---


func test_tc_prog_18_spend_currency_deducts_and_emits() -> void:
	progression.add_currency("gold", 100)
	watch_signals(progression)
	assert_true(progression.spend_currency("gold", 30))
	assert_eq(progression.get_currency("gold"), 70)
	assert_signal_emitted_with_parameters(progression, "currency_changed", ["gold", 70])


func test_tc_prog_19_spend_currency_rejects_when_insufficient() -> void:
	progression.add_currency("gold", 20)
	watch_signals(progression)
	assert_false(progression.spend_currency("gold", 50))
	assert_eq(progression.get_currency("gold"), 20)
	assert_signal_not_emitted(progression, "currency_changed")


func test_tc_prog_20_spend_currency_rejects_non_positive_amount() -> void:
	progression.add_currency("gold", 20)
	assert_false(progression.spend_currency("gold", 0))
	assert_false(progression.spend_currency("gold", -5))
	assert_eq(progression.get_currency("gold"), 20)


func test_tc_prog_21_spend_currency_rejects_empty_id() -> void:
	assert_false(progression.spend_currency("", 10))


# --- can_unlock ---


func test_tc_prog_07_can_unlock_false_when_definition_missing() -> void:
	assert_false(progression.can_unlock("not_defined"))


func test_tc_prog_08_can_unlock_false_when_currency_insufficient() -> void:
	content._defs["hp_up"] = _make_upgrade("hp_up", 50, "gold")
	progression.add_currency("gold", 20)
	assert_false(progression.can_unlock("hp_up"))


func test_tc_prog_09_can_unlock_true_when_currency_sufficient() -> void:
	content._defs["hp_up"] = _make_upgrade("hp_up", 50, "gold")
	progression.add_currency("gold", 50)
	assert_true(progression.can_unlock("hp_up"))


func test_tc_prog_10_can_unlock_false_when_prerequisite_not_met() -> void:
	var prereqs: Array[String] = ["hp_up"]
	content._defs["hp_up2"] = _make_upgrade("hp_up2", 50, "gold", 3, prereqs)
	content._defs["hp_up"] = _make_upgrade("hp_up", 50, "gold")
	progression.add_currency("gold", 500)
	assert_false(progression.can_unlock("hp_up2"))


func test_tc_prog_11_can_unlock_true_once_prerequisite_unlocked() -> void:
	content._defs["hp_up"] = _make_upgrade("hp_up", 10, "gold")
	var prereqs: Array[String] = ["hp_up"]
	content._defs["hp_up2"] = _make_upgrade("hp_up2", 10, "gold", 3, prereqs)
	progression.add_currency("gold", 500)
	progression.unlock_or_level_up("hp_up")
	assert_true(progression.can_unlock("hp_up2"))


func test_tc_prog_12_can_unlock_false_when_at_max_level() -> void:
	content._defs["armor"] = _make_upgrade("armor", 10, "gold", 1)
	progression.add_currency("gold", 500)
	progression.unlock_or_level_up("armor")
	assert_false(progression.can_unlock("armor"))


# --- unlock_or_level_up ---


func test_tc_prog_13_successful_unlock_deducts_currency_and_emits() -> void:
	content._defs["speed_up"] = _make_upgrade("speed_up", 30, "gold")
	progression.add_currency("gold", 100)
	watch_signals(progression)
	var result := progression.unlock_or_level_up("speed_up")
	assert_true(result)
	assert_eq(progression.get_currency("gold"), 70)
	assert_signal_emitted(progression, "currency_changed")
	assert_signal_emitted_with_parameters(progression, "upgrade_level_changed", ["speed_up", 1])


func test_tc_prog_14_unlock_increments_level_each_call() -> void:
	content._defs["atk"] = _make_upgrade("atk", 10, "gold", 3)
	progression.add_currency("gold", 500)
	progression.unlock_or_level_up("atk")
	progression.unlock_or_level_up("atk")
	assert_eq(progression.state.get_upgrade_level("atk"), 2)


func test_tc_prog_15_unlock_returns_false_when_cannot_unlock() -> void:
	content._defs["rare"] = _make_upgrade("rare", 999, "gold")
	progression.add_currency("gold", 5)
	var result := progression.unlock_or_level_up("rare")
	assert_false(result)
	assert_eq(progression.get_currency("gold"), 5)


func test_tc_prog_16_unlock_emits_content_unlocked_for_each_id() -> void:
	var def := _make_upgrade("combo_unlock", 10, "gold")
	def.unlock_content_ids = ["ability_combo_strike", "ability_combo_finish"]
	content._defs["combo_unlock"] = def
	progression.add_currency("gold", 100)
	watch_signals(progression)
	progression.unlock_or_level_up("combo_unlock")
	assert_signal_emit_count(progression, "content_unlocked", 2)


# --- save / load round-trip ---


func test_tc_prog_17_save_load_roundtrip_preserves_data() -> void:
	content._defs["hp_up"] = _make_upgrade("hp_up", 10, "gold")
	progression.add_currency("gold", 100)
	progression.unlock_or_level_up("hp_up")
	var data := progression.to_save_data()
	var prog2 := ProgressionSystem.new()
	add_child_autofree(prog2)
	prog2._ready()
	prog2.from_save_data(data)
	assert_eq(prog2.get_currency("gold"), progression.get_currency("gold"))
	assert_eq(prog2.state.get_upgrade_level("hp_up"), 1)
