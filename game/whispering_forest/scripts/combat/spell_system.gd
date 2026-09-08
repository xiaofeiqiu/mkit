extends Node

const Tuning = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
const Visual = preload("res://game/whispering_forest/scripts/combat/spell_visual.gd")
const GaleMotion = preload("res://game/whispering_forest/scripts/combat/gale_motion.gd")
const FireCue = preload("res://game/whispering_forest/scripts/combat/fire_cue.gd")
var world: Node
var levels: Array[int] = [1,1,1,1]
var modifiers: Dictionary = {}
var pending: Array[Dictionary] = []
var tornadoes: Array[Dictionary] = []
var visuals: Array[Node2D] = []
var voices: Array[AudioStreamPlayer] = []
var sound_cache: Dictionary = {}
var sound_gates: Dictionary = {}
var clock := 0.0
var audio_cues: Array[Dictionary] = []
var sound_events: Array[Dictionary] = []
var wind_voice: AudioStreamPlayer
var wind_gain := 0.0
var contact_audio_element := ""
var releases: Array[Dictionary] = []
var release_events: Array[Dictionary] = []
var next_cast_id := 0

func _ready() -> void:
	for i in range(16):
		var voice:=AudioStreamPlayer.new()
		voice.bus="WF Impact" if AudioServer.get_bus_index("WF Impact")>=0 else "Master"
		voice.max_polyphony=1
		add_child(voice)
		voices.append(voice)
	wind_voice=AudioStreamPlayer.new()
	wind_voice.bus=voices[0].bus
	add_child(wind_voice)

func _process(_delta: float) -> void:
	# Audio loops must pause even when the world stops advancing its simulation
	# for a menu/card choice. User volume and city music remain untouched.
	var silence: bool=world.muted or world.paused or not world.dialogue.is_empty() or not world.expedition.card_choices.is_empty()
	for voice in voices: voice.stream_paused=silence
	wind_voice.stream_paused=silence

func reset() -> void:
	if world.get("impact")!=null: world.impact.casts.clear()
	pending.clear(); tornadoes.clear()
	releases.clear(); release_events.clear()
	audio_cues.clear(); sound_events.clear(); sound_gates.clear()
	for v in visuals:
		if is_instance_valid(v): v.queue_free()
	visuals.clear()
	for voice in voices: voice.stop()
	wind_voice.stop(); wind_gain=0
	contact_audio_element=""

func queue_sound(kind: String, delay: float, level: int, gain: float = 0.0, seconds: float = 0.0) -> void:
	if delay<=0: play(kind,level,gain,seconds)
	else: audio_cues.append({"kind":kind,"delay":delay,"level":level,"gain":gain,"seconds":seconds})

func start_ultimate_audio() -> void:
	queue_sound("ultimate-seal",0,10,-3,1.3)
	queue_sound("ultimate-fall",0.25,10,0,1.05)

func visual(kind: String, at: Vector2, radius: float, level: int, duration: float) -> Node2D:
	var node:=Visual.new()
	node.setup(kind,at,radius,level,duration)
	world.sorted_world.add_child(node)
	visuals.append(node)
	return node

func cast(index: int, target: WFActor) -> void:
	if not is_instance_valid(target) or target.health.dead: return
	var d:=Tuning.definition(index,levels[index],modifiers)
	world.skill_cooldowns[index]=d.cooldown
	world.player.face(target.ground-world.player.ground)
	world.player.attack_pose=0.42/minf(2.5,1.0+float(modifiers.get("speed",0)))
	var targets: Array[WFActor] = [target]
	for enemy in world.enemies:
		if targets.size()>=int(d.count): break
		if enemy!=target and not enemy.health.dead and enemy.ground.distance_to(target.ground)<180:
			targets.append(enemy)
	var count: int=mini(int(d.count),5) if index==1 else int(d.count)
	var gap: float=float(d.release_window)/float(count-1) if count>1 else 0.0
	var rock_order:=range(6)
	rock_order.shuffle()
	var victims: Dictionary={}
	next_cast_id+=1
	for i in range(count):
		# Positions/level/modifiers are value snapshots. A target may move or be
		# freed before a later release; no queued actor reference can go stale.
		var request: Dictionary={"index":index,"data":d,"at":targets[i%targets.size()].ground,
			"release_at":clock+i*gap,"cast_id":next_cast_id,"ordinal":i,"count":count,
			"rock_index":rock_order[i%6],"victims":victims}
		if i==0: release_one(request)
		else: releases.append(request)
	releases.sort_custom(func(a,b): return a.release_at<b.release_at)

func release_one(request: Dictionary) -> void:
	var d: Dictionary=request.data
	var at: Vector2=request.at
	var gain:=meteor_layer_gain(int(request.count))
	release_events.append({"at":clock,"planned_at":request.release_at,"cast_id":request.cast_id,
		"index":request.index,"ordinal":request.ordinal,"level":d.level,"target":[at.x,at.y]})
	if release_events.size()>128: release_events.pop_front()
	match int(request.index):
		0:
			var life: float=FireCue.duration() if d.level==1 else Tuning.FIRE_LIFE
			var hit_at: float=FireCue.hit_time() if d.level==1 else Tuning.FIRE_HIT
			if d.level==1: play("fire-sequence",1,gain,life,true)
			else: play("fire-ignite",d.level,-4+gain,hit_at,true)
			visual("fire",at,d.radius,d.level,life)
			pending.append({"delay":hit_at,"kind":"fire","points":[at],"data":d,"victims":request.victims,"audio_gain":gain,"distinct":true})
		1:
			var origin: Vector2=world.player.ground
			var heading: Vector2=(at-origin).normalized()
			var direction:=heading.rotated((int(request.ordinal)-float(request.count-1)/2.0)*0.20)
			var v:=visual("wind",origin,d.radius,d.level,d.duration+Tuning.WIND_TAIL)
			tornadoes.append({"at":origin,"direction":direction,"life":d.duration,"bounces":d.bounces,"hits":{},"data":d,"visual":v,"motion":GaleMotion.new(randi())})
			play("wind",d.level,gain,0,true)
		2:
			var stone:=visual("earth",at,d.radius,d.level,Tuning.EARTH_FALL+Tuning.EARTH_TAIL)
			stone.impact_at=Tuning.EARTH_FALL
			stone.launch_at=0
			stone.rock_index=request.rock_index
			play("fall",d.level,-1+gain,Tuning.EARTH_FALL,true)
			pending.append({"delay":Tuning.EARTH_FALL,"kind":"earth","points":[at],"data":d,"audio_gain":gain,"distinct":true})
		3:
			# Ice is silent while the stamp and pillar grow. The peak event below
			# owns the single impact cue, damage and freeze together.
			visual("ice",at,d.radius,d.level,Tuning.ICE_LIFE)
			pending.append({"delay":Tuning.ICE_HIT,"kind":"water","points":[at],"data":d,"victims":request.victims,"audio_gain":gain,"distinct":true})

func advance(delta: float) -> void:
	if world.player.health.dead: releases.clear()
	var end: float=clock+maxf(delta,0)
	# Split at due releases so a newborn does not inherit the whole frame's
	# elapsed time. Every piece keeps its complete local animation and hit timer.
	while not releases.is_empty() and float(releases[0].release_at)<=end+0.0000001:
		var request: Dictionary=releases.pop_front()
		var due: float=clampf(float(request.release_at),clock,end)
		if due>clock: advance_live(due-clock)
		release_one(request)
	advance_live(maxf(0,end-clock))

func advance_live(delta: float) -> void:
	clock+=delta
	for cue in audio_cues:
		cue.delay-=delta
		if cue.delay<=0: play(cue.kind,int(cue.level),float(cue.gain),float(cue.seconds))
	audio_cues=audio_cues.filter(func(c): return c.delay>0)
	for event in pending:
		event.delay-=delta
		if event.delay>0: continue
		var d: Dictionary=event.data
		var gain: float=event.get("audio_gain",0)
		var distinct: bool=event.get("distinct",false)
		if event.kind=="fire" and int(d.level)!=1: play("fire",int(d.level),gain,0,distinct)
		if event.kind=="water": play("ice",int(d.level),gain,0,distinct)
		for enemy in world.enemies:
			if enemy.health.dead: continue
			var victim_id: int=enemy.get_instance_id()
			if event.has("victims") and event.victims.has(victim_id): continue
			for at in event.points:
				if enemy.ground.distance_to(at)<=float(d.radius)+10:
					if event.has("victims"): event.victims[victim_id]=true
					# These spell recordings already contain their contact. Scope
					# ownership to this damage call so ordinary bolts retain SFX.
					contact_audio_element=event.kind if (event.kind=="water" or (event.kind=="fire" and int(d.level)==1)) else ""
					world.deal_damage(world.player,enemy,d.damage,event.kind)
					contact_audio_element=""
					if event.kind=="water" and not enemy.health.dead:
						enemy.frozen_for=maxf(enemy.frozen_for,float(d.freeze)*(0.3 if enemy.get_meta("boss",false) else 1.0))
						enemy.windup=0
					break # one hit per fire/ice cast even when neighboring areas overlap
		if event.kind=="earth":
			for at in event.points: visual("impact",at,d.radius,d.level,1.3)
			play("rock",d.level,gain,0,distinct)
			world.screen_shake=maxf(world.screen_shake,1.5+float(d.level)*0.22)
	pending=pending.filter(func(e): return e.delay>0)
	for tornado in tornadoes:
		var active_delta:=minf(delta,maxf(0,tornado.life))
		tornado.life-=delta
		var d: Dictionary=tornado.data
		var motion: RefCounted=tornado.motion
		# Small time steps keep curved swept hits and wall reflection consistent
		# at both high and low frame rates.
		var steps:=maxi(1,ceili(active_delta/(1.0/120)))
		var dt:=active_delta/steps
		for j in range(steps):
			tornado.direction=motion.advance(tornado.direction,dt)
			var old: Vector2=tornado.at
			var next: Vector2=old+tornado.direction*float(motion.speed)*dt
			if not world.walkable(next,8):
				if int(tornado.bounces)<=0:
					tornado.life=0
					break
				tornado.direction=reflect(tornado.direction,next)
				tornado.bounces-=1
				motion.on_bounce()
				next=old+tornado.direction*float(motion.speed)*dt
				play("wind",int(d.level),-9)
			if world.walkable(next,8): tornado.at=next
			for enemy in world.enemies:
				if enemy.health.dead: continue
				var id: int=enemy.get_instance_id()
				if clock<float(tornado.hits.get(id,-1)): continue
				if Geometry2D.get_closest_point_to_segment(enemy.ground,old,tornado.at).distance_to(enemy.ground)<=float(d.radius)+10:
					tornado.hits[id]=clock+0.30
					var hit: DamageResult=world.deal_damage(world.player,enemy,d.damage,"wind")
					if not hit.was_evaded and hit.final_amount>0:
						play("wind-hit",int(d.level))
					if not enemy.get_meta("boss",false): enemy.windup=0
		if is_instance_valid(tornado.visual):
			tornado.visual.ground=tornado.at
			if tornado.life<=0: tornado.visual.begin_fade(Tuning.WIND_TAIL)
	tornadoes=tornadoes.filter(func(t): return t.life>0)
	for v in visuals:
		if not is_instance_valid(v): continue
		v.advance(delta)
		if v.age>=v.duration: v.queue_free()
	visuals=visuals.filter(func(v): return is_instance_valid(v) and not v.is_queued_for_deletion())
	update_wind_audio(delta)

func reflect(direction: Vector2, collision: Vector2) -> Vector2:
	# Analytic collision normals for the existing rectangular instance and round
	# tree/pond colliders. Reflect v - 2(v dot n)n; corners reflect both axes.
	var result:=direction
	var boundary: float=world.LIMIT-8
	var wall:=false
	if absf(collision.x)>boundary: result.x=-result.x; wall=true
	if absf(collision.y)>boundary: result.y=-result.y; wall=true
	if wall: return result.normalized()
	var center:=Vector2(-255,235)
	var found:=collision.distance_to(center)<93
	if not found:
		for prop in world.props:
			if prop.radius>0 and collision.distance_to(prop.ground)<prop.radius+8:
				center=prop.ground; found=true; break
	if found:
		var normal: Vector2=(collision-center).normalized()
		return direction.bounce(normal).normalized()
	return -direction

func update_wind_audio(delta: float) -> void:
	var power:=0.0
	var rank:=1
	for v in visuals:
		if v.kind=="wind":
			power+=v.opacity()
			rank=maxi(rank,v.level)
	var target:=minf(power,1.6)*db_to_linear(lerpf(-11,-7,float(rank-1)/9))
	wind_gain=lerpf(wind_gain,target,1-exp(-delta*9))
	if world.muted: wind_gain=0
	if wind_gain<0.0005:
		wind_voice.stop()
		return
	if not wind_voice.playing:
		var path: String="res://game/whispering_forest/assets/spell-audio-v2/wind-loop-%s.wav" % ("full" if rank>=6 else "small")
		var stream: AudioStreamWAV=load(path).duplicate()
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin=0
		stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
		wind_voice.stream=stream
		wind_voice.play()
		sound_events.append({"kind":"wind-loop","at":clock,"level":rank})
	wind_voice.volume_db=linear_to_db(wind_gain)

func meteor_layer_gain(count: int) -> float:
	# Four falling stones should sound fuller without four full-volume impacts
	# crushing the bus limiter. Single stones retain the original level.
	return -minf(6.0,6.0*log(maxi(1,count))/log(10.0))

func sound_path(kind: String, level: int) -> String:
	var suffix: String="full" if level>=6 else "small"
	if kind=="fire-sequence": return FireCue.PATH
	if kind=="ice" and level==1:
		return "res://game/whispering_forest/assets/ice-audio-v8/hit-level-1.wav"
	if kind=="wind-hit":
		return "res://game/whispering_forest/assets/wind-audio-v4/hit-%s.wav" % suffix
	if kind in ["fall","rock","ultimate-fall","ultimate-impact"]:
		if kind.begins_with("ultimate-"): suffix="full"
		return "res://game/whispering_forest/assets/meteor-audio-v3/%s-%s.wav" % [kind,suffix]
	return "res://game/whispering_forest/assets/spell-audio-v2/%s-%s.wav" % [kind,suffix]

func play(kind: String, level: int = 1, gain: float = 0.0, seconds: float = 0.0, distinct: bool = false) -> void:
	if world.muted or (not distinct and clock<float(sound_gates.get(kind,-1))): return
	if kind=="wind-hit":
		var active_hits:=0
		for voice in voices:
			if voice.playing and voice.get_meta("cue","")=="wind-hit": active_hits+=1
		if active_hits>=2: return # shared across every victim and active tornado
	var path:=sound_path(kind,level)
	if not sound_cache.has(path):
		if not ResourceLoader.exists(path): return
		sound_cache[path]=load(path)
	for voice in voices:
		if voice.playing: continue
		voice.stream=sound_cache[path]
		voice.volume_db=lerpf(-4,-2,float(level-1)/9)+gain
		voice.pitch_scale=voice.stream.get_length()/seconds if seconds>0 else lerpf(1.025,0.975,float(level-1)/9)+randf_range(-0.012,0.012)
		if kind=="fire-sequence" or (kind=="ice" and level==1): voice.pitch_scale=1.0
		if kind=="wind-hit":
			voice.volume_db-=3
			voice.pitch_scale=1.0 # preserve the supplied hit's rhythm and timbre
		voice.set_meta("cue",kind)
		voice.play()
		sound_events.append({"kind":kind,"at":clock,"level":level,"path":path,"volume_db":voice.volume_db,"pitch":voice.pitch_scale,"duration":voice.stream.get_length()/voice.pitch_scale})
		if sound_events.size()>96: sound_events.pop_front()
		sound_gates[kind]=clock+(0.22 if kind=="wind-hit" else (0.08 if kind in ["hurt","death"] else 0.12))
		break
