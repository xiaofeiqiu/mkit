extends Node2D

# Phase 2 ability slice — validation target:
#   Player casts fireball (Q). Fireball damages enemy. Burn ticks every second.
#   Cooldown blocks repeated cast.
#
# Controls: WASD/Arrows = move, Space/J = melee, Q = fireball

@onready var player: Node = $Player
@onready var enemy: Node = $Enemy
@onready var _hp_label: Label = $HUD/StatsPanel/EnemyHP
@onready var _mana_label: Label = $HUD/StatsPanel/PlayerMana
@onready var _burn_label: Label = $HUD/StatsPanel/BurnStatus
@onready var _last_damage_label: Label = $HUD/StatsPanel/LastDamage
@onready var _dmg_number_layer: CanvasLayer = $DamageNumbers

var _enemy_sec: StatusEffectController = null


func _ready() -> void:
	_register_content()
	_register_player_abilities()
	_connect_events()

	_enemy_sec = (
		enemy.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
	)

	print("=== Ability Slice ===")
	print("Move: WASD / Arrows    Melee: Space / J    Fireball: Q")
	print("Fireball: 30 magic dmg + Burn (5 fire/s × 4s). Cooldown: 3s. Cost: 15 mana.")


func _process(_delta: float) -> void:
	_update_hud()


# ── content setup ──────────────────────────────────────────────────────────────


func _register_content() -> void:
	var registry := ServiceRegistry.get_service("content") as ContentRegistry
	if registry == null:
		push_error("Phase2: ContentRegistry not available")
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
		var sec := (
			enemy.get_node_or_null("Controllers/StatusEffectController") as StatusEffectController
		)
		if sec != null:
			sec.status_applied.connect(_on_status_applied)
			sec.status_ticked.connect(_on_status_ticked)
			sec.status_removed.connect(_on_status_removed)


# ── HUD ────────────────────────────────────────────────────────────────────────


func _update_hud() -> void:
	# Enemy HP
	if enemy != null and is_instance_valid(enemy):
		var health := enemy.get_node_or_null("Components/HealthComponent") as HealthComponent
		if health != null:
			_hp_label.text = "Enemy HP: %.0f / %.0f" % [health.current_hp, health.get_max_hp()]
	else:
		_hp_label.text = "Enemy: dead"

	# Player Mana
	if player != null:
		var pool := (
			player.get_node_or_null("Components/ResourcePoolComponent") as ResourcePoolComponent
		)
		if pool != null:
			_mana_label.text = (
				"Mana: %.0f / %.0f" % [pool.get_current("mana"), pool.get_max_resource("mana")]
			)

	# Burn status with remaining time
	if (
		_enemy_sec != null
		and is_instance_valid(_enemy_sec)
		and _enemy_sec.has_status("status.burn")
	):
		var inst: StatusEffectInstance = _enemy_sec.active_statuses.get("status.burn")
		if inst != null:
			_burn_label.add_theme_color_override("font_color", Color.ORANGE)
			_burn_label.text = (
				"Burn: %d stack(s)  %.1fs left" % [inst.stacks, inst.remaining_duration]
			)
	else:
		_burn_label.remove_theme_color_override("font_color")
		_burn_label.text = "Burn: inactive"


func _spawn_damage_number(world_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)

	# Convert world → screen (no Camera2D in demo → canvas_transform handles it)
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_pos
	screen_pos += Vector2(randf_range(-20, 20), -24)
	label.position = screen_pos

	_dmg_number_layer.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -48), 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 1.1)
	tween.chain().tween_callback(label.queue_free)


# ── event handlers ─────────────────────────────────────────────────────────────


func _on_damage_applied(result) -> void:
	if result == null:
		return

	var is_burn_tick: bool = (
		result.damage_type == "magic" and result.element_type == "fire" and result.source != player
	)

	var color := Color.WHITE
	if result.was_critical:
		color = Color.YELLOW
	elif is_burn_tick:
		color = Color.ORANGE_RED

	var label_text := "-%d" % int(result.final_amount)
	if result.was_critical:
		label_text += " CRIT"
	elif is_burn_tick:
		label_text += " burn"

	var target_pos := Vector2(460, 300)
	if result.target != null and result.target is Node2D:
		target_pos = (result.target as Node2D).global_position
	_spawn_damage_number(target_pos, label_text, color)

	_last_damage_label.text = "Last hit: %s  (%s)" % [label_text, result.damage_type]

	print(
		(
			"[DMG] %s  final=%.1f  crit=%s  lethal=%s"
			% [
				label_text,
				result.final_amount,
				str(result.was_critical),
				str(result.was_lethal),
			]
		)
	)


func _on_entity_died(entity_id: String, _ref: Node) -> void:
	print("[EVENT] entity_died → %s" % entity_id)
	_last_damage_label.text = "💀 %s died" % entity_id


func _on_cooldown_started(ability_id: String, duration: float) -> void:
	print("[CD] %s  %.1fs" % [ability_id, duration])


func _on_ability_failed(ability_id: String, reason: String) -> void:
	print("[FAIL] %s — %s" % [ability_id, reason])
	_last_damage_label.text = "Blocked: %s" % reason


func _on_status_applied(status_id: String, stacks: int) -> void:
	print("[STATUS] applied %s  stacks=%d" % [status_id, stacks])


func _on_status_ticked(status_id: String) -> void:
	print("[STATUS] tick %s" % status_id)


func _on_status_removed(status_id: String) -> void:
	print("[STATUS] removed %s" % status_id)
	if status_id == "status.burn":
		_burn_label.remove_theme_color_override("font_color")
		_burn_label.text = "Burn: inactive"


func _node_name(n: Node) -> String:
	return str(n.name) if n != null else "?"
