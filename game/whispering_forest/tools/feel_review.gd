extends Node

var world: Node
var failures: Array[String] = []
var checks := 0
var title: Label
var subtitle: Label

func _ready() -> void:
	world.simulation = true
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func prepare(hp: float = 1000.0) -> WFActor:
	world.stage = 3
	world._change_area("dungeon")
	world.auto_attack = false
	world.muted = false
	world.arrival_glow = 0
	world.dialogue.clear()
	world.player.ground = Vector2(-80,65)
	world.player.last_ground = world.player.ground
	world.player.position = WFIso.project(world.player.ground)
	world.player.invincible = 0
	world.player.stats_component.set_base_stat("crit_chance",0)
	world.player.face(Vector2(1,-0.5))
	world.attack_cooldown = 0
	world.skill_cooldowns.fill(0.0)
	world.impact.sound_events.clear()
	world.impact.sound_gates.clear()
	world.camera.position = WFIso.project(Vector2(0,25))+Vector2(0,-40)
	world.camera.zoom = Vector2.ONE*1.5
	var enemy: WFActor = world._actor("goblin",Vector2(55,15),hp)
	enemy.set_meta("speed",0.0)
	enemy.face(world.player.ground-enemy.ground)
	enemy.cooldown = 100
	enemy.health.died.connect(func(_node): world._enemy_died(enemy))
	world.enemies.append(enemy)
	return enemy

func run() -> void:
	if world.feel_test: await test()
	else: await movie()

func test() -> void:
	var target := prepare()
	check(world.player.clips.idle[0][0].atlas.resource_path.contains("/world-motion/"),"live player loads the shared-camera character assets")
	check(world.portrait_texture().atlas.resource_path.contains("/world-motion/"),"HUD portrait loads the same rebuilt mage")
	check(world.perform_attack(),"basic attack accepted")
	check(world.projectiles.is_empty(),"no projectile before the staff release")
	for i in range(10): world.step(1.0/60)
	check(world.projectiles.is_empty(),"anticipation lasts through 166ms")
	world.step(1.0/60)
	check(world.projectiles.size()==1,"projectile launches at the 180ms release marker")
	check(world.projectiles[0].muzzle.distance_to(world.player.staff_tip_offset())<0.001,"projectile release uses the baked crystal-tip attachment")
	for i in range(45):
		world.step(1.0/60)
		if target.health.current_hp<1000: break
	check(target.health.current_hp==988,"projectile applies unchanged basic damage once")
	check(target.get("hitstop_remaining")>0 and target.get("stagger_remaining")>0,"contact triggers local hitstop and gameplay stagger")
	check(target.animation_state=="hurt" and not world.impact.sparks.is_empty(),"hurt pose and spark appear at contact")
	check(world.impact.sound_events.any(func(e): return e.kind=="physical"),"contact emits physical impact audio")
	var at: Vector2 = target.ground
	var texture: Texture2D = target.sprite.texture
	var player_at: Vector2 = world.player.ground
	world.showcase_mode = true
	world.showcase_direction = Vector2(0,1)
	world.step(0.01)
	world.showcase_mode = false
	check(target.ground==at and target.sprite.texture==texture,"victim position and pose hold during hitstop")
	check(world.player.ground.distance_to(player_at)>0.5 and Engine.time_scale==1.0,"remote hits do not freeze player input")
	for i in range(25): world.step(1.0/60)
	check(target.ground.distance_to(at)>3 and not target.call("is_recovering"),"recoil moves over time and recovers")
	target = prepare()
	world.showcase_mode = true
	world.showcase_direction = Vector2(0,1)
	world.perform_attack()
	world.step(0.05)
	check(world.player.get("rendered_action")=="cast_walk","walking preserves upper-body casting")
	check(world.player.sprite.texture.region.size==Vector2(320,320) and world.player.sprite.offset.distance_to(-world.player.PerformanceFrames.pivot_for("cast_walk"))<0.001,"moving cast has wand clearance without shifting the shared ground anchor")
	world.showcase_mode = false
	target = prepare()
	check(world.cast_skill(0),"elemental spell starts anticipation")
	check(not world.cast_skill(1),"second spell cannot silently replace an unreleased cast")
	world.step(0.10)
	check(target.health.current_hp==1000,"spell cannot hit during anticipation")
	for i in range(32): world.step(1.0/60)
	check(target.health.current_hp<1000,"spell resolves after release and ignition")
	target = prepare()
	target.ground = Vector2(518,0)
	world.player.ground = Vector2(450,0)
	world.deal_damage(world.player,target,1,"meteor")
	for i in range(45): target.step(1.0/60)
	check(world.walkable(target.ground) and target.ground.x<=520.01,"heavy recoil respects the dungeon boundary")
	target = prepare()
	target.set_meta("boss",true)
	world.deal_damage(world.player,target,1,"physical")
	check(not target.call("is_recovering"),"basic hit cannot stun a boss with full poise")
	for i in range(7): world.deal_damage(world.player,target,1,"physical")
	check(target.get("stagger_remaining")>0,"repeated hits eventually break boss poise")
	for i in range(40): target.step(1.0/60)
	world.deal_damage(world.player,target,1,"meteor")
	check(not target.call("is_recovering"),"boss recovery grace prevents an immediate second stun")
	target = prepare()
	for i in range(20): world.deal_damage(world.player,target,1,"physical")
	check(target.get("hitstop_remaining")<=0.04,"simultaneous hits do not add twenty pauses")
	check(world.impact.sound_events.size()==1,"dense identical impacts merge for audio headroom")
	check(world.impact.camera_strength<1.0,"dense light hits do not accumulate camera shake")
	target = prepare(10)
	world.deal_damage(world.player,target,12,"physical")
	target.step(0.20)
	check(target.health.dead and target.visible and target.animation_state=="death","lethal hit retains an animated corpse")
	target.step(0.85)
	check(target.sprite.self_modulate.a>0 and target.sprite.self_modulate.a<1,"corpse settles and fades gradually")
	target = prepare()
	world.perform_attack()
	world.return_to_city()
	world.step(0.25)
	check(world.impact.casts.is_empty() and world.projectiles.is_empty() and world.enemies.is_empty(),"returning to town cancels pending attacks")
	target=prepare()
	world.showcase_mode=true
	world.showcase_direction=Vector2(0,1)
	for i in range(40): world.step(1.0/60)
	check(world.player.rendered_action=="run" and world.player.clips.run[0].size()==16,"normal gameplay speed uses the full light-run cycle")
	check(world.player.sprite.scale==Vector2.ONE*0.5,"character retains the same export scale as city assets")
	world.showcase_mode=false
	world.step(1.0/60)
	check(world.player.rendered_action.begins_with("stop"),"release movement enters a foot-phase stopping pose")
	# Check sustained input, not only one sampled run frame. An accidental gait
	# switch/restarted start clip can look like vibration even with a smooth rig.
	for direction in range(8):
		prepare()
		# All eight 180-unit rays fit in the clearing; the combat setup's offset
		# starts the westward ray beside the pond and legitimately stops movement.
		world.player.ground=Vector2.ZERO
		world.player.last_ground=Vector2.ZERO
		world.player.position=Vector2.ZERO
		world.showcase_mode=true
		world.showcase_direction=WFIso.unproject(Vector2.from_angle(direction*TAU/8)).normalized()
		var stable := true
		for frame in range(80):
			world.step(1.0/60)
			if frame>=9 and world.player.rendered_action!="run": stable=false
		check(stable,"sustained input keeps one run cycle without clip flicker in direction %d" % direction)
	world.showcase_mode=false
	world.return_to_city()
	var idle_frames := {}
	var saw_look := false
	for i in range(470):
		world.step(1.0/60)
		if world.player.rendered_action=="idle": idle_frames[world.player.animation_frame]=true
		if world.player.rendered_action=="look": saw_look=true
	check(idle_frames.size()==32,"standing in town plays all breathing and blink frames")
	check(saw_look,"extended idle triggers a separate observing gesture")
	check(world.mentor.animation_frame==0 and world.mentor.sprite.texture==world.mentor.clips.idle[world.mentor.facing][0],"town NPC keeps its fixed standing pose")
	await get_tree().process_frame
	if failures.is_empty(): print("WF_FEEL_OK: %d checks; release timing, moving cast, hitstop, stun, recoil, collision, boss poise, audio gates, death, city isolation" % checks)
	else:
		for failure in failures: push_error("WF_FEEL_FAILED: "+failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func labels() -> void:
	world.hud.visible = false
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.07,0.14,0.17,0.88)
	panel.position = Vector2(30,28)
	panel.size = Vector2(710,106)
	layer.add_child(panel)
	title = Label.new()
	title.position = Vector2(50,40)
	title.add_theme_font_override("font",world.effects.font)
	title.add_theme_font_size_override("font_size",25)
	layer.add_child(title)
	subtitle = Label.new()
	subtitle.position = Vector2(50,82)
	subtitle.add_theme_font_override("font",world.effects.font)
	subtitle.add_theme_font_size_override("font_size",16)
	subtitle.modulate = Color("bfdad9")
	layer.add_child(subtitle)

func frames(count: int, heading: Vector2 = Vector2.ZERO) -> void:
	for i in range(count):
		world.showcase_mode = heading!=Vector2.ZERO
		world.showcase_direction = heading
		world.step(1.0/60)
		world.camera.position = WFIso.project(Vector2(0,25))+Vector2(0,-40)
		world.hud.visible = false
		await get_tree().process_frame
	world.showcase_mode = false

func movie() -> void:
	if "--motion-only" in OS.get_cmdline_user_args():
		await motion_movie()
		return
	var target := prepare(260)
	labels()
	world.simulation = false
	world.set_process(false)
	world.ambient.stop()
	title.text = "人物动作 · 战斗待机与八方向移动"
	subtitle.text = "CHARACTER PERFORMANCE · gaze, weight, planted steps"
	await frames(100)
	for i in range(8): await frames(22,WFIso.unproject(Vector2.from_angle(i*TAU/8)).normalized())
	world.player.ground = Vector2(-80,65)
	world.player.last_ground = world.player.ground
	title.text = "普攻 · 挥杖出手 → 接触 → 受击退步"
	subtitle.text = "BASIC HIT · 38 ms local pause / 100 ms stagger"
	world.attack_cooldown = 0
	world.perform_attack()
	await frames(105)
	title.text = "移动施法 · 动作持续，视线锁定目标"
	subtitle.text = "MOVING CAST · legs move while the staff releases"
	world.perform_attack()
	await frames(42,Vector2(0,1))
	await frames(60)
	title.text = "暴击 · 更重的接触声与受击幅度"
	subtitle.text = "CRITICAL · stronger contact, recoil and number pop"
	world.player.stats_component.set_base_stat("crit_chance",1)
	world.perform_attack()
	await frames(105)
	world.player.stats_component.set_base_stat("crit_chance",0)
	title.text = "岩石重击 · 下坠与命中在同一时刻"
	subtitle.text = "HEAVY HIT · 75 ms pause / 260 ms stagger"
	world.cast_skill(2)
	await frames(130)
	target = prepare(12)
	title.text = "击倒 · 失衡 → 落地 → 收势消散"
	subtitle.text = "DEFEAT · a complete fall, with room for the silhouette"
	world.perform_attack()
	await frames(150)
	target = prepare(260)
	title.text = "终极 · 结印召唤火陨石"
	subtitle.text = "ULTIMATE · 110 ms pause / shockwave / weighted impact"
	world.rage = 100
	world.cast_skill(4)
	await frames(160)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://game/whispering_forest/preview/combat-feel-final.png")
	print("WF_FEEL_MOVIE_OK: live engine animation, damage, reactions and stereo sound")
	get_tree().quit()

func motion_movie() -> void:
	prepare()
	world.return_to_city()
	world.player.ground=Vector2(-60,60)
	world.player.last_ground=world.player.ground
	world.player.face(Vector2(1,0))
	world.player.reset_performance()
	world.player.position=WFIso.project(world.player.ground)
	world.camera.zoom=Vector2.ONE*1.5
	world.dialogue.clear()
	world.arrival_glow=0
	labels()
	world.simulation=false
	world.set_process(false)
	world.ambient.stop()
	title.text="城内待机 · 呼吸、眨眼、换重心与观察"
	subtitle.text="IDLE · planted feet / full-length upright staff / occasional glance"
	await frames(470)
	title.text="实际移动 · 起步 → 轻跑 → 停步"
	subtitle.text="LOCOMOTION · distance-matched steps / counter-swing / cloth follow-through"
	for direction in [Vector2(1,0),Vector2(-1,0),Vector2(0,-1),Vector2(0,1)]:
		await frames(42,direction)
		await frames(25)
	prepare(260)
	title.text="独立副本 · 抬杖 → 下压 → 杖头释放"
	subtitle.text="STAFF CAST · actual crystal origin / 180 ms release / impact sound"
	world.perform_attack()
	await frames(95)
	world.perform_attack()
	await frames(38,Vector2(0,1))
	await frames(65)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://game/whispering_forest/preview/long-staff-gameplay.png")
	print("WF_MOTION_GAMEPLAY_OK: live city idle, movement transitions, upright staff and actual projectile release")
	get_tree().quit()
