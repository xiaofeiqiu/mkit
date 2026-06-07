extends GutTest


var _save_path: String = "/tmp/mkit_quest_pipeline_integration_save.json"


func after_each() -> void:
	IntTestHelpers.remove_file(_save_path)
	IntTestHelpers.cleanup_service_registry()


func test_tc_int_quest_01_bootstrap_combat_reward_and_save_roundtrip() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [IntTestHelpers.make_quest_pipeline_database()]
	add_child_autofree(bootstrap)

	var quest := ServiceRegistry.get_service("quest") as QuestService
	var events := ServiceRegistry.get_service("events") as EventService
	var effects := ServiceRegistry.get_service("effects") as EffectService
	var progression := ServiceRegistry.get_service("progression") as ProgressionService
	var save := ServiceRegistry.get_service("save") as SaveService
	assert_not_null(quest)
	assert_not_null(events)
	assert_not_null(effects)
	assert_not_null(progression)
	assert_not_null(save)
	save.save_path = _save_path

	var player := _make_player()
	var enemy := _make_enemy()
	var inventory := (
		player.get_node("Controllers/InventoryController") as InventoryController
	)
	var context := GameplayContext.new().with_source(player)

	watch_signals(quest)
	watch_signals(events)
	watch_signals(inventory)
	watch_signals(progression)

	assert_true(quest.accept_quest(IntTestHelpers.QUEST_BOUNTY_ID, context))
	assert_eq(quest.get_state(IntTestHelpers.QUEST_BOUNTY_ID).status, "active")

	var damage := DealDamageEffect.new()
	damage.effect_id = "fx.int.damage"
	damage.base_amount = 15.0
	damage.can_crit = false
	var result := effects.execute(damage, GameplayContext.new().with_source(player).with_target(enemy))

	assert_true(result.success)
	assert_eq(quest.get_state(IntTestHelpers.QUEST_BOUNTY_ID).status, "turned_in")
	assert_signal_emitted_with_parameters(
		quest,
		"objective_advanced",
		[
			IntTestHelpers.QUEST_BOUNTY_ID,
			IntTestHelpers.QUEST_OBJECTIVE_KILL_MARKED_ID,
			1,
			1
		]
	)
	assert_signal_emitted_with_parameters(
		quest, "quest_completed", [IntTestHelpers.QUEST_BOUNTY_ID]
	)
	assert_signal_emitted_with_parameters(
		quest, "quest_turned_in", [IntTestHelpers.QUEST_BOUNTY_ID]
	)
	assert_signal_emitted_with_parameters(
		events, "entity_died", [IntTestHelpers.QUEST_MARKED_ENEMY_ID, enemy]
	)
	assert_signal_emitted_with_parameters(
		events, "quest_turned_in", [IntTestHelpers.QUEST_BOUNTY_ID]
	)
	assert_signal_emitted(inventory, "item_added")
	assert_signal_emitted_with_parameters(
		progression, "currency_changed", [IntTestHelpers.QUEST_REWARD_CURRENCY_ID, 7]
	)
	assert_not_null(inventory.find_item_by_definition(IntTestHelpers.QUEST_REWARD_ITEM_ID))
	assert_eq(progression.get_currency(IntTestHelpers.QUEST_REWARD_CURRENCY_ID), 7)

	assert_true(save.save_game(ServiceRegistry))
	quest.log = QuestLog.new()
	progression.state = ProgressionState.new()
	assert_null(quest.get_state(IntTestHelpers.QUEST_BOUNTY_ID))
	assert_eq(progression.get_currency(IntTestHelpers.QUEST_REWARD_CURRENCY_ID), 0)

	assert_true(save.load_game(ServiceRegistry))
	assert_eq(quest.get_state(IntTestHelpers.QUEST_BOUNTY_ID).status, "turned_in")
	assert_eq(progression.get_currency(IntTestHelpers.QUEST_REWARD_CURRENCY_ID), 7)


func _make_player() -> Node:
	var player := IntTestHelpers.make_inventory_entity("Player", "player", 5)
	add_child_autofree(player)
	return player


func _make_enemy() -> Node:
	var tags: Array[String] = [IntTestHelpers.QUEST_MARKED_TAG]
	var enemy := IntTestHelpers.make_health_entity(
		"Enemy", IntTestHelpers.QUEST_MARKED_ENEMY_ID, 10.0, tags
	)
	add_child_autofree(enemy)
	return enemy
