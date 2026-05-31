extends Node2D

# Phase 3 inventory slice — validation target:
#   Enemy drops loot on death. Player picks it up (auto).
#   Press E to equip the sword. Stats update.
#   Press R to generate 3 reward options. Press 1/2/3 to pick.
#
# Controls: WASD/Arrows = move, Space/J = melee, Q = fireball
#           E = equip sword from inventory, R = generate rewards, 1/2/3 = pick reward

@onready var player: Node = $Player
@onready var enemy: Node = $Enemy
@onready var _hp_label: Label = $HUD/StatsPanel/EnemyHP
@onready var _inv_label: Label = $HUD/StatsPanel/Inventory
@onready var _equip_label: Label = $HUD/StatsPanel/Equipped
@onready var _atk_label: Label = $HUD/StatsPanel/AttackPower
@onready var _reward_label: Label = $HUD/StatsPanel/RewardStatus
@onready var _log_label: Label = $HUD/StatsPanel/EventLog

var _loot_system := LootSystem.new()
var _reward_system := RewardSystem.new()
var _pending_rewards: Array[RewardOption] = []
var _log_lines: Array[String] = []
var _enemy_alive := true


func _ready() -> void:
	_register_content()
	_register_player_abilities()
	_connect_events()
	_log("=== Inventory Slice ===")
	_log("Move: WASD   Melee: Space/J   Fireball: Q")
	_log("E = equip sword   R = rewards   1/2/3 = pick")


func _process(_delta: float) -> void:
	_update_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				_try_equip_sword()
			KEY_R:
				_generate_rewards()
			KEY_1:
				_pick_reward(0)
			KEY_2:
				_pick_reward(1)
			KEY_3:
				_pick_reward(2)


# ── content registration ───────────────────────────────────────────────────────

func _register_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentRegistry
	if registry == null:
		push_error("Phase3: ContentRegistry not available")
		return

	# Iron Sword definition
	var sword_atk := StatModifierDefinition.new()
	sword_atk.modifier_id = "mod.sword_iron.attack"
	sword_atk.stat_id = "attack_power"
	sword_atk.operation = StatModifierDefinition.Operation.FLAT_ADD
	sword_atk.value = 8.0

	var sword := ItemDefinition.new()
	sword.item_id = "item.sword_iron"
	sword.display_name = "Iron Sword"
	sword.description = "A reliable iron sword. +8 attack."
	sword.item_type = "weapon"
	sword.rarity = "common"
	sword.stackable = false
	sword.max_stack = 1
	sword.equipment_slot = "weapon"
	sword.tags = ["weapon", "sword", "melee"]
	sword.stat_modifiers = [sword_atk]
	registry.register_resource(sword)

	# Small Potion
	var heal_eff := HealEffect.new()
	heal_eff.effect_id = "effect.potion_small_heal"
	heal_eff.base_amount = 25.0

	var potion := ItemDefinition.new()
	potion.item_id = "item.potion_small"
	potion.display_name = "Small Potion"
	potion.description = "Restores 25 HP."
	potion.item_type = "consumable"
	potion.rarity = "common"
	potion.stackable = true
	potion.max_stack = 10
	potion.use_effects = [heal_eff]
	registry.register_resource(potion)

	# Goblin loot table
	var sword_entry := LootEntry.new()
	sword_entry.content_id = "item.sword_iron"
	sword_entry.weight = 5.0
	sword_entry.min_quantity = 1
	sword_entry.max_quantity = 1

	var potion_entry := LootEntry.new()
	potion_entry.content_id = "item.potion_small"
	potion_entry.weight = 10.0
	potion_entry.min_quantity = 1
	potion_entry.max_quantity = 2

	var loot_table := LootTableDefinition.new()
	loot_table.loot_table_id = "loot.goblin_common"
	loot_table.rolls = 2
	loot_table.allow_empty = true
	loot_table.empty_weight = 3.0
	loot_table.entries = [sword_entry, potion_entry]
	registry.register_resource(loot_table)

	# Reward definitions
	var atk_effect := ApplyStatModifierEffect.new()
	atk_effect.effect_id = "reward.attack_plus_20"
	atk_effect.stat_id = "attack_power"
	atk_effect.operation = StatModifierDefinition.Operation.PERCENT_ADD
	atk_effect.value = 0.20
	atk_effect.duration = -1.0

	var atk_reward := RewardDefinition.new()
	atk_reward.reward_id = "reward.attack_plus_20"
	atk_reward.display_name = "Power Up"
	atk_reward.description = "+20% attack power"
	atk_reward.rarity = "common"
	atk_reward.weight = 10.0
	atk_reward.effects = [atk_effect]
	registry.register_resource(atk_reward)

	var hp_effect := ApplyStatModifierEffect.new()
	hp_effect.effect_id = "reward.max_hp_plus_20"
	hp_effect.stat_id = "max_hp"
	hp_effect.operation = StatModifierDefinition.Operation.FLAT_ADD
	hp_effect.value = 20.0
	hp_effect.duration = -1.0

	var hp_reward := RewardDefinition.new()
	hp_reward.reward_id = "reward.max_hp_plus_20"
	hp_reward.display_name = "Vitality"
	hp_reward.description = "+20 max HP"
	hp_reward.rarity = "common"
	hp_reward.weight = 10.0
	hp_reward.effects = [hp_effect]
	registry.register_resource(hp_reward)

	var speed_effect := ApplyStatModifierEffect.new()
	speed_effect.effect_id = "reward.move_speed_plus_15pct"
	speed_effect.stat_id = "move_speed"
	speed_effect.operation = StatModifierDefinition.Operation.PERCENT_ADD
	speed_effect.value = 0.15
	speed_effect.duration = -1.0

	var speed_reward := RewardDefinition.new()
	speed_reward.reward_id = "reward.move_speed_plus_15pct"
	speed_reward.display_name = "Swift Feet"
	speed_reward.description = "+15% move speed"
	speed_reward.rarity = "rare"
	speed_reward.weight = 6.0
	speed_reward.effects = [speed_effect]
	registry.register_resource(speed_reward)

	var def_effect := ApplyStatModifierEffect.new()
	def_effect.effect_id = "reward.defense_plus_5"
	def_effect.stat_id = "defense"
	def_effect.operation = StatModifierDefinition.Operation.FLAT_ADD
	def_effect.value = 5.0
	def_effect.duration = -1.0

	var def_reward := RewardDefinition.new()
	def_reward.reward_id = "reward.defense_plus_5"
	def_reward.display_name = "Iron Skin"
	def_reward.description = "+5 defense"
	def_reward.rarity = "common"
	def_reward.weight = 8.0
	def_reward.effects = [def_effect]
	registry.register_resource(def_reward)


func _register_player_abilities() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentRegistry
	if registry == null:
		return

	var burn_tick := DealDamageEffect.new()
	burn_tick.effect_id = "effect.burn_tick"
	burn_tick.base_amount = 5.0
	burn_tick.damage_type = "magic"
	burn_tick.element_type = "fire"
	burn_tick.can_crit = false

	var burn := StatusEffectDefinition.new()
	burn.status_id = "status.burn"
	burn.display_name = "Burn"
	burn.duration = 4.0
	burn.tick_interval = 1.0
	burn.max_stacks = 3
	burn.stack_rule = StatusEffectDefinition.StackRule.ADD_STACK
	burn.tags = ["debuff", "fire", "damage_over_time"]
	var burn_ticks: Array[GameEffect] = [burn_tick]
	burn.effects_on_tick = burn_ticks
	registry.register_resource(burn)

	var fireball_dmg := DealDamageEffect.new()
	fireball_dmg.effect_id = "effect.fireball_damage"
	fireball_dmg.base_amount = 30.0
	fireball_dmg.damage_type = "magic"
	fireball_dmg.element_type = "fire"
	fireball_dmg.can_crit = true

	var fireball_burn := ApplyStatusEffect.new()
	fireball_burn.effect_id = "effect.fireball_apply_burn"
	fireball_burn.status_id = "status.burn"
	fireball_burn.stacks = 1
	fireball_burn.duration_override = 4.0

	var fireball := AbilityDefinition.new()
	fireball.ability_id = "ability.fireball_basic"
	fireball.display_name = "Fireball"
	fireball.cooldown = 3.0
	fireball.cost_type = "mana"
	fireball.cost_amount = 15.0
	fireball.tags = ["spell", "fire"]
	var fireball_effects: Array[GameEffect] = [fireball_dmg, fireball_burn]
	fireball.effects = fireball_effects
	registry.register_resource(fireball)

	var controller := player.get_node_or_null("Controllers/AbilityController") as AbilityController
	if controller != null:
		controller.register_ability("ability.fireball_basic")


# ── events ─────────────────────────────────────────────────────────────────────

func _connect_events() -> void:
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events == null:
		return
	events.entity_died.connect(_on_entity_died)

	if player != null:
		var inv := player.get_node_or_null("Controllers/InventoryController") as InventoryController
		if inv != null:
			inv.item_added.connect(_on_item_added)

		var eq := player.get_node_or_null("Controllers/EquipmentController") as EquipmentController
		if eq != null:
			eq.equipment_changed.connect(_on_equipment_changed)


func _on_entity_died(entity_id: String, entity_ref: Node) -> void:
	_log("[DIED] %s" % entity_id)
	_enemy_alive = false

	if entity_ref == null or not is_instance_valid(entity_ref):
		return

	var ctx := GameplayContext.new()
	ctx.source = entity_ref
	ctx.target = player

	var result := _loot_system.roll_table("loot.goblin_common", ctx)

	_log("[LOOT] rolls=%d  items=%d" % [result.debug_rolls.size(), result.item_instances.size()])
	for roll_info in result.debug_rolls:
		_log("  → %s" % str(roll_info.get("result", "empty")))

	if result.item_instances.is_empty():
		_log("[LOOT] nothing dropped")
		return

	var inv := player.get_node_or_null("Controllers/InventoryController") as InventoryController
	if inv == null:
		return
	for item in result.item_instances:
		if inv.can_add_item(item):
			inv.add_item(item)
		else:
			_log("[LOOT] bag full, dropped: %s" % item.definition_id)


func _on_item_added(item: ItemInstance) -> void:
	_log("[INV] picked up %s ×%d" % [item.definition_id, item.quantity])


func _on_equipment_changed(slot_id: String, item: ItemInstance) -> void:
	if item != null:
		_log("[EQUIP] %s → %s" % [slot_id, item.definition_id])
	else:
		_log("[EQUIP] %s → empty" % slot_id)


# ── actions ────────────────────────────────────────────────────────────────────

func _try_equip_sword() -> void:
	var inv := player.get_node_or_null("Controllers/InventoryController") as InventoryController
	var eq := player.get_node_or_null("Controllers/EquipmentController") as EquipmentController
	if inv == null or eq == null:
		return

	var sword := inv.find_item_by_definition("item.sword_iron")
	if sword == null:
		_log("[EQUIP] no sword in inventory")
		return

	if eq.get_equipped("weapon") != null:
		var old := eq.unequip("weapon")
		if old != null:
			inv.add_item(old)

	if eq.equip(sword, "weapon"):
		_log("[EQUIP] sword equipped  atk=%.1f" % _get_player_stat("attack_power"))
	else:
		_log("[EQUIP] equip failed")


func _generate_rewards() -> void:
	var ctx := GameplayContext.new()
	ctx.source = player

	_pending_rewards = _reward_system.generate_options([
		"reward.attack_plus_20",
		"reward.max_hp_plus_20",
		"reward.move_speed_plus_15pct",
		"reward.defense_plus_5"
	], 3, ctx)

	_log("[REWARD] options:")
	for i in range(_pending_rewards.size()):
		var opt := _pending_rewards[i]
		_log("  %d) [%s] %s — %s" % [i + 1, opt.rarity, opt.display_name, opt.description])

	_reward_label.text = "Rewards ready — press 1 / 2 / 3 to pick"


func _pick_reward(index: int) -> void:
	if index >= _pending_rewards.size():
		_log("[REWARD] invalid choice %d" % (index + 1))
		return

	var option := _pending_rewards[index]
	var ctx := GameplayContext.new()
	ctx.source = player

	if _reward_system.apply_selected(option, ctx):
		_log("[REWARD] applied: %s  atk=%.1f  hp=%.1f  spd=%.1f" % [
			option.display_name,
			_get_player_stat("attack_power"),
			_get_player_stat("max_hp"),
			_get_player_stat("move_speed")
		])
		_pending_rewards.clear()
		_reward_label.text = "Reward applied: %s" % option.display_name
	else:
		_log("[REWARD] apply failed")


# ── HUD ────────────────────────────────────────────────────────────────────────

func _update_hud() -> void:
	if enemy != null and is_instance_valid(enemy) and _enemy_alive:
		var health := enemy.get_node_or_null("Components/HealthComponent") as HealthComponent
		if health != null:
			_hp_label.text = "Enemy HP: %.0f / %.0f" % [health.current_hp, health.get_max_hp()]
	else:
		_hp_label.text = "Enemy: dead"

	_atk_label.text = "Attack: %.1f  MaxHP: %.1f  Speed: %.1f  Def: %.1f" % [
		_get_player_stat("attack_power"),
		_get_player_stat("max_hp"),
		_get_player_stat("move_speed"),
		_get_player_stat("defense")
	]

	var inv := player.get_node_or_null("Controllers/InventoryController") as InventoryController
	if inv != null:
		var items := inv.model.get_items()
		var parts: Array[String] = []
		for item in items:
			parts.append("%s×%d" % [item.definition_id.replace("item.", ""), item.quantity])
		_inv_label.text = "Bag: [%s]" % ", ".join(parts) if parts.size() > 0 else "Bag: empty"

	var eq := player.get_node_or_null("Controllers/EquipmentController") as EquipmentController
	if eq != null:
		var weapon := eq.get_equipped("weapon")
		_equip_label.text = "Weapon: %s" % (weapon.definition_id.replace("item.", "") if weapon != null else "none")


# ── helpers ────────────────────────────────────────────────────────────────────

func _get_player_stat(stat_id: String) -> float:
	if player == null:
		return 0.0
	var stats := player.get_node_or_null("Components/StatsComponent") as StatsComponent
	if stats == null:
		return 0.0
	return stats.get_stat_value(stat_id)


func _log(line: String) -> void:
	print(line)
	_log_lines.append(line)
	if _log_lines.size() > 6:
		_log_lines.pop_front()
	if _log_label != null:
		_log_label.text = "\n".join(_log_lines)
