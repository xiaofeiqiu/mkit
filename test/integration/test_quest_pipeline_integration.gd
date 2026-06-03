extends GutTest


class GrantCurrencyEffect:
	extends GameEffect
	var currency_id: String = "gold"
	var amount: int = 0

	func _apply_impl(_context: GameplayContext) -> EffectResult:
		if not ServiceRegistry.has_service("progression"):
			return EffectResult.fail(effect_id, "Missing progression service")
		var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
		if progression == null:
			return EffectResult.fail(effect_id, "Missing progression service")
		progression.add_currency(currency_id, amount)
		return EffectResult.ok(effect_id, {"currency_id": currency_id, "amount": amount})


var _save_path: String = "/tmp/mkit_quest_pipeline_integration_save.json"


func after_each() -> void:
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)
	for child in ServiceRegistry.get_children():
		child.queue_free()
	ServiceRegistry.clear()


func test_tc_int_quest_01_bootstrap_combat_reward_and_save_roundtrip() -> void:
	var bootstrap := GameBootstrap.new()
	bootstrap.resource_databases = [_make_database()]
	add_child_autofree(bootstrap)

	var quest := ServiceRegistry.get_service("quest") as QuestSystem
	var events := ServiceRegistry.get_service("events") as EventRouter
	var effects := ServiceRegistry.get_service("effects") as EffectExecutor
	var progression := ServiceRegistry.get_service("progression") as ProgressionSystem
	var save := ServiceRegistry.get_service("save") as SaveManager
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

	assert_true(quest.accept_quest("quest.int.bounty", context))
	assert_eq(quest.get_state("quest.int.bounty").status, "active")

	var damage := DealDamageEffect.new()
	damage.effect_id = "fx.int.damage"
	damage.base_amount = 15.0
	damage.can_crit = false
	var result := effects.execute(damage, GameplayContext.new().with_source(player).with_target(enemy))

	assert_true(result.success)
	assert_eq(quest.get_state("quest.int.bounty").status, "turned_in")
	assert_signal_emitted_with_parameters(
		quest, "objective_advanced", ["quest.int.bounty", "obj.kill_marked", 1, 1]
	)
	assert_signal_emitted_with_parameters(quest, "quest_completed", ["quest.int.bounty"])
	assert_signal_emitted_with_parameters(quest, "quest_turned_in", ["quest.int.bounty"])
	assert_signal_emitted_with_parameters(events, "entity_died", ["enemy.marked", enemy])
	assert_signal_emitted_with_parameters(events, "quest_turned_in", ["quest.int.bounty"])
	assert_signal_emitted(inventory, "item_added")
	assert_signal_emitted_with_parameters(progression, "currency_changed", ["gold", 7])
	assert_not_null(inventory.find_item_by_definition("item.int.reward"))
	assert_eq(progression.get_currency("gold"), 7)

	assert_true(save.save_game(ServiceRegistry))
	quest.log = QuestLog.new()
	progression.state = ProgressionState.new()
	assert_null(quest.get_state("quest.int.bounty"))
	assert_eq(progression.get_currency("gold"), 0)

	assert_true(save.load_game(ServiceRegistry))
	assert_eq(quest.get_state("quest.int.bounty").status, "turned_in")
	assert_eq(progression.get_currency("gold"), 7)


func _make_database() -> ResourceDatabase:
	var item := ItemDefinition.new()
	item.item_id = "item.int.reward"
	item.stackable = true
	item.max_stack = 99

	var objective := QuestObjectiveDefinition.new()
	objective.objective_id = "obj.kill_marked"
	objective.event_type = "enemy_killed"
	objective.match_key = "tags"
	objective.match_value = "marked"
	objective.required_count = 1

	var grant_item := GrantItemEffect.new()
	grant_item.effect_id = "fx.int.reward_item"
	grant_item.item_id = "item.int.reward"
	grant_item.quantity = 2
	grant_item.give_to_source = true

	var grant_currency := GrantCurrencyEffect.new()
	grant_currency.effect_id = "fx.int.reward_gold"
	grant_currency.currency_id = "gold"
	grant_currency.amount = 7

	var objectives: Array[QuestObjectiveDefinition] = [objective]
	var rewards: Array[GameEffect] = [grant_item, grant_currency]
	var quest := QuestDefinition.new()
	quest.quest_id = "quest.int.bounty"
	quest.display_name = "Integration Bounty"
	quest.objectives = objectives
	quest.reward_effects = rewards
	quest.auto_complete = true

	var resources: Array[Resource] = [item, quest]
	var database := ResourceDatabase.new()
	database.database_id = "quest_int"
	database.resources = resources
	return database


func _make_player() -> Node:
	var player := Node.new()
	player.name = "Player"

	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "player"
	player.add_child(identity)

	var controllers := Node.new()
	controllers.name = "Controllers"
	player.add_child(controllers)

	var inventory := InventoryController.new()
	inventory.name = "InventoryController"
	inventory.capacity = 5
	controllers.add_child(inventory)

	_assign_owner(player, player)
	add_child_autofree(player)
	return player


func _make_enemy() -> Node:
	var enemy := Node.new()
	enemy.name = "Enemy"

	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = "enemy.marked"
	identity.tags = ["marked"]
	enemy.add_child(identity)

	var components := Node.new()
	components.name = "Components"
	enemy.add_child(components)

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.current_hp = 10.0
	components.add_child(health)

	_assign_owner(enemy, enemy)
	add_child_autofree(enemy)
	return enemy


func _assign_owner(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_assign_owner(child, owner_node)
