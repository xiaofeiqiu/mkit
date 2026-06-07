extends GutTest


class StubContent:
	extends ContentService
	var _defs: Dictionary = {}

	func get_resource(id: String) -> Resource:
		return _defs.get(id, null)


class SourceProbeEffect:
	extends GameEffect
	var last_source: Node = null
	var last_payload: Dictionary = {}

	func _apply_impl(context: GameplayContext) -> EffectResult:
		last_source = context.source
		last_payload = context.payload.duplicate(true)
		return EffectResult.ok(effect_id)


var content: StubContent


func before_each() -> void:
	content = StubContent.new()
	add_child_autofree(content)
	ServiceRegistry.register_service("content", content)
	ServiceRegistry.register_service("effects", EffectService.new())


func after_each() -> void:
	ServiceRegistry.clear()


func test_tc_svc_01_p1a_components_use_saveable_component_base() -> void:
	var nodes: Array[Node] = [
		HealthComponent.new(),
		StatsComponent.new(),
		ResourcePoolComponent.new(),
		StatusEffectController.new(),
		AbilityController.new(),
		InventoryController.new(),
		EquipmentController.new()
	]
	for node in nodes:
		node.name = node.get_script().resource_path.get_file().get_basename().to_pascal_case()
		assert_true(node is SaveableComponent)
		assert_false(node is Saveable)
		assert_eq((node as SaveableComponent).get_save_key(), node.name)
		node.free()


func test_tc_svc_17_global_systems_use_saveable_base() -> void:
	var nodes: Array[Node] = [
		ProgressionService.new(),
		QuestService.new(),
		AudioService.new()
	]
	for node in nodes:
		assert_true(node is Saveable)
		assert_false(node is SaveableComponent)
		node.free()


func test_tc_svc_02_health_roundtrip_clamps_current_hp_after_stats_restore() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity, {"max_hp": 50.0})
	var health := _add_health(entity, 10.0)
	add_child_autofree(entity)
	assert_eq(stats.get_stat_value("max_hp"), 50.0)
	health.from_save_data({"current_hp": 80.0, "dead": false})
	assert_eq(health.current_hp, 50.0)
	assert_false(health.dead)
	health.from_save_data({"current_hp": 20.0, "dead": true})
	assert_eq(health.current_hp, 0.0)
	assert_true(health.dead)


func test_tc_svc_03_stats_roundtrip_persists_base_overrides_and_permanent_modifiers() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity)
	add_child_autofree(entity)
	stats.set_base_stat("attack_power", 15.0)
	stats.add_modifier(_make_modifier("mod.permanent.attack", "attack_power", 5.0, -1.0))
	stats.add_modifier(_make_modifier("mod.temp.attack", "attack_power", 100.0, 3.0))
	var data := stats.to_save_data()
	assert_eq(data["base_overrides"]["attack_power"], 15.0)
	assert_eq((data["persistent_modifiers"] as Array).size(), 1)
	assert_eq((data["persistent_modifiers"] as Array)[0]["modifier_id"], "mod.permanent.attack")
	var restored_entity := _make_entity("Restored", "player_002")
	var restored := _add_stats(restored_entity)
	add_child_autofree(restored_entity)
	restored.from_save_data(data)
	assert_eq(restored.get_stat_value("attack_power"), 20.0)
	var restored_modifiers: Array = restored.modifiers_by_stat.get("attack_power", [])
	assert_eq(restored_modifiers.size(), 1)


func test_tc_svc_11_stats_load_resets_missing_base_overrides_to_baseline() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity, {"attack_power": 24.0})
	add_child_autofree(entity)
	var data := stats.to_save_data()
	assert_true((data["base_overrides"] as Dictionary).is_empty())
	stats.set_base_stat("attack_power", 1.0)
	assert_eq(stats.get_stat_value("attack_power"), 1.0)
	stats.from_save_data(data)
	assert_eq(stats.get_stat_value("attack_power"), 24.0)


func test_tc_svc_12_stats_load_replaces_persistent_modifiers() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity)
	add_child_autofree(entity)
	stats.add_modifier(_make_modifier("mod.permanent.attack", "attack_power", 5.0, -1.0))
	var data := stats.to_save_data()

	stats.add_modifier(_make_modifier("mod.stale.attack", "attack_power", 100.0, -1.0))
	assert_gt(stats.get_stat_value("attack_power"), 100.0)
	stats.from_save_data(data)

	assert_eq(stats.get_stat_value("attack_power"), 15.0)
	var restored_modifiers: Array = stats.modifiers_by_stat.get("attack_power", [])
	assert_eq(restored_modifiers.size(), 1)
	assert_eq((restored_modifiers[0] as StatModifier).modifier_id, "mod.permanent.attack")


func test_tc_svc_04_resource_pool_roundtrip_preserves_current_values() -> void:
	var entity := _make_entity("Player", "player_001")
	_add_stats(entity, {"max_mana": 100.0})
	var pool := _add_resource_pool(entity, {"mana": 80.0})
	add_child_autofree(entity)
	pool.spend("mana", 35.0)
	var data := pool.to_save_data()
	var restored_entity := _make_entity("Restored", "player_002")
	_add_stats(restored_entity, {"max_mana": 100.0})
	var restored := _add_resource_pool(restored_entity)
	add_child_autofree(restored_entity)
	restored.from_save_data(data)
	assert_eq(restored.get_current("mana"), 45.0)


func test_tc_svc_05_status_effect_roundtrip_restores_active_state_and_stat_modifier() -> void:
	content._defs["status.weak"] = _make_status("status.weak", "defense", -2.0)
	var source := _make_entity("Caster", "caster_001")
	var entity := _make_entity("Target", "target_001")
	var stats := _add_stats(entity)
	var status := _add_status(entity)
	add_child_autofree(source)
	add_child_autofree(entity)
	assert_true(status.apply_status("status.weak", source, 2, 4.5))
	var data := status.to_save_data()
	assert_eq((data["active"] as Array)[0]["source_id"], "caster_001")
	var restored_entity := _make_entity("Restored", "target_002")
	var restored_stats := _add_stats(restored_entity)
	var restored_status := _add_status(restored_entity)
	add_child_autofree(restored_entity)
	restored_status.from_save_data(data)
	assert_true(restored_status.has_status("status.weak"))
	var instance := restored_status.active_statuses["status.weak"] as StatusEffectInstance
	assert_eq(instance.stacks, 2)
	assert_almost_eq(instance.remaining_duration, 4.5, 0.001)
	assert_eq(instance.source_id, "caster_001")
	assert_eq(restored_stats.get_stat_value("defense"), -2.0)


func test_tc_svc_06_ability_roundtrip_restores_learned_ids_and_cooldowns() -> void:
	content._defs["ability.dash"] = _make_ability("ability.dash", 3.0, 3)
	content._defs["ability.strike"] = _make_ability("ability.strike", 0.0)
	var entity := _make_entity("Player", "player_001")
	var ability := _add_ability(entity)
	add_child_autofree(entity)
	assert_true(ability.register_ability("ability.dash"))
	assert_true(ability.register_ability("ability.strike"))
	(ability.abilities["ability.dash"] as AbilityInstance).cooldown_remaining = 1.25
	(ability.abilities["ability.dash"] as AbilityInstance).current_charges = 2
	(ability.abilities["ability.dash"] as AbilityInstance).set_recharge_duration(3.0)
	var data := ability.to_save_data()
	assert_eq(data["learned"], ["ability.dash", "ability.strike"])
	assert_eq(data["cooldowns"]["ability.dash"], 1.25)
	assert_eq(data["charges"]["ability.dash"], 2)
	assert_eq(data["recharge_durations"]["ability.dash"], 3.0)
	var restored_entity := _make_entity("Restored", "player_002")
	var restored := _add_ability(restored_entity)
	add_child_autofree(restored_entity)
	restored.from_save_data(data)
	assert_true(restored.has_ability("ability.dash"))
	assert_true(restored.has_ability("ability.strike"))
	assert_almost_eq(restored.get_cooldown_remaining("ability.dash"), 1.25, 0.001)
	assert_true(restored.is_cooldown_ready("ability.dash"))
	assert_eq((restored.abilities["ability.dash"] as AbilityInstance).current_charges, 2)


func test_tc_svc_09_ability_roundtrip_continues_multi_charge_recharge() -> void:
	content._defs["ability.blink"] = _make_ability("ability.blink", 4.0, 3)
	var entity := _make_entity("Player", "player_001")
	var ability := _add_ability(entity)
	add_child_autofree(entity)
	assert_true(ability.register_ability("ability.blink"))
	var instance := ability.abilities["ability.blink"] as AbilityInstance
	instance.current_charges = 1
	instance.cooldown_remaining = 0.5
	instance.set_recharge_duration(4.0)
	var data := ability.to_save_data()
	var restored_entity := _make_entity("Restored", "player_002")
	var restored := _add_ability(restored_entity)
	add_child_autofree(restored_entity)
	restored.from_save_data(data)
	restored._process(0.6)
	var restored_instance := restored.abilities["ability.blink"] as AbilityInstance
	assert_eq(restored_instance.current_charges, 2)
	assert_almost_eq(restored_instance.cooldown_remaining, 4.0, 0.001)


func test_tc_svc_07_inventory_roundtrip_preserves_item_payload() -> void:
	content._defs["item.key"] = _make_item("item.key", "", true, 9)
	var entity := _make_entity("Player", "player_001")
	var inventory := _add_inventory(entity, 4)
	add_child_autofree(entity)
	assert_true(inventory.add_item(ItemInstance.create("item.key", 3)))
	var data := inventory.to_save_data()
	var restored_entity := _make_entity("Restored", "player_002")
	var restored := _add_inventory(restored_entity, 1)
	add_child_autofree(restored_entity)
	restored.from_save_data(data)
	assert_eq(restored.capacity, 4)
	assert_eq(restored.find_item_by_definition("item.key").quantity, 3)


func test_tc_svc_08_equipment_roundtrip_restores_slots_and_affix_modifiers() -> void:
	var static_mod := _make_modifier_definition("mod.weapon.attack", "attack_power", 3.0)
	var item_def := _make_item("item.blade", "weapon", false, 1)
	item_def.stat_modifiers = [static_mod]
	content._defs["item.blade"] = item_def
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity)
	var equipment := _add_equipment(entity)
	add_child_autofree(entity)
	var item := ItemInstance.create("item.blade", 1)
	item.instance_id = "blade_001"
	item.rolled_affixes.append(_make_modifier("mod.rolled.crit", "crit_chance", 0.1, -1.0))
	assert_true(equipment.equip(item, "weapon"))
	var data := equipment.to_save_data()
	assert_eq((data["slots"]["weapon"]["rolled_affixes"] as Array).size(), 1)
	var restored_entity := _make_entity("Restored", "player_002")
	var restored_stats := _add_stats(restored_entity)
	var restored_equipment := _add_equipment(restored_entity)
	add_child_autofree(restored_entity)
	restored_equipment.from_save_data(data)
	var restored_item := restored_equipment.get_equipped("weapon")
	assert_not_null(restored_item)
	assert_eq(restored_item.instance_id, "blade_001")
	assert_eq(restored_item.rolled_affixes.size(), 1)
	assert_eq(restored_stats.get_stat_value("attack_power"), 13.0)
	assert_almost_eq(restored_stats.get_stat_value("crit_chance"), 0.15, 0.001)
	assert_eq(stats.get_stat_value("attack_power"), 13.0)


func test_tc_svc_10_status_restore_rebinds_source_for_tick_effects() -> void:
	var probe := SourceProbeEffect.new()
	content._defs["status.mark"] = _make_status("status.mark", "defense", -1.0)
	(content._defs["status.mark"] as StatusEffectDefinition).tick_interval = 1.0
	(content._defs["status.mark"] as StatusEffectDefinition).effects_on_tick = [probe]
	var source := _make_entity("Caster", "caster_001")
	var entity := _make_entity("Target", "target_001")
	var status := _add_status(entity)
	add_child_autofree(source)
	add_child_autofree(entity)
	assert_true(status.apply_status("status.mark", source, 1, 5.0))
	var data := status.to_save_data()
	var restored_entity := _make_entity("Restored", "target_002")
	_add_stats(restored_entity)
	var restored_status := _add_status(restored_entity)
	add_child_autofree(restored_entity)
	restored_status.from_save_data(data)
	restored_status._process(1.1)
	assert_eq(probe.last_source, source)
	assert_eq(probe.last_payload.get("source_id"), "caster_001")


func test_tc_svc_13_stats_highest_only_rejects_lower_value() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity)
	add_child_autofree(entity)
	var high := _make_modifier("mod.boost", "attack_power", 20.0, -1.0)
	high.stacking_rule = StatModifierDefinition.StackingRule.HIGHEST_ONLY
	var low := _make_modifier("mod.boost", "attack_power", 5.0, -1.0)
	low.stacking_rule = StatModifierDefinition.StackingRule.HIGHEST_ONLY
	stats.add_modifier(high)
	stats.add_modifier(low)
	var list: Array = stats.modifiers_by_stat.get("attack_power", [])
	assert_eq(list.size(), 1)
	assert_eq((list[0] as StatModifier).value, 20.0)


func test_tc_svc_14_stats_highest_only_replaces_lower_with_higher_value() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity)
	add_child_autofree(entity)
	var low := _make_modifier("mod.boost", "attack_power", 5.0, -1.0)
	low.stacking_rule = StatModifierDefinition.StackingRule.HIGHEST_ONLY
	var high := _make_modifier("mod.boost", "attack_power", 20.0, -1.0)
	high.stacking_rule = StatModifierDefinition.StackingRule.HIGHEST_ONLY
	stats.add_modifier(low)
	stats.add_modifier(high)
	var list: Array = stats.modifiers_by_stat.get("attack_power", [])
	assert_eq(list.size(), 1)
	assert_eq((list[0] as StatModifier).value, 20.0)


func test_tc_svc_15_stats_lowest_only_rejects_higher_value() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity)
	add_child_autofree(entity)
	var low := _make_modifier("mod.debuff", "defense", -10.0, -1.0)
	low.stacking_rule = StatModifierDefinition.StackingRule.LOWEST_ONLY
	var high := _make_modifier("mod.debuff", "defense", -2.0, -1.0)
	high.stacking_rule = StatModifierDefinition.StackingRule.LOWEST_ONLY
	stats.add_modifier(low)
	stats.add_modifier(high)
	var list: Array = stats.modifiers_by_stat.get("defense", [])
	assert_eq(list.size(), 1)
	assert_eq((list[0] as StatModifier).value, -10.0)


func test_tc_svc_16_stats_lowest_only_replaces_higher_with_lower_value() -> void:
	var entity := _make_entity("Player", "player_001")
	var stats := _add_stats(entity)
	add_child_autofree(entity)
	var high := _make_modifier("mod.debuff", "defense", -2.0, -1.0)
	high.stacking_rule = StatModifierDefinition.StackingRule.LOWEST_ONLY
	var low := _make_modifier("mod.debuff", "defense", -10.0, -1.0)
	low.stacking_rule = StatModifierDefinition.StackingRule.LOWEST_ONLY
	stats.add_modifier(high)
	stats.add_modifier(low)
	var list: Array = stats.modifiers_by_stat.get("defense", [])
	assert_eq(list.size(), 1)
	assert_eq((list[0] as StatModifier).value, -10.0)


func _make_entity(entity_name: String, entity_id: String) -> Node:
	var entity := Node.new()
	entity.name = entity_name
	var identity := EntityIdentity.new()
	identity.name = "EntityIdentity"
	identity.entity_id = entity_id
	entity.add_child(identity)
	var components := Node.new()
	components.name = "Components"
	entity.add_child(components)
	var controllers := Node.new()
	controllers.name = "Controllers"
	entity.add_child(controllers)
	_assign_owner(entity, entity)
	return entity


func _assign_owner(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_assign_owner(child, owner_node)


func _add_stats(entity: Node, base_stats: Dictionary = {}) -> StatsComponent:
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	if not base_stats.is_empty():
		stats.base_stats = base_stats.duplicate(true)
	entity.get_node("Components").add_child(stats)
	stats.owner = entity
	return stats


func _add_health(entity: Node, current_hp: float) -> HealthComponent:
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.current_hp = current_hp
	entity.get_node("Components").add_child(health)
	health.owner = entity
	return health


func _add_resource_pool(entity: Node, starting_values: Dictionary = {}) -> ResourcePoolComponent:
	var pool := ResourcePoolComponent.new()
	pool.name = "ResourcePoolComponent"
	pool.starting_values = starting_values.duplicate(true)
	entity.get_node("Components").add_child(pool)
	pool.owner = entity
	return pool


func _add_status(entity: Node) -> StatusEffectController:
	var status := StatusEffectController.new()
	status.name = "StatusEffectController"
	entity.get_node("Controllers").add_child(status)
	status.owner = entity
	return status


func _add_ability(entity: Node) -> AbilityController:
	var ability := AbilityController.new()
	ability.name = "AbilityController"
	entity.get_node("Controllers").add_child(ability)
	ability.owner = entity
	return ability


func _add_inventory(entity: Node, capacity: int) -> InventoryController:
	var inventory := InventoryController.new()
	inventory.name = "InventoryController"
	inventory.capacity = capacity
	entity.get_node("Controllers").add_child(inventory)
	inventory.owner = entity
	return inventory


func _add_equipment(entity: Node) -> EquipmentController:
	var equipment := EquipmentController.new()
	equipment.name = "EquipmentController"
	entity.get_node("Controllers").add_child(equipment)
	equipment.owner = entity
	return equipment


func _make_modifier(
	modifier_id: String, stat_id: String, value: float, duration: float
) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.modifier_id = modifier_id
	modifier.stat_id = stat_id
	modifier.source_id = "test_source"
	modifier.operation = StatModifierDefinition.Operation.FLAT_ADD
	modifier.value = value
	modifier.stacking_rule = StatModifierDefinition.StackingRule.STACK
	modifier.remaining_duration = duration
	return modifier


func _make_modifier_definition(
	modifier_id: String, stat_id: String, value: float
) -> StatModifierDefinition:
	var modifier := StatModifierDefinition.new()
	modifier.modifier_id = modifier_id
	modifier.stat_id = stat_id
	modifier.operation = StatModifierDefinition.Operation.FLAT_ADD
	modifier.value = value
	modifier.stacking_rule = StatModifierDefinition.StackingRule.STACK
	return modifier


func _make_status(status_id: String, stat_id: String, value: float) -> StatusEffectDefinition:
	var status := StatusEffectDefinition.new()
	status.status_id = status_id
	status.duration = 6.0
	status.tick_interval = 0.0
	status.max_stacks = 3
	status.stat_modifiers = [_make_modifier_definition("mod.%s" % status_id, stat_id, value)]
	return status


func _make_ability(ability_id: String, cooldown: float, charges: int = 1) -> AbilityDefinition:
	var ability := AbilityDefinition.new()
	ability.ability_id = ability_id
	ability.cooldown = cooldown
	ability.charges = charges
	ability.cost_type = "none"
	ability.effects = []
	ability.conditions = []
	return ability


func _make_item(
	item_id: String, equipment_slot: String, stackable: bool, max_stack: int
) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.item_id = item_id
	item.equipment_slot = equipment_slot
	item.stackable = stackable
	item.max_stack = max_stack
	return item
