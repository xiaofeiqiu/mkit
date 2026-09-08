extends RefCounted

const Frames = preload("res://game/whispering_forest/scripts/combat/vfx_frames.gd")
const Timing = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")

func ice_events(world: Node) -> Array:
	return world.spells.sound_events.filter(func(e): return e.kind=="ice")

func test(world: Node, review: Node) -> void:
	var audio: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/whispering_forest/assets/ice-audio-v8/manifest.json"))
	var fire: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/whispering_forest/assets/fire-audio-v5/manifest.json"))
	review.check(audio.original_filename=="冰1.wav" and audio.source_sha256!=fire.reference.sha256,"Ice uses the distinct 冰1.wav recording, not the fire reference again")
	review.check(FileAccess.get_sha256("res://game/whispering_forest/"+str(audio.source))==audio.source_sha256,"The saved ice source matches its recorded identity")
	review.check(FileAccess.get_sha256("res://game/whispering_forest/assets/ice-audio-v8/hit-level-1.wav")==audio.sha256,"The actual ice WAV matches the corrected export")
	var asset: Dictionary=Frames.solid_data("ice")
	var heights: Array=asset.heights_metres
	var peak_index: int=heights.find(heights.max())
	var peak_time: float=asset.times[peak_index]
	review.check(is_equal_approx(Timing.ICE_HIT,peak_time),"Ice damage time matches the tallest exported model pose, not a separate earlier timer")
	for rank in [1,10]:
		for step in [1.0/120,1.0/30,0.125]:
			review.prepare(10000,5)
			world.spells.levels[3]=rank
			world.impact.sound_events.clear()
			var target: WFActor=world.enemies[0]
			var hp: float=target.health.current_hp
			world.spells.cast(3,target)
			var ice: Node2D=world.spells.visuals[0]
			var start: float=world.spells.clock
			var time:=0.0
			while time+step<peak_time-0.00001:
				world.spells.advance(step)
				time+=step
				review.check(target.health.current_hp==hp and target.frozen_for==0 and world.spells.sound_events.is_empty(),"No ice damage, freeze or sound during the stamp and rising phases")
			world.spells.advance(step)
			time+=step
			# Avoid a binary floating-point boundary landing infinitesimally short.
			if time<peak_time+0.000001: world.spells.advance(0.00001)
			review.check(target.health.current_hp<hp and target.frozen_for>0 and ice.ice_frame()==float(peak_index),"Damage and freeze arrive on the maximum-height ice pose at 120/30/8 updates per second")
			var heard:=ice_events(world)
			review.check(heard.size()==1,"One peak cue per ice cast, including multiple pillars and victims")
			if not heard.is_empty():
				review.check(heard[0].at-start>=peak_time-0.00001 and heard[0].at-start<=peak_time+step+0.0001,"Ice sound begins on the same update as peak damage")
				if rank==1:
					review.check(heard[0].path.ends_with("ice-audio-v8/hit-level-1.wav") and is_equal_approx(heard[0].pitch,1),"Level-one peak uses the distinct ice recording at its original pitch")
				else:
					review.check(heard[0].path.ends_with("spell-audio-v2/ice-full.wav"),"Level-ten ice retains its own stronger recording")
			var after: float=target.health.current_hp
			world.spells.advance(0.1)
			review.check(target.health.current_hp==after and ice_events(world).size()==1,"The held maximum-height pose does not repeat damage or audio")
			for event in world.impact.sound_events:
				review.check(event.kind!="water","The previous generic water impact does not double the new peak cue")
	world.spells.levels[3]=1
	review.prepare(10000,1)
	world.spells.cast(3,world.enemies[0])
	world.spells.advance(Timing.ICE_PEAK*0.5)
	world.spells.reset()
	world.spells.advance(1.2)
	review.check(world.enemies[0].health.current_hp==10000 and world.spells.sound_events.is_empty(),"Cancelling before peak clears both pending damage and its sound")

func preview(world: Node, review: Node) -> void:
	world.set_process_input(false)
	world.set_process_unhandled_input(false)
	world.set_process_unhandled_key_input(false)
	var trace: Array=[]
	for take in range(2):
		review.prepare(10000,3)
		world.spells.levels.fill(1)
		world.paused=false; world.muted=false; world.dialogue.clear()
		world.toast("霜白冰刺 · 实心碎裂 · 0.42 秒刺出命中","White Ice · solid fracture · impact at 0.42 s",999)
		await review.render_frames(15)
		var target: WFActor=world.enemies[take]
		var hp: float=target.health.current_hp
		world.spells.cast(3,target)
		var ice: Node2D=world.spells.visuals[0]
		var start: float=world.spells.clock
		var hit_at: float=-1
		var hit_pose: float=-1
		for frame in range(60):
			await review.render_frames(1)
			if target.health.current_hp<hp and hit_at<0:
				hit_at=world.spells.clock-start
				hit_pose=ice.ice_frame()
			if take==0 and frame in [3,6,8,10,12,15,20,28,38,44]:
				await RenderingServer.frame_post_draw
				review.get_viewport().get_texture().get_image().save_png("res://game/whispering_forest/preview/ice-16-%02d.png" % frame)
		if hit_at<Timing.ICE_PEAK or hit_pose!=float(Frames.solid_data("ice").peak_frame) or ice_events(world).size()!=1:
			push_error("Ice preview did not hit once at the maximum-height pose")
			review.get_tree().quit(1); return
		trace.append({"take":take+1,"start":start,"damage_at":hit_at,"pose_at_hit":hit_pose,"events":world.spells.sound_events.duplicate(true)})
	var file:=FileAccess.open("res://game/whispering_forest/preview/ice-16-events.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(trace,"\t")+"\n")
	file.close()
	print("WF_ICE_PREVIEW_OK: silent growth; maximum-height pose, damage, freeze and supplied audio together")
	review.get_tree().quit()
