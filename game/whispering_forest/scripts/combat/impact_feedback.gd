extends Node2D

const Tuning = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
# Seconds and logical ground units. Pause is local to the victim, never Engine.time_scale.
const PROFILES := {
	"physical": [0.038,0.100,6.0,14.0,0.6],
	"fire": [0.052,0.160,10.0,23.0,1.5],
	"wind": [0.025,0.065,4.0,7.0,0.35],
	"earth": [0.075,0.260,18.0,45.0,3.0],
	"water": [0.042,0.140,5.0,18.0,1.0],
	"meteor": [0.110,0.420,28.0,100.0,6.0],
}
const COLORS := {"physical":"dbf8ed","fire":"ffae54","wind":"b2eee5","earth":"dec89a","water":"9addff","meteor":"ffbb64"}
var world: Node
var clock := 0.0
var sparks: Array[Dictionary] = []
var casts: Array[Dictionary] = []
var voices: Array[AudioStreamPlayer2D] = []
var sound_cache: Dictionary = {}
var sound_gates: Dictionary = {}
var variants: Dictionary = {}
var sound_events: Array[Dictionary] = []
var camera_direction := Vector2.RIGHT
var camera_strength := 0.0
var camera_age := 1.0
var camera_offset := Vector2.ZERO
var duck_left := 0.0
var ambient_base := -20.0
var ambient_known := false
var basic_buffer := 0.0
var owns_audio_bus := false

func _ready() -> void:
	z_index = 21
	if AudioServer.get_bus_index("WF Impact")<0:
		owns_audio_bus = true
		AudioServer.add_bus()
		var index := AudioServer.bus_count-1
		AudioServer.set_bus_name(index,"WF Impact")
		AudioServer.set_bus_send(index,"Master")
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.threshold_db = -3.0
		AudioServer.add_bus_effect(index,limiter)
	for i in range(16):
		var voice := AudioStreamPlayer2D.new()
		voice.bus = "WF Impact"
		voice.max_distance = 2200
		voice.attenuation = 0.3
		voice.panning_strength = 0.4
		add_child(voice)
		voices.append(voice)
	for kind in ["physical","fire","wind","earth","water","critical","meteor","death","launch","dodge","step-grass","step-concrete"]:
		var samples: Array[AudioStream] = []
		for i in range(3):
			samples.append(load("res://game/whispering_forest/assets/impact-audio/%s-%d.wav" % [kind,i]))
		sound_cache[kind] = samples

func profile_for(result: DamageResult) -> Dictionary:
	var p: Array = PROFILES.get(result.element_type,PROFILES.physical)
	var crit := result.was_critical
	return {"stop":minf(0.12,float(p[0])*(1.35 if crit else 1.0)),"stagger":float(p[1])*(1.3 if crit else 1.0),"push":float(p[2])*(1.4 if crit else 1.0),"poise":float(p[3])*(1.5 if crit else 1.0),"shake":float(p[4])*(1.5 if crit else 1.0),"critical":crit}

func _exit_tree() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	sound_cache.clear()
	var index := AudioServer.get_bus_index("WF Impact")
	if owns_audio_bus and index>=0: AudioServer.remove_bus(index)

func react(actor: WFActor, result: DamageResult) -> void:
	var p := profile_for(result)
	var source := result.source as WFActor
	var direction := (actor.ground-source.ground).normalized() if is_instance_valid(source) else Vector2.RIGHT
	if direction==Vector2.ZERO: direction = Vector2.RIGHT
	if actor.has_method("receive_impact"): actor.call("receive_impact",p,direction)
	var element: String = result.element_type if PROFILES.has(result.element_type) else "physical"
	var col := Color(COLORS[element])
	var point := WFIso.project(actor.ground)+Vector2(0,-actor.body_height*0.54)
	sparks.append({"at":point,"direction":WFIso.project(direction).normalized(),"life":0.19,"total":0.19,"color":col,"size":22.0 if result.was_critical else (26.0 if element=="meteor" else 14.0)})
	if sparks.size()>40: sparks.pop_front()
	var number_color := Color("ffdf8f") if result.was_critical else (Color("ffb6a3") if actor==world.player else Color("f2faf1"))
	world.effects.number(actor.ground,str(int(result.final_amount))+("!" if result.was_critical else ""),number_color,result.was_critical or element=="meteor")
	# Player tornado contact owns its level-specific sound in spell_system.
	# Keep the visual reaction here without doubling it with the old wind tick.
	var owned_contact: bool=element==world.spells.contact_audio_element
	if not (source==world.player and (element=="wind" or owned_contact)):
		play(element,actor.ground,5 if element=="meteor" else (3 if result.was_critical else 2),-3 if element=="wind" else 0)
	if result.was_critical: play("critical",actor.ground,4,-4)
	impulse(WFIso.project(direction).normalized(),float(p.shake))
	if element=="meteor" or result.was_critical: duck_left = maxf(duck_left,0.22 if element=="meteor" else 0.10)

func impulse(direction: Vector2, strength: float) -> void:
	# Merge simultaneous victims into the strongest impulse, rather than summing.
	if camera_age<0.07 and strength<camera_strength: return
	camera_strength = minf(strength,7.0)
	camera_direction = direction
	camera_age = 0

func queue_basic(direction: Vector2) -> void:
	var duration := 0.42
	world.player.attack_pose = duration
	casts = [{"left":duration*3.0/7.0,"kind":"basic","direction":direction}]

func queue_spell(index: int, target: WFActor) -> void:
	var d := Tuning.definition(index,world.spells.levels[index],world.spells.modifiers)
	var duration := 0.42/minf(2.5,1.0+float(world.spells.modifiers.get("speed",0)))
	world.player.face(target.ground-world.player.ground)
	world.player.attack_pose = duration
	world.skill_cooldowns[index] = d.cooldown
	casts = [{"left":duration*3.0/7.0,"kind":"spell","index":index,"target":weakref(target)}]

func reset() -> void:
	casts.clear()
	sparks.clear()
	basic_buffer = 0
	camera_strength = 0
	camera_offset = Vector2.ZERO
	duck_left = 0
	for voice in voices: voice.stop()
	if is_instance_valid(world.player) and world.player.has_method("reset_performance"):
		world.player.call("reset_performance")

func advance(delta: float) -> void:
	clock += delta
	if world.area!="dungeon" or world.player.health.dead:
		casts.clear()
	elif world.player.is_recovering():
		casts.clear()
	for event in casts:
		event.left -= delta
		if event.left>0: continue
		if event.kind=="basic":
			world.launch_bolt(event.direction,12,"physical")
			play("launch",world.player.ground,1,-5)
		else:
			var target: WFActor = event.target.get_ref()
			if not is_instance_valid(target) or target.health.dead: target = world.nearest_enemy(430)
			if is_instance_valid(target):
				var remaining: float = world.player.attack_pose
				var cooldown: float = world.skill_cooldowns[event.index]
				world.spells.cast(event.index,target)
				world.player.attack_pose = remaining
				world.skill_cooldowns[event.index] = cooldown
	casts = casts.filter(func(e): return e.left>0)
	if basic_buffer>0:
		basic_buffer = maxf(0,basic_buffer-delta)
		if world.attack_cooldown<=0 and casts.is_empty():
			basic_buffer = 0
			world.perform_attack()
	for spark in sparks: spark.life -= delta
	sparks = sparks.filter(func(s): return s.life>0)
	camera_age += delta
	camera_offset = camera_direction*camera_strength*exp(-camera_age*18)*cos(camera_age*55)
	if camera_age>0.32: camera_offset = Vector2.ZERO
	if is_instance_valid(world.ambient):
		if not ambient_known:
			ambient_base = world.ambient.volume_db
			ambient_known = true
		duck_left = maxf(0,duck_left-delta)
		world.ambient.volume_db = move_toward(world.ambient.volume_db,ambient_base-(3.0 if duck_left>0 else 0.0),delta*30)
	queue_redraw()

func footstep() -> void:
	play("step-concrete" if world.area=="city" else "step-grass",world.player.ground,0,-17)

func play(kind: String, at: Vector2, priority: int = 2, gain: float = 0.0) -> void:
	if world.muted or not sound_cache.has(kind) or clock<float(sound_gates.get(kind,-1)): return
	var selected: AudioStreamPlayer2D
	for voice in voices:
		if not voice.playing:
			selected = voice
			break
	if selected==null:
		for voice in voices:
			if int(voice.get_meta("priority",0))>priority: continue
			if selected==null or int(voice.get_meta("priority",0))<int(selected.get_meta("priority",0)) or (int(voice.get_meta("priority",0))==int(selected.get_meta("priority",0)) and float(voice.get_meta("began",0))<float(selected.get_meta("began",0))):
				selected = voice
	if selected==null: return
	var variant := posmod(int(variants.get(kind,-1))+randi_range(1,2),3)
	variants[kind] = variant
	selected.stop()
	selected.stream = sound_cache[kind][variant]
	selected.position = WFIso.project(at)+Vector2(0,-30)
	selected.volume_db = -9+gain
	selected.pitch_scale = randf_range(0.98,1.02)
	selected.set_meta("priority",priority)
	selected.set_meta("began",clock)
	if not world.simulation: selected.play()
	sound_gates[kind] = clock+(0.12 if priority==0 else 0.065)
	sound_events.append({"kind":kind,"variant":variant,"at":clock})
	if sound_events.size()>64: sound_events.pop_front()

func _draw() -> void:
	for s in sparks:
		var age: float = 1.0-s.life/s.total
		var size: float = s.size*(0.65+age*1.25)
		var col: Color = s.color
		col.a = pow(1.0-age,1.3)
		draw_set_transform(s.at,s.direction.angle())
		var spike := PackedVector2Array([Vector2(-size,0),Vector2(-2,-2),Vector2(2,-size*0.55),Vector2(4,-2),Vector2(size*0.6,0),Vector2(3,2),Vector2(-2,size*0.6),Vector2(-3,2)])
		draw_colored_polygon(spike,col)
		if age<0.25: draw_circle(Vector2.ZERO,4.0*(1-age),Color("fffdf1"))
		for i in range(5):
			var ray := Vector2.from_angle(-1.0+i*0.50)
			draw_line(ray*size*(0.5+age),ray*size*(0.85+age),col,1.6,true)
		draw_set_transform(Vector2.ZERO)
