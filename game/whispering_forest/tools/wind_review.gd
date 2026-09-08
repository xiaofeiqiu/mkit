extends RefCounted

func hit_events(world: Node) -> Array:
	return world.spells.sound_events.filter(func(e): return e.kind=="wind-hit")

func test(world: Node, review: Node) -> void:
	for rank in [1,10]:
		review.prepare(10000,8)
		world.spells.levels[1]=rank
		world.spells.cast(1,world.enemies[0])
		world.spells.advance(0.01)
		review.check(hit_events(world).is_empty(),"Wind launch in empty space does not play the contact recording")
		# A cast retains its own level even if the player's level changes in flight.
		world.spells.levels[1]=1
		var tornado: Dictionary=world.spells.tornadoes[0]
		for enemy in world.enemies: enemy.ground=tornado.at
		world.impact.sound_events.clear()
		world.spells.advance(0.01)
		var hits:=hit_events(world)
		review.check(hits.size()==1,"A simultaneous crowd contact plays one wind hit rather than a cue per victim")
		if not hits.is_empty():
			var suffix: String="full" if rank==10 else "small"
			review.check(hits[0].path.ends_with("wind-audio-v4/hit-%s.wav" % suffix) and hits[0].level==rank,"Wind contact selects the supplied L1/L10 recording using the cast level")
			review.check(is_equal_approx(hits[0].pitch,1.0),"Wind contact preserves the supplied recording's pitch")
		for event in world.impact.sound_events:
			review.check(event.kind!="wind","The previous generic wind impact does not double the supplied cue")
		var hp: float=world.enemies[0].health.current_hp
		world.spells.advance(0.01)
		review.check(hit_events(world).size()==1 and world.enemies[0].health.current_hp==hp,"Audio gate and per-victim damage interval suppress immediate retrigger")
		# Audio pool protection is independent from combat clock speed.
		world.spells.clock+=0.23
		world.spells.play("wind-hit",rank)
		world.spells.clock+=0.23
		world.spells.play("wind-hit",rank)
		review.check(hit_events(world).size()==2,"At most two supplied wind contact tails overlap across all tornadoes")
		review.prepare(10000,1)
		world.spells.levels[1]=rank
		world.spells.cast(1,world.enemies[0])
		for t in world.spells.tornadoes:
			t.at=Vector2(516,0); t.direction=Vector2.RIGHT; t.motion.on_bounce()
		world.spells.advance(0.05)
		review.check(hit_events(world).is_empty(),"A wall reflection without an enemy does not play the hit recording")
	world.spells.levels[1]=1
	world.spells.reset()

func preview(world: Node, review: Node) -> void:
	var trace: Array=[]
	# This isolated capture drives the spell directly and ignores live keyboard
	# input. Gameplay's queued cast path is covered by the combat regression.
	world.set_process_input(false)
	world.set_process_unhandled_input(false)
	world.set_process_unhandled_key_input(false)
	seed(9841)
	for rank in [1,10]:
		review.prepare(10000,24)
		world.paused=false
		world.muted=false
		world.dialogue.clear()
		world.spells.levels.fill(rank)
		world.camera.zoom=Vector2.ONE*0.95
		world.toast("龙卷 · %d 级 · 8 帧 / 8 fps · 命中音效" % rank,"Tornado · L%d · 8 frames / 8 fps · contact audio" % rank,999)
		# A fixed group allows the real swept collision to choose hit moments.
		for i in range(world.enemies.size()):
			world.enemies[i].ground=Vector2(-20+(i%6)*48,-65+int(i/6)*48)
		await review.render_frames(15)
		world.spells.cast(1,world.nearest_enemy(430))
		await review.render_frames(390 if rank==10 else 300,1,rank)
		if hit_events(world).is_empty():
			push_error("Wind preview has no real contacts at level %d" % rank)
			review.get_tree().quit(1)
			return
		trace.append({"level":rank,"events":world.spells.sound_events.duplicate(true)})
	var log_file:=FileAccess.open("res://game/whispering_forest/preview/wind-v4-events.json",FileAccess.WRITE)
	log_file.store_string(JSON.stringify(trace,"\t")+"\n")
	log_file.close()
	print("WF_WIND_PREVIEW_OK: 8 poses / 8 fps, L1 and L10 real swept hits, supplied contact cues")
	review.get_tree().quit()
