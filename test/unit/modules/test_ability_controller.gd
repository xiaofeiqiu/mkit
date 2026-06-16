extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class _NeverCondition:
	extends Condition

	func evaluate(_ctx: GameplayContext) -> bool:
		return false


class _AlwaysCondition:
	extends Condition

	func evaluate(_ctx: GameplayContext) -> bool:
		return true


func _make_ability(id: String, cooldown: float = 0.0) -> AbilityDefinition:
	var def := AbilityDefinition.new()
	def.ability_id = id
	def.cooldown = cooldown
	def.cast_time = 0.0
	def.cost_type = "none"
	def.cost_amount = 0.0
	def.conditions = []
	def.effects = []
	return def


var ctrl: AbilityController
var content: StubContent
var actions: ActionService
var time: TimeService
var entity: EntityRoot
var ctx: GameplayContext


func before_each() -> void:
	entity = _make_entity_root()
	content = StubContent.new()
	add_child_autofree(content)
	ServiceRegistry.register_service("content", content)
	actions = ActionService.new()
	add_child_autofree(actions)
	ServiceRegistry.register_service("actions", actions)
	time = TimeService.new()
	ServiceRegistry.register_service("time", time)
	ctrl = AbilityController.new()
	entity.add_child(ctrl)
	ctx = GameplayContext.new()
	ctx.source = entity


func _make_entity_root() -> EntityRoot:
	var entity_root := EntityRoot.new()
	entity_root.name = "AbilityEntity"
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "ability.entity"
	entity_root.add_child(identity)
	var state_machine := Hfsm.new()
	state_machine.name = "StateMachine"
	entity_root.add_child(state_machine)
	var receiver := CommandReceiver.new()
	receiver.name = "CommandReceiver"
	entity_root.add_child(receiver)
	var components := Node.new()
	components.name = "Components"
	entity_root.add_child(components)
	var controllers := Node.new()
	controllers.name = "Controllers"
	entity_root.add_child(controllers)
	add_child_autofree(entity_root)
	return entity_root


func after_each() -> void:
	ServiceRegistry.clear()


# --- register_ability ---


func test_tc_ab_01_register_returns_true_and_emits() -> void:
	content._defs["slam"] = _make_ability("slam")
	watch_signals(ctrl)
	var result := ctrl.register_ability("slam")
	assert_true(result)
	assert_true(ctrl.has_ability("slam"))
	assert_signal_emitted_with_parameters(ctrl, "ability_registered", ["slam"])


func test_tc_ab_02_register_same_twice_is_idempotent() -> void:
	content._defs["slam"] = _make_ability("slam")
	ctrl.register_ability("slam")
	var result := ctrl.register_ability("slam")
	assert_true(result)
	assert_eq(ctrl.abilities.size(), 1)


func test_tc_ab_03_register_empty_id_returns_false() -> void:
	var result := ctrl.register_ability("")
	assert_false(result)


func test_tc_ab_04_register_missing_definition_returns_false() -> void:
	var result := ctrl.register_ability("undefined_ability")
	assert_false(result)


# --- can_cast / get_cast_failure_reason ---


func test_tc_ab_05_can_cast_false_for_unregistered() -> void:
	var result := ctrl.can_cast("not_registered", ctx)
	assert_false(result)
	var reason := ctrl.get_cast_failure_reason("not_registered", ctx)
	assert_true(reason.begins_with("not_registered"))


func test_tc_ab_06_can_cast_true_for_valid_ready_ability() -> void:
	content._defs["dash"] = _make_ability("dash")
	ctrl.register_ability("dash")
	assert_true(ctrl.can_cast("dash", ctx))


func test_tc_ab_07_can_cast_false_when_on_cooldown() -> void:
	var def := _make_ability("dash", 2.0)
	content._defs["dash"] = def
	ctrl.register_ability("dash")
	ctrl.cast("dash", ctx)
	var result := ctrl.can_cast("dash", ctx)
	assert_false(result)
	assert_true(ctrl.get_cast_failure_reason("dash", ctx).begins_with("on_cooldown"))


func test_tc_ab_08_can_cast_false_when_null_context() -> void:
	content._defs["dash"] = _make_ability("dash")
	ctrl.register_ability("dash")
	assert_false(ctrl.can_cast("dash", null))
	assert_eq(ctrl.get_cast_failure_reason("dash", null), "missing_context")


func test_tc_ab_09_can_cast_false_when_disabled() -> void:
	var def := _make_ability("slam")
	content._defs["slam"] = def
	ctrl.register_ability("slam")
	(ctrl.abilities["slam"] as AbilityInstance).enabled = false
	var result := ctrl.can_cast("slam", ctx)
	assert_false(result)
	assert_true(ctrl.get_cast_failure_reason("slam", ctx).begins_with("disabled"))


# --- cast — instant ability ---


func test_tc_ab_10_cast_instant_emits_started_and_finished() -> void:
	content._defs["slash"] = _make_ability("slash")
	ctrl.register_ability("slash")
	watch_signals(ctrl)
	ctrl.cast("slash", ctx)
	assert_signal_emitted(ctrl, "ability_cast_started")
	assert_signal_emitted(ctrl, "ability_cast_finished")


func test_tc_ab_11_cast_starts_cooldown_and_emits() -> void:
	var def := _make_ability("slash", 1.5)
	content._defs["slash"] = def
	ctrl.register_ability("slash")
	watch_signals(ctrl)
	ctrl.cast("slash", ctx)
	assert_signal_emitted(ctrl, "cooldown_started")
	assert_false(ctrl.is_cooldown_ready("slash"))
	assert_true(ctrl.get_cooldown_remaining("slash") > 0.0)


func test_tc_ab_12_cast_false_for_unregistered_emits_failed() -> void:
	watch_signals(ctrl)
	var result := ctrl.cast("unknown", ctx)
	assert_false(result)
	assert_signal_emitted(ctrl, "ability_failed")


func test_tc_ab_13_cast_false_with_null_context_emits_failed() -> void:
	content._defs["slash"] = _make_ability("slash")
	ctrl.register_ability("slash")
	watch_signals(ctrl)
	var result := ctrl.cast("slash", null)
	assert_false(result)
	assert_signal_emitted_with_parameters(ctrl, "ability_failed", ["slash", "missing_context"])


# --- cooldown tick ---


func test_tc_ab_14_cooldown_remaining_decreases_after_process() -> void:
	var def := _make_ability("dash", 2.0)
	content._defs["dash"] = def
	ctrl.register_ability("dash")
	ctrl.cast("dash", ctx)
	var remaining_before := ctrl.get_cooldown_remaining("dash")
	ctrl._process(0.5)
	assert_true(ctrl.get_cooldown_remaining("dash") < remaining_before)


func test_tc_ab_15_ability_ready_once_cooldown_expires() -> void:
	var def := _make_ability("dash", 0.1)
	content._defs["dash"] = def
	ctrl.register_ability("dash")
	ctrl.cast("dash", ctx)
	ctrl._process(0.2)
	assert_true(ctrl.is_cooldown_ready("dash"))


# --- cost checking ---


func test_tc_ab_16_cast_fails_when_no_resource_for_cost() -> void:
	var def := _make_ability("fireball")
	def.cost_type = "mana"
	def.cost_amount = 30.0
	content._defs["fireball"] = def
	ctrl.register_ability("fireball")
	watch_signals(ctrl)
	var result := ctrl.cast("fireball", ctx)
	assert_false(result)
	assert_signal_emitted(ctrl, "ability_failed")


# --- condition evaluation ---


func test_tc_ab_17_cast_fails_when_condition_false() -> void:
	var def := _make_ability("slam")
	def.conditions = [_NeverCondition.new()]
	content._defs["slam"] = def
	ctrl.register_ability("slam")
	watch_signals(ctrl)
	var result := ctrl.cast("slam", ctx)
	assert_false(result)
	assert_signal_emitted(ctrl, "ability_failed")


func test_tc_ab_18_cast_succeeds_when_all_conditions_pass() -> void:
	var def := _make_ability("slam")
	def.conditions = [_AlwaysCondition.new()]
	content._defs["slam"] = def
	ctrl.register_ability("slam")
	watch_signals(ctrl)
	var result := ctrl.cast("slam", ctx)
	assert_true(result)
	assert_signal_emitted(ctrl, "ability_cast_finished")


# --- channeled cast ---


func test_tc_ab_19_cast_with_cast_time_emits_started_not_finished() -> void:
	var def := _make_ability("charge")
	def.cast_time = 1.0
	content._defs["charge"] = def
	ctrl.register_ability("charge")
	watch_signals(ctrl)
	ctrl.cast("charge", ctx)
	assert_signal_emitted(ctrl, "ability_cast_started")
	assert_signal_not_emitted(ctrl, "ability_cast_finished")
	assert_eq(actions.active_actions.size(), 1)
	assert_eq(ctrl.active_cast_actions.size(), 1)


func test_tc_ab_20_cast_finished_fires_after_cast_time_elapses() -> void:
	var def := _make_ability("charge")
	def.cast_time = 0.5
	content._defs["charge"] = def
	ctrl.register_ability("charge")
	ctrl.cast("charge", ctx)
	watch_signals(ctrl)
	actions._process(0.6)
	assert_signal_emitted(ctrl, "ability_cast_finished")


func test_tc_ab_21_cast_with_cast_time_respects_pause() -> void:
	var def := _make_ability("charge")
	def.cast_time = 0.5
	content._defs["charge"] = def
	ctrl.register_ability("charge")
	ctrl.cast("charge", ctx)
	watch_signals(ctrl)
	time.set_paused(true)
	actions._process(0.6)
	assert_signal_not_emitted(ctrl, "ability_cast_finished")
	time.set_paused(false)
	actions._process(0.6)
	assert_signal_emitted(ctrl, "ability_cast_finished")


func test_tc_ab_22_cast_with_cast_time_fails_without_action_runner() -> void:
	var def := _make_ability("charge")
	def.cast_time = 0.5
	content._defs["charge"] = def
	ctrl.register_ability("charge")
	ServiceRegistry.unregister_service("actions")
	watch_signals(ctrl)
	var result := ctrl.cast("charge", ctx)
	assert_false(result)
	assert_signal_emitted_with_parameters(
		ctrl, "ability_failed", ["charge", "missing_action_runner"]
	)
	assert_eq(actions.active_actions.size(), 0)
	assert_eq(ctrl.active_cast_actions.size(), 0)


# --- unregister_ability ---


func test_tc_ab_23_unregister_removes_ability() -> void:
	content._defs["slash"] = _make_ability("slash")
	ctrl.register_ability("slash")
	ctrl.unregister_ability("slash")
	assert_false(ctrl.has_ability("slash"))


func test_tc_ab_24_unregister_nonexistent_is_safe() -> void:
	content._defs["slash"] = _make_ability("slash")
	ctrl.register_ability("slash")
	ctrl.unregister_ability("ghost_ability")
	assert_true(ctrl.has_ability("slash"))
	assert_eq(ctrl.abilities.size(), 1)
