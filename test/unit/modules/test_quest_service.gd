extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class PassingCondition:
	extends Condition

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return true


class FailingCondition:
	extends Condition

	func _evaluate_impl(_context: GameplayContext) -> bool:
		return false


class CountingEffect:
	extends GameEffect
	var runs: int = 0

	func _apply_impl(_context: GameplayContext) -> EffectResult:
		runs += 1
		return EffectResult.ok(effect_id)


class FailingEffect:
	extends GameEffect

	func _apply_impl(_context: GameplayContext) -> EffectResult:
		return EffectResult.fail(effect_id, "failed")


var quest: QuestService
var content: StubContent
var events: EventService
var effects: EffectService


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	events = EventService.new()
	add_child_autofree(events)
	effects = EffectService.new()
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("events", events)
	ServiceRegistry.register_service("effects", effects)
	quest = QuestService.new()
	add_child_autofree(quest)
	ServiceRegistry.register_service("quest", quest)


func after_each() -> void:
	ServiceRegistry.clear()


# --- helpers ---


func _make_objective(
	id: String,
	event_type: String,
	required: int = 1,
	match_key: String = "",
	match_value: String = "",
	count_key: String = ""
) -> QuestObjectiveDefinition:
	var objective := QuestObjectiveDefinition.new()
	objective.objective_id = id
	objective.event_type = event_type
	objective.required_count = required
	objective.match_key = match_key
	objective.match_value = match_value
	objective.count_payload_key = count_key
	return objective


func _make_quest(
	id: String, objectives: Array[QuestObjectiveDefinition], auto_complete: bool = false
) -> QuestDefinition:
	var definition := QuestDefinition.new()
	definition.quest_id = id
	definition.objectives = objectives
	definition.auto_complete = auto_complete
	content._defs[id] = definition
	return definition


func _make_entity_root(entity_id: String, tags: Array[String] = []) -> EntityRoot:
	var entity := EntityRoot.new()
	entity.name = "Entity"
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = entity_id
	identity.tags = tags
	entity.add_child(identity)
	var state_machine := Hfsm.new()
	state_machine.name = "StateMachine"
	entity.add_child(state_machine)
	var receiver := CommandReceiver.new()
	receiver.name = "CommandReceiver"
	entity.add_child(receiver)
	var components := Node.new()
	components.name = "Components"
	entity.add_child(components)
	var controllers := Node.new()
	controllers.name = "Controllers"
	entity.add_child(controllers)
	add_child_autofree(entity)
	return entity


func _make_enemy(entity_id: String, tags: Array[String] = []) -> EntityRoot:
	return _make_entity_root(entity_id, tags)


func _make_player_with_inventory() -> EntityRoot:
	var player := _make_entity_root("player")
	player.name = "Player"
	var identity := player.get_node("EntityIdentity") as EntityIdentity
	identity.entity_id = "player"
	var controllers := player.get_node("Controllers") as Node
	var inventory := InventoryController.new()
	inventory.name = "InventoryController"
	controllers.add_child(inventory)
	return player


func _make_item_definition(id: String) -> ItemDefinition:
	var definition := ItemDefinition.new()
	definition.item_id = id
	definition.stackable = true
	definition.max_stack = 99
	content._defs[id] = definition
	return definition


# --- accept gating ---


func test_tc_quest_01_accept_requires_prerequisites_and_conditions() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	var definition := _make_quest("quest.main", objectives)
	definition.prerequisite_quest_ids = ["quest.intro"]
	var failing: Array[Condition] = [FailingCondition.new()]
	definition.accept_conditions = failing
	_make_quest("quest.intro", [])

	assert_false(quest.can_accept("quest.main", null))
	assert_false(quest.accept_quest("quest.main", null))

	var intro := QuestState.create("quest.intro")
	intro.status = "turned_in"
	quest.log.states["quest.intro"] = intro
	assert_false(quest.can_accept("quest.main", null))

	var passing: Array[Condition] = [PassingCondition.new()]
	definition.accept_conditions = passing
	watch_signals(quest)
	watch_signals(events)
	assert_true(quest.accept_quest("quest.main", null))
	assert_eq(quest.get_state("quest.main").status, "active")
	assert_signal_emitted_with_parameters(quest, "quest_accepted", ["quest.main"])
	var evt_quest_accepted_1 := DomainEventAsserts.last_event(events, "quest_accepted")
	assert_not_null(evt_quest_accepted_1)
	assert_eq(evt_quest_accepted_1.source_id, "quest.main")
	assert_false(quest.accept_quest("quest.main", null))


# --- kill objective + tag matching ---


func test_tc_quest_02_kill_event_advances_objective_to_complete() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [
		_make_objective("obj.goblins", "enemy_killed", 2, "tags", "goblin")
	]
	_make_quest("quest.cull", objectives)
	quest.accept_quest("quest.cull", null)
	watch_signals(quest)

	var wolf: Array[String] = ["wolf"]
	events.emit_domain_event(CombatEvents.entity_died("wolf_1", _make_enemy("wolf_1", wolf)))
	assert_eq(quest.get_state("quest.cull").get_progress("obj.goblins"), 0)
	assert_false(quest.is_quest_complete("quest.cull"))

	var goblin: Array[String] = ["goblin"]
	events.emit_domain_event(CombatEvents.entity_died("goblin_1", _make_enemy("goblin_1", goblin)))
	events.emit_domain_event(CombatEvents.entity_died("goblin_2", _make_enemy("goblin_2", goblin)))
	assert_eq(quest.get_state("quest.cull").get_progress("obj.goblins"), 2)
	assert_true(quest.is_quest_complete("quest.cull"))
	assert_signal_emitted_with_parameters(
		quest, "objective_advanced", ["quest.cull", "obj.goblins", 2, 2]
	)


func test_tc_quest_12_synthesized_kill_event_is_published_to_event_service() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	_make_quest("quest.kill", objectives)
	quest.accept_quest("quest.kill", null)

	events.emit_domain_event(CombatEvents.entity_died("rat_1", _make_enemy("rat_1")))

	var enemy_killed := DomainEventAsserts.last_event(events, QuestEvents.ENEMY_KILLED)
	assert_not_null(enemy_killed)
	assert_eq(enemy_killed.source_id, "rat_1")


# --- item acquired with payload count key ---


func test_tc_quest_03_item_acquired_event_counts_with_payload_key() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [
		_make_objective("obj.herbs", "item_acquired", 5, "item_id", "item.herb", "amount")
	]
	_make_quest("quest.gather", objectives)
	quest.accept_quest("quest.gather", null)
	_make_item_definition("item.herb")
	_make_item_definition("item.stone")
	var player := _make_player_with_inventory()
	var inventory := (
		player.get_node("Controllers/InventoryController") as InventoryController
	)

	inventory.add_item(ItemInstance.create("item.stone", 9))
	assert_eq(quest.get_state("quest.gather").get_progress("obj.herbs"), 0)

	inventory.add_item(ItemInstance.create("item.herb", 3))
	assert_eq(quest.get_state("quest.gather").get_progress("obj.herbs"), 3)

	inventory.add_item(ItemInstance.create("item.herb", 4))
	assert_eq(quest.get_state("quest.gather").get_progress("obj.herbs"), 5)
	assert_true(quest.is_quest_complete("quest.gather"))


# --- auto complete grants rewards ---


func test_tc_quest_04_auto_complete_grants_reward_effects() -> void:
	var item_def := ItemDefinition.new()
	item_def.item_id = "item.reward"
	content._defs["item.reward"] = item_def
	var grant := GrantItemEffect.new()
	grant.item_id = "item.reward"
	grant.quantity = 1
	grant.give_to_source = true
	var rewards: Array[GameEffect] = [grant]

	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	var definition := _make_quest("quest.bounty", objectives, true)
	definition.reward_effects = rewards

	var player := _make_player_with_inventory()
	var ctx := GameplayContext.new().with_source(player)
	quest.accept_quest("quest.bounty", ctx)
	watch_signals(quest)

	events.emit_domain_event(CombatEvents.entity_died("rat_1", _make_enemy("rat_1")))

	assert_eq(quest.get_state("quest.bounty").status, "turned_in")
	assert_signal_emitted(quest, "quest_completed")
	assert_signal_emitted(quest, "quest_turned_in")
	var inventory := (
		player.get_node("Controllers/InventoryController") as InventoryController
	)
	assert_not_null(inventory.find_item_by_definition("item.reward"))


# --- manual turn-in + repeatable reset ---


func test_tc_quest_05_manual_turn_in_grants_reward_and_repeatable_resets() -> void:
	var counting := CountingEffect.new()
	var rewards: Array[GameEffect] = [counting]
	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	var definition := _make_quest("quest.daily", objectives, false)
	definition.repeatable = true
	definition.reward_effects = rewards

	quest.accept_quest("quest.daily", null)
	events.emit_domain_event(CombatEvents.entity_died("rat_1", _make_enemy("rat_1")))
	assert_true(quest.is_quest_complete("quest.daily"))
	assert_eq(quest.get_state("quest.daily").status, "active")
	assert_eq(counting.runs, 0)

	assert_true(quest.complete_quest("quest.daily", null))
	assert_eq(quest.get_state("quest.daily").status, "completed")
	assert_eq(counting.runs, 0)

	assert_true(quest.turn_in_quest("quest.daily", null))
	assert_eq(counting.runs, 1)
	assert_eq(quest.get_state("quest.daily").status, "available")
	assert_eq(quest.get_state("quest.daily").get_progress("obj.kill"), 0)
	assert_true(quest.can_accept("quest.daily", null))


# --- save / load round-trip ---


func test_tc_quest_06_save_load_roundtrips_quest_log() -> void:
	var objectives_a: Array[QuestObjectiveDefinition] = [
		_make_objective("obj.kill", "enemy_killed", 3)
	]
	_make_quest("quest.a", objectives_a)
	var objectives_b: Array[QuestObjectiveDefinition] = [_make_objective("obj.talk", "npc_talked")]
	_make_quest("quest.b", objectives_b)

	quest.accept_quest("quest.a", null)
	quest.accept_quest("quest.b", null)
	events.emit_domain_event(CombatEvents.entity_died("goblin_1", _make_enemy("goblin_1")))
	assert_eq(quest.get_state("quest.a").get_progress("obj.kill"), 1)

	var json: String = JSON.stringify(quest.to_save_data())
	var restored: Dictionary = JSON.parse_string(json)

	var quest2 := QuestService.new()
	add_child_autofree(quest2)
	quest2.from_save_data(restored)
	assert_eq(quest2.get_state("quest.a").status, "active")
	assert_eq(quest2.get_state("quest.a").get_progress("obj.kill"), 1)
	assert_true(quest2.log.has("quest.b"))
	assert_eq(quest2.get_state("quest.b").status, "active")


# --- domain effects ---


func test_tc_quest_07_accept_quest_effect_accepts_via_service() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	_make_quest("quest.fx", objectives)
	var effect := AcceptQuestEffect.new()
	effect.quest_id = "quest.fx"
	var result := effect.apply(GameplayContext.new())
	assert_true(result.success)
	assert_eq(quest.get_state("quest.fx").status, "active")

	var missing := AcceptQuestEffect.new()
	missing.quest_id = ""
	assert_false(missing.apply(GameplayContext.new()).success)


func test_tc_quest_08_advance_objective_effect_advances_progress() -> void:
	var objectives: Array[QuestObjectiveDefinition] = [
		_make_objective("obj.kill", "enemy_killed", 5)
	]
	_make_quest("quest.fx", objectives)
	quest.accept_quest("quest.fx", null)
	var effect := AdvanceObjectiveEffect.new()
	effect.quest_id = "quest.fx"
	effect.objective_id = "obj.kill"
	effect.amount = 3
	var result := effect.apply(GameplayContext.new())
	assert_true(result.success)
	assert_eq(quest.get_state("quest.fx").get_progress("obj.kill"), 3)

	var missing := AdvanceObjectiveEffect.new()
	missing.quest_id = "quest.fx"
	missing.objective_id = "obj.missing"
	assert_false(missing.apply(GameplayContext.new()).success)


func test_tc_quest_09_complete_quest_effect_turns_in() -> void:
	var counting := CountingEffect.new()
	var rewards: Array[GameEffect] = [counting]
	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	var definition := _make_quest("quest.fx", objectives, false)
	definition.reward_effects = rewards
	quest.accept_quest("quest.fx", null)
	events.emit_domain_event(CombatEvents.entity_died("rat_1", _make_enemy("rat_1")))

	var effect := CompleteQuestEffect.new()
	effect.quest_id = "quest.fx"
	effect.turn_in = true
	var result := effect.apply(GameplayContext.new())
	assert_true(result.success)
	assert_eq(quest.get_state("quest.fx").status, "turned_in")
	assert_eq(counting.runs, 1)


func test_tc_quest_10_complete_quest_effect_handles_auto_complete_turn_in() -> void:
	var counting := CountingEffect.new()
	var rewards: Array[GameEffect] = [counting]
	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	var definition := _make_quest("quest.auto_fx", objectives, true)
	definition.reward_effects = rewards
	quest.accept_quest("quest.auto_fx", null)
	quest.get_state("quest.auto_fx").set_progress("obj.kill", 1)
	assert_eq(quest.get_state("quest.auto_fx").status, "active")
	assert_eq(counting.runs, 0)

	var effect := CompleteQuestEffect.new()
	effect.quest_id = "quest.auto_fx"
	effect.turn_in = true
	var result := effect.apply(GameplayContext.new())
	assert_true(result.success)
	assert_eq(quest.get_state("quest.auto_fx").status, "turned_in")
	assert_eq(counting.runs, 1)


func test_tc_quest_11_turn_in_keeps_completed_when_reward_fails() -> void:
	var failing := FailingEffect.new()
	var rewards: Array[GameEffect] = [failing]
	var objectives: Array[QuestObjectiveDefinition] = [_make_objective("obj.kill", "enemy_killed")]
	var definition := _make_quest("quest.failed_reward", objectives, false)
	definition.reward_effects = rewards
	quest.accept_quest("quest.failed_reward", null)
	events.emit_domain_event(CombatEvents.entity_died("rat_1", _make_enemy("rat_1")))
	assert_true(quest.complete_quest("quest.failed_reward", null))
	assert_eq(quest.get_state("quest.failed_reward").status, "completed")

	watch_signals(quest)
	assert_false(quest.turn_in_quest("quest.failed_reward", null))
	assert_eq(quest.get_state("quest.failed_reward").status, "completed")
	assert_signal_not_emitted(quest, "quest_turned_in")
