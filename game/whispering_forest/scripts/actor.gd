class_name WFActor
extends EntityRoot

const AnimationSet = preload("res://game/whispering_forest/scripts/character_frames.gd")

var ground := Vector2.ZERO
var spawn_ground := Vector2.ZERO
var actor_kind := "mage"
var world: Node
var sprite: Sprite2D
var stats_component: StatsComponent
var health: HealthComponent
var facing := 0
var moving := false
var animation_clock := 0.0
var hit_flash := 0.0
var attack_pose := 0.0
var invincible := 0.0
var windup := 0.0
var attack_target := Vector2.ZERO
var cooldown := 0.0
var respawn_timer := 0.0
var elite := false
var clips: Dictionary = {}
var animation_state := "idle"
var animation_frame := 0
var walk_phase := 0.0
var last_ground := Vector2.ZERO
var attack_duration := 0.35
var previous_attack_pose := 0.0
var body_height := 72.0
var hurt_pose := 0.0
var death_age := 0.0
var frozen_for := 0.0

func setup(kind: String, at: Vector2, hp: float, game: Node, is_elite: bool = false) -> void:
	actor_kind = kind
	ground = at
	spawn_ground = at
	last_ground = at
	world = game
	elite = is_elite
	var identity_node := EntityIdentity.new()
	identity_node.name = "EntityIdentity"
	identity_node.entity_id = "wf.%s.%d" % [kind,get_instance_id()]
	add_child(identity_node)
	var machine := Fsm.new()
	machine.name = "StateMachine"
	add_child(machine)
	var components := Node.new()
	components.name = "Components"
	add_child(components)
	stats_component = StatsComponent.new()
	stats_component.name = "StatsComponent"
	stats_component.base_stats = {"max_hp": hp, "attack_power": 12.0, "defense": 0.0, "crit_chance": 0.1, "crit_damage": 1.6}
	components.add_child(stats_component)
	stats_component.owner = self
	health = HealthComponent.new()
	health.name = "HealthComponent"
	health.current_hp = hp
	components.add_child(health)
	health.owner = self
	# Runtime-created entities set the contract explicitly as well as owner.
	health.stats = stats_component
	health.damaged.connect(_on_damaged)
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.material = AnimationSet.outline()
	add_child(sprite)
	clips = load_animation_clips(kind)
	sprite.texture = clips.idle[0][0]
	# Normalize visible body height, not the size of the padded source canvas.
	# Ordinary humans share one scale; goblins are smaller, buildings much larger.
	body_height = 72.0 if kind != "goblin" else (74.0 if elite else 56.0)
	var source_body_height := 197.0 if kind == "mentor" else 216.0
	sprite.scale = Vector2.ONE * body_height / source_body_height
	# Every rendered angle and pose shares the same projected ground origin.
	sprite.centered = false
	sprite.offset = -AnimationSet.PIVOT
	position = WFIso.project(ground)
	queue_redraw()

func load_animation_clips(kind: String) -> Dictionary:
	return AnimationSet.for_kind(kind)

func step(delta: float) -> void:
	animation_clock += delta
	hurt_pose=maxf(0,hurt_pose-delta)
	frozen_for=maxf(0,frozen_for-delta)
	if health.dead: death_age+=delta
	hit_flash = maxf(0, hit_flash - delta)
	if attack_pose > previous_attack_pose+0.001:
		attack_duration = attack_pose
	attack_pose = maxf(0, attack_pose - delta)
	previous_attack_pose = attack_pose
	invincible = maxf(0, invincible - delta)
	cooldown = maxf(0, cooldown - delta)
	position = WFIso.project(ground)
	var traveled := ground.distance_to(last_ground)
	last_ground = ground
	var idle_phase := fposmod(animation_clock/3.2,1.0)
	animation_state = "idle"
	animation_frame = mini(int(idle_phase*8),7)
	if animation_frame==6 and (idle_phase<0.80 or idle_phase>0.845):
		animation_frame = 5 if idle_phase<0.80 else 7
	if health.dead:
		animation_state="death" if clips.has("death") else "attack"
		animation_frame=clampi(int(death_age/0.72*8),0,7)
	elif hurt_pose>0:
		animation_state="hurt" if clips.has("hurt") else "attack"
		animation_frame=clampi(int((1.0-hurt_pose/0.3)*8),0,7)
	elif actor_kind=="mage" and world.meteor_timer>0:
		animation_state = "seal"
		animation_frame = clampi(int((1.0-world.meteor_timer/1.3)*8),0,7)
	elif moving and traveled>0.001 and traveled<200:
		animation_state = "walk"
		walk_phase = fposmod(walk_phase+traveled/70.0,1.0)
		animation_frame = mini(int(walk_phase*8),7)
	elif attack_pose>0:
		animation_state = "attack"
		animation_frame = clampi(int((1.0-attack_pose/maxf(attack_duration,0.01))*8),0,7)
	sprite.texture = clips[animation_state][facing][animation_frame]
	sprite.flip_h = false
	sprite.position = Vector2.ZERO
	sprite.rotation = 0
	if health.dead:
		sprite.self_modulate=Color(1,1,1,1-smoothstep(0.85,1.25,death_age))
	elif hit_flash > 0:
		sprite.self_modulate = Color(2.2, 1.4, 1.0)
	elif frozen_for>0:
		sprite.self_modulate=Color(0.62,0.86,1.12)
	elif invincible > 0 and actor_kind == "mage":
		sprite.self_modulate = Color(1, 1, 1, 0.45 + 0.5 * absf(sin(animation_clock * 25)))
	else:
		sprite.self_modulate = Color.WHITE
	queue_redraw()

func face(direction: Vector2) -> void:
	if direction.length_squared() < 0.001:
		return
	var screen := WFIso.project(direction)
	facing = AnimationSet.facing_for_screen(screen)

func _on_damaged(result: DamageResult) -> void:
	hit_flash = 0.065
	hurt_pose=0.3
	world.hit_feedback(self, result)

func _draw() -> void:
	if health == null or health.dead:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 13 if actor_kind != "goblin" else 11, Color(0.08, 0.13, 0.08, 0.25))
	if actor_kind == "mage":
		draw_arc(Vector2.ZERO, 16, 0, TAU, 40, Color(0.7, 0.9, 0.77, 0.8), 1.3, true)
	elif actor_kind == "mentor":
		draw_arc(Vector2.ZERO, 17, 0, TAU, 40, Color(0.97, 0.73, 0.31, 0.7), 1.5, true)
	draw_set_transform(Vector2.ZERO)
	if actor_kind == "goblin" and (elite or health.current_hp<health.get_max_hp()):
		var width := 46.0 if not elite else 66.0
		var y := -body_height - 10.0
		draw_style_box(world.bar_style(Color(0.1, 0.13, 0.12, 0.8)), Rect2(-width / 2, y, width, 5))
		draw_style_box(world.bar_style(Color("d88753") if not elite else Color("c797db")), Rect2(-width / 2, y, width * health.current_hp / health.get_max_hp(), 5))
		if elite:
			draw_colored_polygon(PackedVector2Array([Vector2(-4, y-8),Vector2(0,y-14),Vector2(4,y-8),Vector2(0,y-4)]), Color("e1bf69"))
	if actor_kind == "mentor":
		var indicator_y := -body_height - 15 + sin(animation_clock * 2) * 3
		draw_circle(Vector2(0, indicator_y), 8, Color("edc76f"))
		draw_line(Vector2(0, indicator_y-4), Vector2(0, indicator_y+1), Color("273d33"), 2)
		draw_circle(Vector2(0, indicator_y+4), 1, Color("273d33"))
