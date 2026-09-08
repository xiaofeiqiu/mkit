extends "res://game/whispering_forest/scripts/actor.gd"

const PerformanceFrames = preload("res://game/whispering_forest/scripts/combat/performance_frames.gd")
var hitstop_remaining := 0.0
var stagger_remaining := 0.0
var reaction_cooldown := 0.0
var knock_velocity := Vector2.ZERO
var poise_damage := 0.0
var previous_moving := false
var transition_left := 0.0
var cast_facing := 0
var rendered_action := "idle"
var foot_phase := 0
var hurt_duration := 0.30
var idle_elapsed := 0.0
var gesture_remaining := 0.0
var next_gesture := 5.6
var stop_quarter := 0
var gait_action := "run"

func setup(kind: String, at: Vector2, hp: float, game: Node, is_elite: bool = false) -> void:
	super.setup(kind,at,hp,game,is_elite)
	sprite.texture = clips.idle[0][0]
	# The city and all actors use the same 2x export density. Physical model
	# dimensions define character sizes; padded PNG height never sets scale.
	sprite.scale=Vector2.ONE/PerformanceFrames.Motion.STAGE.SUPERSAMPLE*(1.32 if kind=="goblin" and is_elite else 1.0)
	sprite.offset=-PerformanceFrames.pivot_for("idle",kind)

func load_animation_clips(kind: String) -> Dictionary:
	return PerformanceFrames.for_kind(kind)

func staff_tip_offset() -> Vector2:
	return PerformanceFrames.staff_tip(rendered_action,facing,animation_frame)

func reset_performance() -> void:
	hitstop_remaining = 0
	stagger_remaining = 0
	reaction_cooldown = 0
	knock_velocity = Vector2.ZERO
	poise_damage = 0
	hurt_pose = 0
	death_age = 0
	frozen_for = 0
	attack_pose = 0
	previous_attack_pose = 0
	previous_moving = false
	transition_left = 0
	idle_elapsed = 0
	gesture_remaining = 0
	last_ground = ground
	sprite.self_modulate = Color.WHITE

func is_recovering() -> bool:
	return hitstop_remaining>0 or stagger_remaining>0 or frozen_for>0

func receive_impact(profile: Dictionary, direction: Vector2) -> void:
	var boss: bool = get_meta("boss",false)
	var allowed := reaction_cooldown<=0
	var stagger: float = profile.stagger
	var push: float = profile.push
	if boss:
		poise_damage += float(profile.poise)
		allowed = allowed and poise_damage>=100.0
		if allowed:
			poise_damage = 0
			stagger = 0.28
		push *= 0.12
	elif elite:
		stagger *= 0.65
		push *= 0.55
	# One brief local pause; hits cannot keep adding time to an existing pause.
	if allowed or health.dead:
		hitstop_remaining = maxf(hitstop_remaining,float(profile.stop)*(0.55 if boss else 1.0))
		stagger_remaining = maxf(stagger_remaining,stagger)
		reaction_cooldown = 1.45 if boss else maxf(0.26,stagger+0.09)
		hurt_duration = minf(0.32,maxf(0.065,stagger))
		hurt_pose = hurt_duration
		windup = 0
		if actor_kind=="mage": attack_pose = 0
		knock_velocity = direction*push*16.0
		# The first hurt pose is already compressed, so the pause reads as contact.
		if not health.dead:
			sprite.texture = clips.hurt[facing][0]
			sprite.offset = -PerformanceFrames.pivot_for("hurt",actor_kind)
			animation_state = "hurt"
			rendered_action = "hurt"
			animation_frame = 0
	hit_flash = 0.055 if not bool(profile.critical) else 0.075
	sprite.self_modulate = Color(1.8,1.8,1.65)

func step(delta: float) -> void:
	if actor_kind=="mentor":
		# Town NPCs deliberately keep a fixed standing pose.
		position=WFIso.project(ground)
		animation_state="idle"
		rendered_action="idle"
		animation_frame=0
		sprite.texture=clips.idle[facing][0]
		sprite.offset=-PerformanceFrames.pivot_for("idle",actor_kind)
		queue_redraw()
		return
	reaction_cooldown = maxf(0,reaction_cooldown-delta)
	poise_damage = maxf(0,poise_damage-delta*7.0)
	frozen_for = maxf(0,frozen_for-delta)
	var held := minf(delta,hitstop_remaining)
	hitstop_remaining = maxf(0,hitstop_remaining-delta)
	var dt := delta-held
	if dt<=0:
		position = WFIso.project(ground)
		queue_redraw()
		return
	animation_clock += dt
	stagger_remaining = maxf(0,stagger_remaining-dt)
	hurt_pose = maxf(0,hurt_pose-dt)
	hit_flash = maxf(0,hit_flash-dt)
	invincible = maxf(0,invincible-dt)
	cooldown = maxf(0,cooldown-dt)
	if knock_velocity.length_squared()>0.04:
		# Exponential integration makes recoil distance independent of frame rate.
		var decay := exp(-16.0*dt)
		world.move_actor(self,knock_velocity*(1.0-decay)/16.0)
		knock_velocity *= decay
	if attack_pose>previous_attack_pose+0.001:
		attack_duration = attack_pose
		cast_facing = facing
	attack_pose = maxf(0,attack_pose-dt)
	previous_attack_pose = attack_pose
	if health.dead: death_age += dt
	position = WFIso.project(ground)
	var traveled := ground.distance_to(last_ground)
	last_ground = ground
	var walking := moving and traveled>0.001 and traveled<200 and not is_recovering()
	if walking!=previous_moving:
		transition_left = 0.12 if walking else 0.18
		if walking:
			walk_phase=0
			foot_phase=0
			if actor_kind=="mage" and world.get("impact")!=null: world.impact.footstep()
		else: stop_quarter=posmod(roundi(walk_phase*4),4)
	previous_moving = walking
	transition_left = maxf(0,transition_left-dt)
	if walking or attack_pose>0 or hurt_pose>0 or health.dead:
		idle_elapsed=0
		gesture_remaining=0
		next_gesture=5.6
	else:
		idle_elapsed+=dt
		gesture_remaining=maxf(0,gesture_remaining-dt)
		if actor_kind=="mage" and world.area=="city" and idle_elapsed>=next_gesture and gesture_remaining<=0:
			gesture_remaining=2.0
			next_gesture=idle_elapsed+7.4+fposmod(animation_clock*0.37,3.0)
	var idle_seconds := 2.4 if actor_kind=="mage" and world.area=="dungeon" else 3.2
	var idle_phase := fposmod((idle_elapsed if actor_kind=="mage" else animation_clock)/idle_seconds,1.0)
	animation_state = "idle"
	rendered_action = "ready" if actor_kind=="mage" and world.area=="dungeon" else "idle"
	animation_frame = mini(int(idle_phase*clips[rendered_action][0].size()),clips[rendered_action][0].size()-1)
	if walking:
		gait_action="run" if actor_kind=="mage" and traveled/maxf(dt,0.0001)>80.0 else "walk"
		var stride_length := PerformanceFrames.Motion.stride_units(gait_action=="run") if actor_kind=="mage" else 70.0
		walk_phase = fposmod(walk_phase+traveled/stride_length,1.0)
		var next_foot := int(walk_phase*2)
		if next_foot!=foot_phase and actor_kind=="mage" and world.get("impact")!=null:
			world.impact.footstep()
		foot_phase = next_foot
	if health.dead:
		animation_state = "death"
		animation_frame = clampi(int(death_age/0.72*8),0,7)
		rendered_action = "death"
	elif hurt_pose>0:
		animation_state = "hurt"
		animation_frame = clampi(int((1.0-hurt_pose/hurt_duration)*8),0,7)
		rendered_action = "hurt"
	elif actor_kind=="mage" and world.meteor_timer>0:
		animation_state = "seal"
		animation_frame = clampi(int((1.0-world.meteor_timer/1.3)*8),0,7)
		rendered_action = "seal"
	elif actor_kind=="mage" and world.dodge_timer>0:
		animation_state = "dodge"
		animation_frame = clampi(int((1.0-world.dodge_timer/0.2)*8),0,7)
		rendered_action = "dodge"
	elif actor_kind=="goblin" and windup>0:
		animation_state = "attack"
		animation_frame = clampi(int((1.0-windup/0.85)*3),0,2)
		rendered_action = "attack"
	elif attack_pose>0:
		animation_state = "attack"
		animation_frame = clampi(int((1.0-attack_pose/maxf(attack_duration,0.01))*7.0+0.001),0,7)
		if actor_kind=="goblin": animation_frame = clampi(3+int((1.0-attack_pose/maxf(attack_duration,0.01))*5),3,7)
		rendered_action = "cast_walk" if walking and clips.has("cast_walk") else "attack"
		facing = cast_facing
	elif walking:
		animation_state = "walk"
		rendered_action = gait_action
		animation_frame = mini(int(walk_phase*clips[rendered_action][0].size()),clips[rendered_action][0].size()-1)
		if actor_kind=="mage" and transition_left>0 and gait_action=="run":
			rendered_action="start"
			animation_frame=clampi(int((1.0-transition_left/0.12)*8),0,7)
	else:
		if transition_left>0 and clips.has("stop"):
			rendered_action = "stop" if stop_quarter==0 else "stop_"+str(stop_quarter)
			animation_frame = clampi(int((1.0-transition_left/0.18)*8),0,7)
		elif gesture_remaining>0 and clips.has("look"):
			rendered_action="look"
			animation_frame=clampi(int((1.0-gesture_remaining/2.0)*24),0,23)
	sprite.texture = clips[rendered_action][facing][animation_frame]
	sprite.offset = -PerformanceFrames.pivot_for(rendered_action,actor_kind)
	sprite.flip_h = false
	sprite.position = Vector2.ZERO
	sprite.rotation = 0
	if health.dead:
		sprite.self_modulate = Color(1,1,1,1-smoothstep(0.85,1.25,death_age))
	elif hit_flash>0: sprite.self_modulate = Color(1.8,1.8,1.65)
	elif frozen_for>0: sprite.self_modulate = Color(0.62,0.86,1.12)
	elif invincible>0 and actor_kind=="mage":
		sprite.self_modulate = Color(1,1,1,0.65+0.35*absf(sin(animation_clock*25)))
	else: sprite.self_modulate = Color.WHITE
	queue_redraw()

func _on_damaged(result: DamageResult) -> void:
	world.hit_feedback(self,result)
