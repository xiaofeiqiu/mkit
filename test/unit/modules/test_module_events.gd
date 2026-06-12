extends GutTest
## Payload contracts of the per-module domain event catalogs
## (moved out of kernel EventService by the layering fix).


func test_tc_me_01_room_cleared_records_source() -> void:
	var de := WorldEvents.room_cleared("room_forest_01")
	assert_eq(de.event_type, WorldEvents.ROOM_CLEARED)
	assert_eq(de.source_id, "room_forest_01")


func test_tc_me_02_entity_died_carries_id_ref_and_identity() -> void:
	var node := _make_entity("enemy_01", "entity.enemy", "enemy", ["beast"])
	add_child_autofree(node)
	var de := CombatEvents.entity_died("enemy_01", node)
	assert_eq(de.event_type, CombatEvents.ENTITY_DIED)
	assert_eq(de.source_id, "enemy_01")
	assert_eq(de.payload.get("entity_id"), "enemy_01")
	assert_eq(de.payload.get("entity_ref"), node)
	assert_eq(de.payload.get("definition_id"), "entity.enemy")
	assert_eq(de.payload.get("faction"), "enemy")
	assert_eq(de.payload.get("tags"), ["beast"])
	assert_eq(de.payload.get("killer_id"), "")
	assert_null(de.payload.get("killer_ref"))


func test_tc_me_03_inventory_changed_payload() -> void:
	var de := InventoryEvents.inventory_changed("player", "item.herb", 3, "added")
	assert_eq(de.event_type, InventoryEvents.INVENTORY_CHANGED)
	assert_eq(de.target_id, "item.herb")
	assert_eq(de.payload.get("owner_id"), "player")
	assert_eq(de.payload.get("item_id"), "item.herb")
	assert_eq(de.payload.get("quantity"), 3)
	assert_eq(de.payload.get("change_type"), "added")


func test_tc_me_04_run_started_carries_seed() -> void:
	var de := WorldEvents.run_started("run_001", 42)
	assert_eq(de.event_type, WorldEvents.RUN_STARTED)
	assert_eq(de.source_id, "run_001")
	assert_eq(de.payload.get("seed"), 42)


func test_tc_me_05_run_finished_carries_result() -> void:
	var de := WorldEvents.run_finished("run_001", "victory")
	assert_eq(de.event_type, WorldEvents.RUN_FINISHED)
	assert_eq(de.payload.get("result"), "victory")


func test_tc_me_06_reward_selected_payload() -> void:
	var de := LootEvents.reward_selected("hp_up", "chest_01")
	assert_eq(de.event_type, LootEvents.REWARD_SELECTED)
	assert_eq(de.source_id, "chest_01")
	assert_eq(de.payload.get("reward_id"), "hp_up")


func test_tc_me_14_entity_died_carries_killer_identity() -> void:
	var enemy := _make_entity("enemy_01", "entity.enemy", "enemy", ["beast"])
	var player := _make_entity("player_01", "entity.player", "player", ["hero"])
	add_child_autofree(enemy)
	add_child_autofree(player)
	var de := CombatEvents.entity_died("enemy_01", enemy, player)
	assert_eq(de.payload.get("definition_id"), "entity.enemy")
	assert_eq(de.payload.get("faction"), "enemy")
	assert_eq(de.payload.get("tags"), ["beast"])
	assert_eq(de.payload.get("killer_id"), "player_01")
	assert_eq(de.payload.get("killer_ref"), player)
	assert_eq(de.payload.get("killer_definition_id"), "entity.player")
	assert_eq(de.payload.get("killer_faction"), "player")
	assert_eq(de.payload.get("killer_tags"), ["hero"])


func test_tc_me_15_loot_dropped_payload() -> void:
	var drop := LootDropResult.new()
	drop.entity_id = "enemy_01"
	drop.killer_id = "player_01"
	drop.rule_id = "death_loot.enemy"
	var de := LootEvents.loot_dropped(drop)
	assert_eq(de.event_type, LootEvents.LOOT_DROPPED)
	assert_eq(de.source_id, "enemy_01")
	assert_eq(de.target_id, "player_01")
	assert_eq(de.payload.get("drop"), drop)


func test_tc_me_07_damage_applied_carries_result() -> void:
	var result := DamageResult.new()
	var de := CombatEvents.damage_applied(result)
	assert_eq(de.event_type, CombatEvents.DAMAGE_APPLIED)
	assert_eq(de.payload.get("result"), result)


func test_tc_me_08_quest_accepted_payload() -> void:
	var de := QuestEvents.quest_accepted("quest.gather_herbs")
	assert_eq(de.event_type, QuestEvents.QUEST_ACCEPTED)
	assert_eq(de.payload.get("quest_id"), "quest.gather_herbs")


func test_tc_me_09_quest_objective_advanced_carries_progress() -> void:
	var de := QuestEvents.quest_objective_advanced("quest.kill", "obj.goblins", 3, 5)
	assert_eq(de.event_type, QuestEvents.QUEST_OBJECTIVE_ADVANCED)
	assert_eq(de.target_id, "obj.goblins")
	assert_eq(de.payload.get("current"), 3)
	assert_eq(de.payload.get("required"), 5)


func test_tc_me_10_quest_completed_and_turned_in() -> void:
	assert_eq(QuestEvents.quest_completed("quest.kill").event_type, QuestEvents.QUEST_COMPLETED)
	var turned := QuestEvents.quest_turned_in("quest.kill")
	assert_eq(turned.event_type, QuestEvents.QUEST_TURNED_IN)
	assert_eq(turned.payload.get("quest_id"), "quest.kill")


func test_tc_me_11_dialogue_events_payload() -> void:
	assert_eq(
		DialogueEvents.dialogue_started("dlg.elder").event_type, DialogueEvents.DIALOGUE_STARTED
	)
	assert_eq(DialogueEvents.dialogue_ended("dlg.elder").event_type, DialogueEvents.DIALOGUE_ENDED)
	var talked := DialogueEvents.npc_talked("npc.elder")
	assert_eq(talked.event_type, DialogueEvents.NPC_TALKED)
	assert_eq(talked.payload.get("npc_id"), "npc.elder")


func test_tc_me_12_zone_changed_carries_from_and_to() -> void:
	var de := WorldEvents.zone_changed("village", "field")
	assert_eq(de.event_type, WorldEvents.ZONE_CHANGED)
	assert_eq(de.payload.get("from_zone_id"), "village")
	assert_eq(de.payload.get("to_zone_id"), "field")


func test_tc_me_13_shop_events_carry_quantity() -> void:
	var bought := ShopEvents.item_purchased("shop.village", "item.potion", 2)
	assert_eq(bought.event_type, ShopEvents.ITEM_PURCHASED)
	assert_eq(bought.payload.get("quantity"), 2)
	var sold := ShopEvents.item_sold("shop.village", "item.pelt", 3)
	assert_eq(sold.event_type, ShopEvents.ITEM_SOLD)
	assert_eq(sold.payload.get("quantity"), 3)


func _make_entity(
	entity_id: String, definition_id: String, faction: String, tags: Array[String]
) -> EntityRoot:
	var entity := EntityRoot.new()
	entity.name = entity_id
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = entity_id
	identity.definition_id = definition_id
	identity.faction = faction
	identity.tags = tags
	entity.add_child(identity)
	return entity
