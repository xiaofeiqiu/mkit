extends Node

const Tuning = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
var world: Node
var failures: Array[String] = []
var screenshots:=false
var refinement:=false
var meteor_audio:=false
var wind_review:=false
var fire_review:=false
var ice_review:=false
var volley_review:=false

func _ready() -> void:
	world.simulation=true
	for arg in OS.get_cmdline_user_args():
		if arg=="--wf-combat-stills": screenshots=true
		if arg=="--wf-spell-refinement": refinement=true
		if arg=="--wf-meteor-audio": meteor_audio=true
		if arg=="--wf-wind-review": wind_review=true
		if arg=="--wf-fire-review": fire_review=true
		if arg=="--wf-ice-review": ice_review=true
		if arg=="--wf-volley-review": volley_review=true
	run.call_deferred()

func prepare(hp: float = 1000, count: int = 5) -> void:
	if world.get("impact")!=null: world.impact.reset()
	world.spells.reset()
	world.expedition.reset()
	for enemy in world.enemies: enemy.queue_free()
	world.enemies.clear()
	world.stage=3; world.wave=1
	world.auto_attack=false
	world.meteor_timer=0
	world.skill_cooldowns.fill(0.0)
	world.player.ground=Vector2(-100,100)
	world.player.last_ground=world.player.ground
	world.player.health.revive(1)
	world.player.invincible=1000
	world.player.stats_component.set_base_stat("crit_chance",0)
	world.player.position=WFIso.project(world.player.ground)
	world.camera.position=Vector2(0,-65)
	world.camera.zoom=Vector2.ONE*1.05
	for i in range(count):
		var at:=Vector2(65+(i%3)*36,-25+int(i/3)*47)
		var enemy: WFActor=world._actor("goblin",at,hp)
		enemy.cooldown=1000
		enemy.health.died.connect(func(_node): world._enemy_died(enemy))
		world.enemies.append(enemy)

func run() -> void:
	world.stage=3
	world._change_area("dungeon")
	world.arrival_glow=0
	world.ambient.stop()
	if world.combat_test:
		await test()
	else:
		await preview()

func check(ok: bool, note: String) -> void:
	if not ok:
		failures.append(note)
		print("WF_COMBAT_CHECK_FAILED: "+note)

func release_cast() -> void:
	if world.get("impact")!=null: world.impact.advance(0.181)

func test() -> void:
	for error in preload("res://game/whispering_forest/tools/spell_asset_checks.gd").failures(): check(false,error)
	prepare()
	var target: WFActor=world.nearest_enemy(430)
	var hp: float=target.health.current_hp
	check(world.cast_skill(0),"Fire casts at an enemy")
	check(not world.cast_skill(0),"Cooldown rejects a duplicate cast")
	release_cast()
	world.spells.advance(0.07)
	check(target.health.current_hp==hp,"Fire does not deal damage before ignition")
	world.spells.advance(0.04)
	check(target.health.current_hp<hp and world.enemies[4].health.current_hp<hp,"Fire damages multiple enemies around its target")
	target.step(0.09)
	check(target.animation_state=="hurt","Damage enters articulated hurt animation")
	prepare()
	target=world.nearest_enemy(430)
	hp=target.health.current_hp
	world.cast_skill(2)
	release_cast()
	world.spells.advance(0.90)
	check(target.health.current_hp==hp,"Earth damage waits for the falling rock")
	world.spells.advance(0.06)
	check(target.health.current_hp<hp,"Earth damage occurs on impact")
	prepare()
	world.spells.levels[2]=10
	world.spells.cast(2,world.enemies[0])
	world.spells.advance(Tuning.MULTI_RELEASE_WINDOW+0.01)
	var rock_variants: Dictionary = {}
	for v in world.spells.visuals:
		if v.kind=="earth": rock_variants[v.rock_index]=true
	check(rock_variants.size()==4,"One L10 meteor volley uses four distinct dirty-rock silhouettes")
	world.spells.levels[2]=1
	prepare()
	target=world.nearest_enemy(430)
	world.player.health.current_hp=40
	hp=target.health.current_hp
	world.cast_skill(3)
	release_cast()
	world.spells.advance(Tuning.ICE_PEAK-0.01)
	check(target.health.current_hp==hp and target.frozen_for==0,"Ice does not hurt or freeze its target while still growing")
	world.spells.advance(0.02)
	check(world.player.health.current_hp==40 and target.frozen_for>0,"Ice rises under enemies, freezes, and no longer heals")
	prepare()
	target=world.enemies[0]
	world.cast_skill(1)
	release_cast()
	var tornado: Dictionary=world.spells.tornadoes[0]
	tornado.at=target.ground
	hp=target.health.current_hp
	world.spells.advance(0.01)
	var after_hit: float=target.health.current_hp
	world.spells.advance(0.01)
	check(after_hit<hp and target.health.current_hp==after_hit,"Tornado damage is rate limited per enemy")
	tornado.at=target.ground
	world.spells.advance(0.31)
	check(target.health.current_hp<after_hit,"Tornado can hurt the same enemy again after its tick interval")
	tornado.at=Vector2(516,0); tornado.direction=Vector2.RIGHT
	var before_bounces: int=tornado.bounces
	world.spells.advance(0.10)
	check(tornado.direction.x<0 and tornado.bounces==before_bounces-1,"A wall reflects the tornado and consumes one bounce")
	tornado.at=Vector2(-516,0); tornado.direction=Vector2.LEFT; tornado.bounces=0
	world.spells.advance(0.10)
	check(world.spells.tornadoes.is_empty(),"Tornado ends when its bounce budget is exhausted")
	var l1:=Tuning.definition(1,1)
	var l10:=Tuning.definition(1,10,{"bounces":3,"projectiles":2,"area":0.5})
	check(l10.bounces==7 and l1.bounces==1 and l10.radius>l1.radius and l10.count>l1.count,"Level and generic cards change physical tornado behavior")
	await test_spell_tails_and_roaming()
	await test_stages_and_spell_audio()
	test_meteor_audio()
	preload("res://game/whispering_forest/tools/wind_review.gd").new().test(world,self)
	preload("res://game/whispering_forest/tools/fire_review.gd").new().test(world,self)
	preload("res://game/whispering_forest/tools/ice_review.gd").new().test(world,self)
	preload("res://game/whispering_forest/tools/volley_review.gd").new().test(world,self)
	prepare(20,1)
	target=world.enemies[0]
	var before_kills: int=world.kills
	world.deal_damage(world.player,target,40,"fire")
	world._enemy_died(target)
	target.step(0.35)
	check(target.visible and target.animation_state=="death" and world.kills==before_kills+1,"Death animates before removal and rewards only once")
	target.step(0.65)
	check(target.sprite.self_modulate.a>0 and target.sprite.self_modulate.a<1,"The settled corpse fades after its fall")
	prepare(1000,1)
	world.rage=99
	check(not world.cast_skill(4),"Ultimate requires full rage")
	world.rage=100
	check(world.cast_skill(4) and world.rage==0,"Ultimate spends the full rage meter")
	world.step(1.31)
	check(world.meteor_timer<=0 and world.rage==0,"Ultimate cannot recharge itself")
	prepare()
	world._spawn_wave()
	world.expedition.advance(0.76)
	check(world.enemies.size()>=12,"Expedition begins with a pack rather than five static monsters")
	for i in range(120): world.expedition.advance(1.0)
	check(world.expedition.alive_count()==96 and world.enemies.size()==96,"Continuous waves are bounded at 96 live enemies")
	world.expedition.time=179.95
	world.expedition.advance(0.1)
	check(world.wave==2 and world.expedition.card_choices.size()==3,"Three-minute wave transition offers three cards")
	var before_time: float=world.expedition.time
	world.step(0.5)
	check(world.expedition.time==before_time,"Choosing a card freezes gameplay time")
	world.expedition.card_choices.clear()
	world.expedition.card_choices.append({"id":"bounces","zh":"折返轨迹","en":"Ricochet","rarity":2,"value":3})
	world.expedition.choose(0)
	check(world.spells.modifiers.bounces==3 and world.expedition.card_choices.is_empty(),"Selected ricochet card applies to the real spell")
	world.wave=4; world.expedition.time=719.95
	world.expedition.advance(0.1)
	check(world.wave==5 and is_instance_valid(world.expedition.boss),"Boss appears at the start of wave five, 12 minutes")
	check(world.expedition.boss.health.get_max_hp()==5000,"First-tier boss has its own HP budget")
	world.expedition.choose(0)
	world.expedition.time=899.95
	world.expedition.advance(0.1)
	check(world.expedition.failed and not world.expedition.active,"A living boss at 15 minutes ends the expedition")
	prepare()
	world.expedition.active=true; world.wave=5
	world.expedition.time=720
	world.expedition.spawn_boss()
	world.deal_damage(world.player,world.expedition.boss,100000,"meteor")
	world.expedition.advance(0.01)
	check(world.expedition.complete and not world.expedition.failed,"Defeating the final boss completes the expedition")
	world.spells.levels.assign([1,4,7,10])
	var data: Dictionary=world.profile.to_save_data()
	world.spells.levels.fill(1)
	world.profile.from_save_data(data)
	check(world.spells.levels==[1,4,7,10],"Skill levels round-trip in the profile")
	world.return_to_city()
	check(world.enemies.is_empty() and world.spells.visuals.is_empty() and not world.expedition.active and world.spells.modifiers.is_empty(),"Leaving an instance clears combat and temporary cards")
	await get_tree().process_frame
	if failures.is_empty(): print("WF_COMBAT_OK: damage timing, AOE, tornado ticks/reflection/budget, L1-L10, cards, hurt/death, rage, hordes, 180/720/900s, boss victory/timeout, save and city isolation")
	else:
		for failure in failures: push_error("WF_COMBAT_FAILED: "+failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func test_spell_tails_and_roaming() -> void:
	prepare()
	world.spells.levels[0]=10
	world.spells.cast(0,world.enemies[0])
	world.spells.advance(1.8)
	var flame: Node2D=world.spells.visuals[0]
	check(flame.kind=="fire" and flame.opacity()>0.4 and flame.opacity()<1,"Level-ten fire retains its longer gradual tail")
	var before: float=flame.opacity()
	world.spells.advance(0.35)
	check(is_instance_valid(flame) and flame.opacity()>0 and flame.opacity()<before,"Fire fades continuously before removal")
	world.spells.levels[0]=1
	prepare()
	world.spells.cast(2,world.enemies[0])
	world.spells.advance(1.3)
	var stone: Node2D=world.spells.visuals[0]
	var hp: float=world.enemies[0].health.current_hp
	check(stone.kind=="earth" and stone.age>stone.impact_at and stone.opacity()>0,"Meteor remains visible after landing")
	world.spells.advance(0.3)
	check(stone.opacity()>0 and stone.opacity()<0.5 and world.enemies[0].health.current_hp==hp,"Landed meteor fades without dealing extra damage")
	prepare()
	world.spells.cast(3,world.enemies[0])
	world.spells.advance(Tuning.ICE_LIFE-Tuning.ICE_FADE*0.5)
	check(is_equal_approx(world.spells.visuals[0].opacity(),1.0) and is_equal_approx(world.spells.visuals[0].self_modulate.a,1.0),"Ice stays opaque while its authored solid fragments break apart")
	world.spells.advance(Tuning.ICE_FADE*0.5+0.001)
	check(world.spells.visuals.is_empty(),"Solid ice fragments are removed at the end of the fast timeline")
	prepare()
	world.spells.cast(1,world.enemies[0])
	var tornado: Dictionary=world.spells.tornadoes[0]
	tornado.at=Vector2(516,0); tornado.direction=Vector2.RIGHT; tornado.bounces=0
	world.spells.advance(0.1)
	var wind: Node2D=tornado.visual
	check(world.spells.tornadoes.is_empty() and is_instance_valid(wind) and not wind.is_queued_for_deletion(),"Collision stops wind damage but preserves its visual tail")
	# Check a mature vortex so the fade starts after its birth fade-in.
	prepare()
	world.spells.cast(1,world.enemies[0])
	world.spells.advance(0.6)
	tornado=world.spells.tornadoes[0]
	tornado.at=Vector2(516,0); tornado.direction=Vector2.RIGHT; tornado.bounces=0
	tornado.motion.on_bounce()
	world.spells.advance(0.1)
	wind=tornado.visual
	before=wind.opacity()
	world.spells.advance(0.3)
	check(wind.opacity()>0 and wind.opacity()<before,"An exhausted mature vortex dissolves instead of disappearing at a wall")
	world.spells.advance(0.7)
	check(world.spells.visuals.is_empty(),"Faded tornado visuals are eventually released")
	var Motion=load("res://game/whispering_forest/scripts/combat/gale_motion.gd")
	var trajectory: Array[Vector2] = []
	for sample in range(2):
		var motion: RefCounted=Motion.new(814)
		var at:=Vector2.ZERO
		var direction:=Vector2.RIGHT
		var maximum_turn:=0.0
		for frame in range(900):
			var previous:=direction
			direction=motion.advance(direction,1.0/120)
			maximum_turn=maxf(maximum_turn,absf(previous.angle_to(direction)))
			at+=direction*float(motion.speed)/120
		check(motion.history.has("straight") and motion.history.has("turn") and motion.history.has("orbit"),"A full L1 lifetime contains straight, turning and orbit phrases")
		check(maximum_turn<0.025 and absf(at.y)>20,"Roaming changes course smoothly instead of jittering or staying on its launch line")
		trajectory.append(at)
	check(trajectory[0].distance_to(trajectory[1])<0.001,"Seeded roaming is reproducible for regression checks")
	var orbit: RefCounted=Motion.new(12)
	orbit.set_phrase("orbit",1)
	var heading:=Vector2.RIGHT
	var total_angle:=0.0
	var phrase_time: float=orbit.remaining
	for i in range(int(phrase_time*120)-1):
		var next: Vector2=orbit.advance(heading,1.0/120)
		total_angle+=heading.angle_to(next)
		heading=next
	check(total_angle>5.8,"Orbit behavior completes a loop, not just a slight bend")

func heard(kind: String) -> bool:
	for event in world.spells.sound_events:
		if event.kind==kind: return true
	return false

func test_stages_and_spell_audio() -> void:
	for index in range(4):
		prepare()
		world.spells.cast(index,world.enemies[0])
		check(world.spells.visuals[0].animation_frame_count()==Tuning.frame_count(["fire","wind","earth","ice"][index]),"The runtime uses every authored pose: ice 16, other elements pending migration")
	prepare(1000,2)
	var former_target: WFActor=world.enemies[0]
	var incoming: WFActor=world.enemies[1]
	var locked_at: Vector2=former_target.ground
	world.spells.cast(3,former_target)
	var anchored: Node2D=world.spells.visuals[0]
	former_target.ground+=Vector2(220,0)
	incoming.ground=locked_at
	var former_hp: float=former_target.health.current_hp
	var incoming_hp: float=incoming.health.current_hp
	for i in range(36):
		world.spells.advance(1.0/30)
		check(anchored.ground==locked_at and anchored.position.is_equal_approx(WFIso.project(locked_at)),"Ice keeps its world position while its former target leaves")
	check(former_target.health.current_hp==former_hp and former_target.frozen_for==0,"Escaping the fixed ice area avoids its damage and freeze")
	check(incoming.health.current_hp<incoming_hp and incoming.frozen_for>0,"A different enemy entering the locked ice area is hit")
	prepare()
	world.spells.cast(3,world.enemies[0])
	var ice: Node2D=world.spells.visuals[0]
	world.spells.advance(0.2)
	check(ice.ice_stage()=="gather" and ice.ice_height()==0 and world.spells.sound_events.is_empty(),"Water gathers silently before the ice breaks the surface")
	world.spells.advance(0.10)
	check(ice.ice_stage()=="rise" and ice.ice_height()>0 and world.spells.sound_events.is_empty(),"Ice erupts through the ground without an early hit cue")
	world.spells.advance(0.22)
	var peak: float=ice.ice_height()
	check(ice.ice_stage()=="peak" and peak>ice.radius*3 and heard("ice"),"Ice reaches a distinct tall peak with impact audio")
	world.spells.advance(0.18)
	check(ice.ice_stage()=="fracture" and is_equal_approx(ice.ice_height(),peak) and not heard("ice-settle"),"Ice fractures at its full height without shrinking or repeating the hit sound")
	prepare()
	world.spells.cast(2,world.enemies[0])
	var stone: Node2D=world.spells.visuals[0]
	check(heard("fall") and not heard("rock"),"Falling meteor sounds before impact, with no early crash")
	world.spells.advance(0.65)
	check(stone.trail.size()>5 and absf(stone.meteor_angle(0.65)-stone.meteor_angle(0.10))>1.5,"Meteor visibly rotates while leaving a continuous trail")
	world.spells.advance(0.33)
	check(heard("rock") and not stone.trail.is_empty(),"Crash sounds at impact while tail particles remain in the air")
	check(is_equal_approx(stone.meteor_angle(1.3),stone.meteor_angle(stone.impact_at)),"The landed stone stops flight rotation")
	world.spells.advance(0.5)
	check(stone.trail.is_empty(),"Historical tail particles disperse after impact")
	prepare()
	world.spells.levels[0]=10
	world.spells.cast(0,world.enemies[0])
	check(heard("fire-ignite") and not heard("fire"),"Fire has separate ignition and blast cues")
	world.spells.advance(0.37)
	check(heard("fire"),"Fire blast cue follows actual ignition damage")
	world.spells.levels[0]=1
	prepare()
	world.spells.cast(1,world.enemies[0])
	world.spells.advance(0.4)
	check(heard("wind") and heard("wind-loop") and world.spells.wind_voice.playing,"Tornado has an onset and a sustained rotating wind bed")
	world.spells.reset()
	check(not world.spells.wind_voice.playing and world.spells.audio_cues.is_empty(),"Reset clears sustained and scheduled spell sounds")
	prepare()
	world.rage=100
	world.cast_skill(4)
	check(heard("ultimate-seal") and not heard("ultimate-impact"),"Rage ultimate begins with its own seal sound")
	world.step(0.3)
	check(heard("ultimate-fall"),"Rage meteor has a distinct descent sound")
	world.step(1.01)
	check(heard("ultimate-impact"),"Rage ultimate crash matches its impact frame")

func test_meteor_audio() -> void:
	prepare()
	world.spells.levels[2]=1
	world.spells.cast(2,world.enemies[0])
	check(world.spells.sound_events[0].path.ends_with("meteor-audio-v3/fall-small.wav"),"Level-one rockfall loads the new airy descent")
	world.spells.advance(0.94)
	check(not heard("rock"),"No stone contact is audible while the meteor is still falling")
	world.spells.advance(0.02)
	check(world.spells.sound_events[-1].path.ends_with("meteor-audio-v3/rock-small.wav"),"Level-one contact loads the light impact only on landing")
	prepare()
	world.spells.levels[2]=10
	var start: float=world.spells.clock
	world.spells.cast(2,world.enemies[0])
	for i in range(185): world.spells.advance(0.01)
	var falls: Array=[]
	var hits: Array=[]
	for cue in world.spells.sound_events:
		if cue.kind=="fall": falls.append(cue)
		if cue.kind=="rock": hits.append(cue)
	check(falls.size()==4 and hits.size()==4,"All four level-ten stones retain separate wind and contact cues")
	if falls.size()==4 and hits.size()==4:
		for i in range(4):
			check(falls[i].path.ends_with("meteor-audio-v3/fall-full.wav") and hits[i].path.ends_with("meteor-audio-v3/rock-full.wav"),"Level-ten meteors use the heavy bank")
			var release_at: float=i*Tuning.MULTI_RELEASE_WINDOW/3.0
			check(absf(falls[i].at-start-release_at)<0.021 and absf(hits[i].at-start-0.95-release_at)<0.021,"Wind and crash follow each stone's own release and full descent")
	world.spells.levels[2]=1
	prepare()
	world.spells.start_ultimate_audio()
	world.spells.advance(0.25)
	check(world.spells.sound_events[-1].path.ends_with("meteor-audio-v3/ultimate-fall-full.wav"),"Ultimate descent loads the dedicated wind-and-fire mix")
	world.spells.reset()
	check(world.spells.audio_cues.is_empty(),"Reset discards scheduled meteor audio")

func render_frames(count: int, skill: int = -1, rank: int = 1) -> void:
	for frame in range(count):
		world.elapsed+=1.0/30
		if world.get("impact")!=null: world.impact.advance(1.0/30)
		world.spells.advance(1.0/30)
		world.effects.step(1.0/30)
		world.player.step(1.0/30)
		for enemy in world.enemies: enemy.step(1.0/30)
		world.hud.queue_redraw()
		await get_tree().process_frame
		if frame in [6,12,22,30,40,48,55,65,78,90,135,210,245] and skill>=0:
			await RenderingServer.frame_post_draw
			var path: String="res://game/whispering_forest/preview/combat-%d-L%d-%d.png" % [skill,rank,frame]
			get_viewport().get_texture().get_image().save_png(path)

func preview() -> void:
	if volley_review:
		await preload("res://game/whispering_forest/tools/volley_review.gd").new().preview(world,self)
		return
	if ice_review:
		await preload("res://game/whispering_forest/tools/ice_review.gd").new().preview(world,self)
		return
	if fire_review:
		await preload("res://game/whispering_forest/tools/fire_review.gd").new().preview(world,self)
		return
	if wind_review:
		await preload("res://game/whispering_forest/tools/wind_review.gd").new().preview(world,self)
		return
	if meteor_audio:
		await preview_meteor_audio()
		return
	for rank in ([1] if refinement else [1,10]):
		for index in range(4):
			prepare(95 if rank==1 else 180,5)
			world.spells.levels.fill(rank)
			world.toast_zh="%s · %d 级 · 实机效果" % [Tuning.ZH[index],rank]
			world.toast_en="%s · LEVEL %d · GAMEPLAY" % [Tuning.EN[index],rank]
			world.toast_timer=999
			world.player.invincible=0
			await render_frames(20)
			world.cast_skill(index)
			await render_frames(270 if index==1 else 120,index,rank)
			print("WF_COMBAT_PREVIEW: %s L%d" % [Tuning.IDS[index],rank])
	if refinement:
		prepare(1000,1)
		world.toast("冰柱固定落点 · 敌人离开后仍在原地长出","Ice stays at its locked ground point as the enemy leaves",999)
		world.spells.cast(3,world.enemies[0])
		for frame in range(120):
			if frame>8: world.enemies[0].ground+=Vector2(2.5,-0.7)
			await render_frames(1)
		prepare(1000,4)
		world.rage=100
		world.toast("炎印·火陨天降 · 结印 / 下坠 / 撞击音效","Ultimate · seal / descent / impact",999)
		await render_frames(20)
		world.cast_skill(4)
		for frame in range(150):
			world.player.invincible=100
			world.step(1.0/30)
			await get_tree().process_frame
	if not screenshots and not refinement:
		prepare(1000,0)
		world.spells.levels.fill(10)
		world._spawn_wave()
		world.expedition.queue_pack(64)
		world.toast("持续刷怪 · 分批涌入 · 最高 96 个存活敌人","Continuous packs · up to 96 living enemies",999)
		for frame in range(300):
			world.player.invincible=100
			world.toast_timer=999
			world.step(1.0/30)
			if frame%80==60: world.cast_skill(int(frame/80)%4)
			await get_tree().process_frame
		world.expedition.time=719.95
		world.wave=4
		world.step(0.1)
		world.toast("第 5 波 · 首领入场 · 12:00","Wave 5 · boss arrives · 12:00",999)
		for frame in range(75): await get_tree().process_frame
		world.expedition.choose(0)
		for frame in range(120):
			world.player.invincible=100
			world.step(1.0/30)
			await get_tree().process_frame
	print("WF_COMBAT_PREVIEW_OK")
	get_tree().quit()

func preview_meteor_audio() -> void:
	var trace: Array=[]
	for rank in [1,10]:
		prepare(10000,4)
		world.spells.levels.fill(rank)
		world.toast("陨石术 · %d 级 · 下坠风声 / 石体撞击" % rank,"Rockfall · L%d · rushing wind / stone impact" % rank,999)
		await render_frames(15)
		world.cast_skill(2)
		await render_frames(110)
		trace.append({"skill":"earth","level":rank,"events":world.spells.sound_events.duplicate(true)})
	prepare(10000,4)
	world.rage=100
	world.toast("火陨终极 · 风啸与燃烧 / 重击与余焰","Fire meteor · wind and fire / impact and afterburn",999)
	await render_frames(15)
	world.cast_skill(4)
	for frame in range(150):
		world.player.invincible=100
		world.step(1.0/30)
		await get_tree().process_frame
	trace.append({"skill":"ultimate","level":10,"events":world.spells.sound_events.duplicate(true)})
	var log_file:=FileAccess.open("res://game/whispering_forest/preview/meteor-audio-v3-events.json",FileAccess.WRITE)
	log_file.store_string(JSON.stringify(trace,"\t")+"\n")
	log_file.close()
	print("WF_METEOR_AUDIO_PREVIEW_OK: L1 single / L10 four stones / ultimate wind-fire mix")
	get_tree().quit()
