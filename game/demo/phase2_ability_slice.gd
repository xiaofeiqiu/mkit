extends Node2D

# Phase 2 ability slice — validation target:
#   Player casts fireball (Q). Fireball damages enemy. Burn ticks every second.
#   Cooldown blocks repeated cast.
#
# Controls: WASD/Arrows = move, Space/J = melee, Q = fireball

@onready var player: Node = $Player
@onready var enemy: Node = $Enemy


func _ready() -> void:
	_register_content()
	_register_player_abilities()
	_connect_events()

	print("=== Ability Slice ===")
	print("Move: WASD / Arrows    Melee: Space / J    Fireball: Q")
	print("Fireball deals 30 magic dmg + applies Burn (5 fire/s for 4s, 3s cooldown).")


func _register_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentRegistry
	if registry == null:
		push_error("Phase2: ContentRegistry not available")
		return

	# Burn status: 4s, ticks every 1s for 5 magic fire damage, stacks up to 3
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

	# Fireball: 30 magic fire damage, also applies burn
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


func _register_player_abilities() -> void:
	if player == null:
		return
	var controller := player.get_node_or_null("Controllers/AbilityController") as AbilityController
	if controller == null:
		push_error("Phase2: player has no AbilityController")
		return
	controller.register_ability("ability.fireball_basic")
	controller.cooldown_started.connect(_on_cooldown_started)
	controller.ability_failed.connect(_on_ability_failed)


func _connect_events() -> void:
	var events := ServiceRegistry.get_service("events") as EventRouter
	if events == null:
		return
	events.damage_applied.connect(_on_damage_applied)
	events.entity_died.connect(_on_entity_died)

	if enemy != null:
		var sec := enemy.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
		if sec != null:
			sec.status_applied.connect(_on_status_applied)
			sec.status_ticked.connect(_on_status_ticked)
			sec.status_removed.connect(_on_status_removed)


func _on_damage_applied(result) -> void:
	if result == null:
		return
	print("[EVENT] damage_applied -> %.1f %s dmg to %s (crit=%s)" % [
		result.final_amount,
		result.damage_type,
		_node_name(result.target),
		str(result.was_critical)
	])


func _on_entity_died(entity_id: String, _ref: Node) -> void:
	print("[EVENT] entity_died -> %s" % entity_id)


func _on_cooldown_started(ability_id: String, duration: float) -> void:
	print("[ABILITY] cooldown started: %s (%.1fs)" % [ability_id, duration])


func _on_ability_failed(ability_id: String, reason: String) -> void:
	print("[ABILITY] cast failed: %s — %s" % [ability_id, reason])


func _on_status_applied(status_id: String, stacks: int) -> void:
	print("[STATUS] applied: %s (stacks=%d)" % [status_id, stacks])


func _on_status_ticked(status_id: String) -> void:
	print("[STATUS] tick: %s" % status_id)


func _on_status_removed(status_id: String) -> void:
	print("[STATUS] removed: %s" % status_id)


func _node_name(n: Node) -> String:
	return str(n.name) if n != null else "?"
