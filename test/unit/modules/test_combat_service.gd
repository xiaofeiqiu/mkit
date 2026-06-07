extends GutTest


class FixedRandom:
	extends RandomService
	var fixed_value: float = 0.0

	func randf() -> float:
		return fixed_value

	func randi_range(from: int, _to: int) -> int:
		return from

	func randf_range(from: float, to: float) -> float:
		return fixed_value * (to - from) + from


var resolver: CombatService
var fixed_random: FixedRandom


func _make_entity_with_stats() -> EntityRoot:
	var e := EntityRoot.new()
	e.name = "Entity"
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	e.add_child(identity)
	var state_machine := StateMachine.new()
	state_machine.name = "StateMachine"
	e.add_child(state_machine)
	var receiver := CommandReceiver.new()
	receiver.name = "CommandReceiver"
	e.add_child(receiver)
	var components := Node.new()
	components.name = "Components"
	e.add_child(components)
	var controllers := Node.new()
	controllers.name = "Controllers"
	e.add_child(controllers)
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	stats.base_stats = {
		"max_hp": 100.0,
		"attack_power": 0.0,
		"defense": 0.0,
		"move_speed": 160.0,
		"max_mana": 0.0,
		"max_stamina": 100.0,
		"attack_speed": 1.0,
		"crit_chance": 0.0,
		"crit_damage": 1.5,
		"cooldown_reduction": 0.0,
		"luck": 0.0,
		"damage_multiplier": 1.0,
		"healing_multiplier": 1.0,
		"evade_chance": 0.0
	}
	components.add_child(stats)
	return e


func before_each() -> void:
	resolver = CombatService.new()
	fixed_random = FixedRandom.new()


func after_each() -> void:
	ServiceRegistry.clear()


# --- null / missing source or target ---


func test_tc_cmbt_01_null_source_returns_zero_damage() -> void:
	var req := DamageRequest.new()
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	req.target = tgt
	req.base_amount = 50.0
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 0.0)
	assert_true(result.trace.has("failure"))


func test_tc_cmbt_02_null_target_returns_zero_damage() -> void:
	var req := DamageRequest.new()
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	req.source = src
	req.base_amount = 50.0
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 0.0)


# --- base damage calculation (no stats) ---


func test_tc_cmbt_03_base_amount_is_final_when_no_stats() -> void:
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 30.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 30.0)


# --- attack_power and damage_multiplier ---


func test_tc_cmbt_04_attack_power_added_to_base() -> void:
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var src_stats := src.get_node("Components/StatsComponent") as StatsComponent
	src_stats.set_base_stat("attack_power", 10.0)
	src_stats.set_base_stat("damage_multiplier", 1.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 20.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 30.0)


func test_tc_cmbt_05_damage_multiplier_scales_total() -> void:
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var src_stats := src.get_node("Components/StatsComponent") as StatsComponent
	src_stats.set_base_stat("attack_power", 0.0)
	src_stats.set_base_stat("damage_multiplier", 2.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 15.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 30.0)


# --- defense ---


func test_tc_cmbt_06_defense_reduces_final_damage() -> void:
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var tgt_stats := tgt.get_node("Components/StatsComponent") as StatsComponent
	tgt_stats.set_base_stat("defense", 10.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 25.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 15.0)


func test_tc_cmbt_07_damage_cannot_go_below_zero() -> void:
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var tgt_stats := tgt.get_node("Components/StatsComponent") as StatsComponent
	tgt_stats.set_base_stat("defense", 100.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 10.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_eq(result.final_amount, 0.0)


# --- crit ---


func test_tc_cmbt_08_crit_multiplies_damage_when_roll_passes() -> void:
	fixed_random.fixed_value = 0.0
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var src_stats := src.get_node("Components/StatsComponent") as StatsComponent
	src_stats.set_base_stat("attack_power", 0.0)
	src_stats.set_base_stat("crit_chance", 0.5)
	src_stats.set_base_stat("crit_damage", 2.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 20.0
	req.can_crit = true
	var result := resolver.resolve(req)
	assert_true(result.was_critical)
	assert_eq(result.final_amount, 40.0)


func test_tc_cmbt_09_crit_does_not_trigger_when_can_crit_false() -> void:
	fixed_random.fixed_value = 0.0
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var src_stats := src.get_node("Components/StatsComponent") as StatsComponent
	src_stats.set_base_stat("attack_power", 0.0)
	src_stats.set_base_stat("crit_chance", 1.0)
	src_stats.set_base_stat("crit_damage", 3.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 20.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_false(result.was_critical)
	assert_eq(result.final_amount, 20.0)


func test_tc_cmbt_10_crit_does_not_trigger_when_roll_fails() -> void:
	fixed_random.fixed_value = 0.99
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var src_stats := src.get_node("Components/StatsComponent") as StatsComponent
	src_stats.set_base_stat("crit_chance", 0.5)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 20.0
	req.can_crit = true
	var result := resolver.resolve(req)
	assert_false(result.was_critical)


# --- on-hit status application ---


func test_tc_cmbt_11_on_hit_status_chance_1_always_applies() -> void:
	fixed_random.fixed_value = 0.0
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 10.0
	req.can_crit = false
	req.on_hit_statuses = [{"status_id": "poison", "chance": 1.0, "stacks": 2, "duration": 5.0}]
	var result := resolver.resolve(req)
	assert_true(result.applied_status_effects.has("poison"))
	assert_eq(result.status_applications[0].get("stacks"), 2)


func test_tc_cmbt_12_on_hit_status_chance_0_never_applies() -> void:
	fixed_random.fixed_value = 0.5
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 10.0
	req.can_crit = false
	req.on_hit_statuses = [{"status_id": "freeze", "chance": 0.0}]
	var result := resolver.resolve(req)
	assert_true(result.applied_status_effects.is_empty())


func test_tc_cmbt_13_on_hit_status_skipped_if_evaded() -> void:
	fixed_random.fixed_value = 0.0
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var tgt_stats := tgt.get_node("Components/StatsComponent") as StatsComponent
	tgt_stats.set_base_stat("evade_chance", 1.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 20.0
	req.can_crit = false
	req.on_hit_statuses = [{"status_id": "poison", "chance": 1.0, "stacks": 1, "duration": 3.0}]
	var result := resolver.resolve(req)
	assert_true(result.was_evaded)
	assert_true(result.applied_status_effects.is_empty())


# --- trace dict ---


func test_tc_cmbt_14_resolve_populates_trace() -> void:
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 10.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_true(result.trace.has("base"))
	assert_true(result.trace.has("after_attack_power"))
	assert_true(result.trace.has("after_damage_multiplier"))
	assert_true(result.trace.has("after_crit"))
	assert_true(result.trace.has("after_defense"))


# --- combat service registration ---


func test_tc_cmbt_15_combat_service_returns_registered_instance() -> void:
	var registered := CombatService.new()
	ServiceRegistry.register_service("combat", registered)
	assert_eq(ServiceRegistry.get_service("combat") as CombatService, registered)


# --- evade ---


func test_tc_cmbt_16_evade_chance_1_always_evades() -> void:
	fixed_random.fixed_value = 0.0
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var tgt_stats := tgt.get_node("Components/StatsComponent") as StatsComponent
	tgt_stats.set_base_stat("evade_chance", 1.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 20.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_true(result.was_evaded)
	assert_eq(result.final_amount, 0.0)


func test_tc_cmbt_17_evade_chance_0_never_evades() -> void:
	fixed_random.fixed_value = 0.5
	ServiceRegistry.register_service("random", fixed_random)
	var src := _make_entity_with_stats()
	add_child_autofree(src)
	var tgt := _make_entity_with_stats()
	add_child_autofree(tgt)
	var tgt_stats := tgt.get_node("Components/StatsComponent") as StatsComponent
	tgt_stats.set_base_stat("evade_chance", 0.0)
	var req := DamageRequest.new()
	req.source = src
	req.target = tgt
	req.base_amount = 20.0
	req.can_crit = false
	var result := resolver.resolve(req)
	assert_false(result.was_evaded)
	assert_true(result.final_amount > 0.0)
