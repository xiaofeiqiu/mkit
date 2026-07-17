class_name DemoSavePayloadVerifier
extends RefCounted


const QUEST_ID := "quest.demo.field_report"
const QUEST_OBJECTIVE_ID := "obj.demo.kill_field_beast"
const QUEST_MANUAL_ID := "quest.demo.supply_request"
const QUEST_MANUAL_OBJECTIVE_ID := "obj.demo.receive_supply_note"
const ITEM_POTION := "item.demo.herb_potion"
const ITEM_CLAW := "item.demo.beast_claw"
const ITEM_CHARM := "item.demo.village_charm"
const ITEM_FIELD_BLADE := "item.demo.field_blade"
const WEAPON_SLOT := "weapon"
const ABILITY_FIREBOLT := "ability.demo.firebolt"
const REWARD_TRIAL_ATTACK := "reward.demo.trial_attack"
const UPGRADE_TRIAL_ATTACK := "upgrade.demo.trial_attack"
const PLAYER_ID := "player_001"
const TRIAL_SEED := 8606


func roundtrip(host) -> void:
	host._demo_save_roundtrip_succeeded = false
	host._demo_save_payload_verified = false
	if not host._save_demo_state():
		return
	var saved_data := _read_save_data(host)
	host._demo_save_payload_verified = validate(saved_data, "SAVE", host)
	_scramble_saved_state(host)
	await host.get_tree().process_frame
	if host._load_demo_state():
		host._demo_save_roundtrip_succeeded = (
			host._demo_save_payload_verified and _roundtrip_restored(host)
		)
		if host._demo_save_roundtrip_succeeded:
			host._log("[SAVE] round-trip restored demo state")
		else:
			host._log("[SAVE] round-trip restore check failed")


func validate(data: Dictionary, label: String, host = null) -> bool:
	var missing := missing_requirements(data)
	if missing.is_empty():
		return true
	if host != null:
		host._log("[%s] save data missing: %s" % [label, ", ".join(missing)])
	return false


func missing_requirements(data: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	if data.is_empty():
		missing.append("save_data")
		return missing
	if int(data.get("save_version", 0)) <= 0:
		missing.append("save_version")
	var roots := _dict_value(data, "roots")
	if roots.is_empty():
		missing.append("roots")
	var entities := _dict_value(data, "entities")
	if not entities.has(PLAYER_ID):
		missing.append("entities")
	var scopes := _dict_value(data, "scopes")
	if (
		not scopes.has("global")
		or not scopes.has("world.run")
		or not scopes.has("world.room")
		or not scopes.has("world.reward")
	):
		missing.append("scopes")
	var global_scope := _dict_value(scopes, "global")
	if (
		not global_scope.has("player_experience")
		or not global_scope.has("progression")
		or not global_scope.has("quest")
	):
		missing.append("global_scope")
	_append_saved_player_requirements(entities, roots, missing)
	_append_saved_quest_requirements(roots, missing)
	_append_saved_progression_requirements(roots, missing)
	_append_saved_trial_scope_requirements(scopes, missing)
	return missing


func _read_save_data(host) -> Dictionary:
	var save_manager := host._save_manager as SaveService
	if save_manager == null:
		return {}
	var file := FileAccess.open(save_manager.save_path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	return data


func _scramble_saved_state(host) -> void:
	var equipment := host._equipment_controller() as EquipmentController
	if equipment != null:
		equipment.unequip(WEAPON_SLOT)
	var inventory := host._inventory() as InventoryController
	if inventory != null:
		inventory.model.setup(inventory.capacity)
	var stats := host._player_stats() as StatsComponent
	if stats != null:
		var modifier_definition := StatModifierDefinition.new()
		modifier_definition.modifier_id = "mod.demo.save_scramble_attack"
		modifier_definition.stat_id = "attack_power"
		modifier_definition.value = -999.0
		modifier_definition.stacking_rule = StatModifierDefinition.StackingRule.REPLACE_SAME_SOURCE
		stats.add_modifier(StatModifier.from_definition(modifier_definition, "demo_save_scramble"))
	var health := host._player_health() as HealthComponent
	if health != null:
		health.current_hp = 1.0
	var pool := host._player.get_component("ResourcePoolComponent") as ResourcePoolComponent
	if pool != null:
		pool.set_current("mana", 0.0)
	var ability := host._ability_controller() as AbilityController
	if ability != null:
		ability.unregister_ability(ABILITY_FIREBOLT)
	host._field_blade_equipped = false


func _roundtrip_restored(host) -> bool:
	var equipment := host._equipment_controller() as EquipmentController
	if equipment == null or equipment.get_equipped(WEAPON_SLOT) == null:
		host._log("[SAVE] round-trip missing equipped weapon")
		return false
	var inventory := host._inventory() as InventoryController
	if inventory == null or inventory.find_item_by_definition(ITEM_POTION) == null:
		host._log("[SAVE] round-trip missing potion")
		return false
	var ability := host._ability_controller() as AbilityController
	if ability == null or not ability.has_ability(ABILITY_FIREBOLT):
		host._log("[SAVE] round-trip missing firebolt")
		return false
	var pool := host._player.get_component("ResourcePoolComponent") as ResourcePoolComponent
	if pool == null or pool.get_current("mana") <= 0.0:
		host._log("[SAVE] round-trip missing mana")
		return false
	var stats := host._player_stats() as StatsComponent
	if stats == null or stats.get_stat_value("attack_power", 0.0) < 30.0:
		host._log("[SAVE] round-trip attack_power below gate")
		return false
	return true


func _append_saved_player_requirements(
	entities: Dictionary, roots: Dictionary, missing: Array[String]
) -> void:
	var player_record := _dict_value(entities, PLAYER_ID)
	var components := _dict_value(player_record, "components")
	var position_payload := _dict_value(components, "Position")
	if position_payload.is_empty():
		missing.append("saved_player_position")
	var inventory_payload := _dict_value(components, "InventoryController")
	var saved_items := _array_value(inventory_payload, "items")
	if int(inventory_payload.get("capacity", 0)) < 20:
		missing.append("saved_inventory_capacity")
	if _saved_item_count(saved_items, ITEM_CHARM) < 1:
		missing.append("saved_charm")
	if _saved_item_count(saved_items, ITEM_FIELD_BLADE) < 1:
		missing.append("saved_field_blade")
	if _saved_item_count(saved_items, ITEM_POTION) < 1:
		missing.append("saved_potion")
	if _saved_item_count(saved_items, ITEM_CLAW) > 0:
		missing.append("saved_claw_sold")
	var equipment_payload := _dict_value(components, "EquipmentController")
	var slots := _dict_value(equipment_payload, "slots")
	var weapon := _dict_value(slots, WEAPON_SLOT)
	if str(weapon.get("definition_id", "")) != ITEM_FIELD_BLADE:
		missing.append("saved_equipped_weapon")
	var ability_payload := _dict_value(components, "AbilityController")
	if not _array_has_string(_array_value(ability_payload, "learned"), ABILITY_FIREBOLT):
		missing.append("saved_firebolt")
	if float(_dict_value(ability_payload, "charges").get(ABILITY_FIREBOLT, 0.0)) < 1.0:
		missing.append("saved_firebolt_charge")
	var resource_payload := _dict_value(components, "ResourcePoolComponent")
	if float(resource_payload.get("mana", 0.0)) <= 0.0:
		missing.append("saved_mana")
	var health_payload := _dict_value(components, "HealthComponent")
	if bool(health_payload.get("dead", true)):
		missing.append("saved_alive")
	if float(health_payload.get("current_hp", 0.0)) <= 50.0:
		missing.append("saved_potion_heal")
	var stats_payload := _dict_value(components, "StatsComponent")
	var modifiers := _array_value(stats_payload, "persistent_modifiers")
	if _saved_modifier_count(modifiers, "effect.demo.trial_attack_upgrade") < 3:
		missing.append("saved_trial_attack_modifiers")
	if _saved_modifier_count(modifiers, "effect.demo.elder_blessing_attack") < 1:
		missing.append("saved_elder_blessing")
	var experience_payload := _dict_value(roots, "player_experience")
	if int(experience_payload.get("current_level", 0)) < 2:
		missing.append("saved_level")


func _append_saved_quest_requirements(payload: Dictionary, missing: Array[String]) -> void:
	var quest_payload := _dict_value(payload, "quest")
	var states := _dict_value(quest_payload, "states")
	if _saved_quest_status(states, QUEST_ID) != "turned_in":
		missing.append("saved_field_report")
	if _saved_quest_status(states, QUEST_MANUAL_ID) != "turned_in":
		missing.append("saved_manual_quest")
	var field_state := _dict_value(states, QUEST_ID)
	var field_progress := _dict_value(field_state, "objective_progress")
	if int(field_progress.get(QUEST_OBJECTIVE_ID, 0)) < 1:
		missing.append("saved_field_objective")
	var manual_state := _dict_value(states, QUEST_MANUAL_ID)
	var manual_progress := _dict_value(manual_state, "objective_progress")
	if int(manual_progress.get(QUEST_MANUAL_OBJECTIVE_ID, 0)) < 1:
		missing.append("saved_manual_objective")


func _append_saved_progression_requirements(payload: Dictionary, missing: Array[String]) -> void:
	var progression_payload := _dict_value(payload, "progression")
	var currencies := _dict_value(progression_payload, "currencies")
	var saved_gold := int(currencies.get("gold", -1))
	if saved_gold < 0:
		missing.append("saved_gold")


func _append_saved_trial_scope_requirements(scopes: Dictionary, missing: Array[String]) -> void:
	var world_run := _dict_value(_dict_value(scopes, "world.run"), "run_director")
	var run_state := _dict_value(world_run, "run_state")
	if str(run_state.get("status", "")) != "completed":
		missing.append("saved_trial_completed")
	if int(run_state.get("seed", 0)) != TRIAL_SEED:
		missing.append("saved_trial_seed")
	if _array_value(run_state, "room_history").size() != 3:
		missing.append("saved_trial_rooms")
	var reward_history := _array_value(run_state, "reward_history")
	if reward_history.size() != 3 or _array_string_count(reward_history, REWARD_TRIAL_ATTACK) != 3:
		missing.append("saved_trial_rewards")
	if not _array_has_string(_array_value(run_state, "temporary_upgrade_ids"), UPGRADE_TRIAL_ATTACK):
		missing.append("saved_trial_upgrade")
	var world_reward := _dict_value(_dict_value(scopes, "world.reward"), "run_director")
	var scoped_rewards := _array_value(world_reward, "reward_history")
	if scoped_rewards.size() != 3 or _array_string_count(scoped_rewards, REWARD_TRIAL_ATTACK) != 3:
		missing.append("saved_reward_scope")
	var world_room := _dict_value(_dict_value(scopes, "world.room"), "run_director")
	var room_runtime := _dict_value(world_room, "current_room_runtime")
	if not bool(room_runtime.get("cleared", false)):
		missing.append("saved_room_scope")


func _dict_value(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	if value is Dictionary:
		return value
	return {}


func _array_value(data: Dictionary, key: String) -> Array:
	var value: Variant = data.get(key, [])
	if value is Array:
		return value
	return []


func _array_has_string(values: Array, expected: String) -> bool:
	for value in values:
		if str(value) == expected:
			return true
	return false


func _array_string_count(values: Array, expected: String) -> int:
	var count := 0
	for value in values:
		if str(value) == expected:
			count += 1
	return count


func _saved_item_count(items: Array, definition_id: String) -> int:
	var total := 0
	for raw in items:
		if raw is Dictionary:
			var item_data: Dictionary = raw
			if str(item_data.get("definition_id", "")) == definition_id:
				total += int(item_data.get("quantity", 0))
	return total


func _saved_modifier_count(modifiers: Array, modifier_id: String) -> int:
	var total := 0
	for raw in modifiers:
		if raw is Dictionary:
			var modifier_data: Dictionary = raw
			if str(modifier_data.get("modifier_id", "")) == modifier_id:
				total += 1
	return total


func _saved_quest_status(states: Dictionary, quest_id: String) -> String:
	var state := _dict_value(states, quest_id)
	return str(state.get("status", ""))
