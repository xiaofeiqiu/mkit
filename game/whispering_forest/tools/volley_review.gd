extends RefCounted

const Timing = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")
const FireCue = preload("res://game/whispering_forest/scripts/combat/fire_cue.gd")
const KINDS := ["fire","wind","earth","ice"]

func prepare(world: Node, review: Node, index: int, count: int = 5, speed: float = 0) -> void:
	review.prepare(10000,count)
	world.spells.levels.fill(1)
	world.spells.modifiers={"projectiles":count-1,"speed":speed}
	# Five distinct points inside the target-selection range, with readable gaps.
	var points: Array[Vector2]=[Vector2(40,-60),Vector2(110,-60),Vector2(110,10),Vector2(40,10),Vector2(-30,10)]
	for i in range(world.enemies.size()): world.enemies[i].ground=points[i%points.size()]
	world.spells.cast(index,world.enemies[0])

func bodies(world: Node, index: int) -> Array:
	return world.spells.visuals.filter(func(v): return v.kind==KINDS[index])

func test(world: Node, review: Node) -> void:
	for index in range(4):
		prepare(world,review,index)
		var start: float=world.spells.clock
		review.check(bodies(world,index).size()==1 and world.spells.releases.size()==4,"Only the first of five elemental objects exists immediately after release")
		world.spells.advance(0.199)
		review.check(bodies(world,index).size()==1,"The second object cannot appear early")
		world.spells.advance(0.002)
		review.check(bodies(world,index).size()==2 and bodies(world,index)[1].age<0.002,"A delayed object starts at age zero instead of inheriting the frame's elapsed time")
		# Moving/losing the original target cannot drag or invalidate queued areas.
		world.enemies[0].ground+=Vector2(200,0)
		world.spells.advance(0.599)
		var released:=bodies(world,index)
		review.check(released.size()==5 and world.spells.releases.is_empty(),"All five objects release within 0.8 seconds, without waiting for animation completion")
		for i in range(world.spells.release_events.size()):
			var e: Dictionary=world.spells.release_events[i]
			review.check(absf(e.at-start-i*0.2)<0.0001,"The five releases follow 0 / 0.2 / 0.4 / 0.6 / 0.8 seconds")
			if i<released.size():
				review.check(absf(released[i].age-(0.8-i*0.2))<0.0001,"Each object preserves its own complete local animation clock")
				if index!=1:
					review.check(released[i].fixed_ground==Vector2(e.target[0],e.target[1]),"Delayed stationary spells preserve their selected world points")
		if index==0:
			var tail: Node2D=released[-1]
			world.spells.advance(FireCue.duration()-0.001)
			review.check(is_instance_valid(tail) and not tail.is_queued_for_deletion(),"The final fire retains its full sound-length lifetime after release")
			world.spells.advance(0.002)
			review.check(bodies(world,index).is_empty(),"The final fire finishes at its own sound endpoint")
		elif index==3:
			# With the quicker ice, its first hit precedes the final queued
			# release. Start a fresh sample and observe that boundary directly.
			prepare(world,review,index)
			start=world.spells.clock
			world.spells.advance(Timing.ICE_PEAK-0.001)
			review.check(world.spells.sound_events.is_empty(),"No delayed ice plays impact audio before the first peak")
			world.spells.advance(0.002)
			var ice_hits: Array=world.spells.sound_events.filter(func(e): return e.kind=="ice")
			var peak_frame: int=preload("res://game/whispering_forest/scripts/combat/vfx_frames.gd").solid_data("ice").peak_frame
			released=bodies(world,index)
			review.check(ice_hits.size()==1 and released[0].ice_frame()==peak_frame and released[-1].ice_frame()<peak_frame,"The first ice spear hits at its own peak while the last is still gathering")
			review.check(not world.spells.releases.is_empty(),"Quick ice impacts while later ice objects are still queued")
			for j in range(85): world.spells.advance(0.01)
			ice_hits=world.spells.sound_events.filter(func(e): return e.kind=="ice")
			review.check(ice_hits.size()==5,"Every sequential ice peak receives its own sound")
			for j in range(ice_hits.size()):
				review.check(absf(ice_hits[j].at-start-(Timing.ICE_PEAK+j*0.2))<0.011,"Each pillar's impact sound follows its own rise duration")
		# Release speed shortens only the release window, never the animation.
		prepare(world,review,index,5,1.0)
		world.spells.advance(0.4)
		review.check(world.spells.release_events.size()==5 and world.spells.releases.is_empty(),"Release-speed modifiers shorten the five-object window to 0.4 seconds")
		if index==0: review.check(is_equal_approx(bodies(world,index)[-1].duration,FireCue.duration()),"Faster release does not accelerate the fire's audio or animation")
		prepare(world,review,index)
		world.paused=true
		world.step(1.0)
		review.check(world.spells.release_events.size()==1 and world.spells.releases.size()==4,"Pause freezes unreleased elements")
		world.paused=false
		world.spells.reset()
		world.spells.advance(2)
		review.check(world.spells.release_events.is_empty() and world.spells.visuals.is_empty() and world.spells.releases.is_empty(),"Reset clears unreleased objects and their future sounds/damage")
	# Preserve the existing per-cast fire/ice victim budget as timing changes.
	for index in [0,3]:
		review.prepare(10000,1)
		world.spells.levels.fill(1); world.spells.modifiers={"projectiles":4}
		var damage: float=Timing.definition(index,1,world.spells.modifiers).damage
		world.spells.cast(index,world.enemies[0])
		world.spells.advance(2.1)
		review.check(is_equal_approx(world.enemies[0].health.current_hp,10000-damage),"Staggering alone does not multiply fire/ice damage against one overlapping victim")
	# Concurrent casts share a sorted release queue, but never a clock or level.
	prepare(world,review,0)
	var start: float=world.spells.clock
	world.spells.advance(0.1)
	world.spells.cast(3,world.enemies[1])
	world.spells.levels[3]=10
	world.spells.modifiers.clear()
	world.spells.advance(0.8)
	var fire_events: Array=world.spells.release_events.filter(func(e): return e.index==0)
	var ice_events: Array=world.spells.release_events.filter(func(e): return e.index==3)
	review.check(fire_events.size()==5 and ice_events.size()==5,"Overlapping fire and ice casts retain all five releases independently")
	if fire_events.size()==5 and ice_events.size()==5:
		review.check(absf(fire_events[-1].at-start-0.8)<0.0001 and absf(ice_events[-1].at-start-0.9)<0.0001,"Each overlapping cast owns its own 0.8-second release window")
		for e in ice_events: review.check(e.level==1,"Queued releases keep the cast's level after later player upgrades")
	prepare(world,review,3)
	var removed: WFActor=world.enemies.pop_front()
	removed.queue_free()
	world.spells.advance(0.8)
	review.check(world.spells.release_events.size()==5,"Removing the original enemy cannot invalidate the remaining value-snapshot releases")
	for index in range(4):
		prepare(world,review,index,1)
		review.check(world.spells.release_events.size()==1 and world.spells.releases.is_empty(),"A single element releases immediately without an artificial wait")
	world.spells.modifiers.clear()
	world.spells.reset()

func preview(world: Node, review: Node) -> void:
	world.set_process_input(false)
	world.set_process_unhandled_input(false)
	world.set_process_unhandled_key_input(false)
	var trace: Array=[]
	for index in [3,2,1,0]:
		review.prepare(10000,5)
		world.paused=false; world.muted=false; world.dialogue.clear()
		world.toast("%s ×5 · 0.8 秒内依次释放 · 动画独立播放" % Timing.ZH[index],"%s ×5 · staggered within 0.8 s · independent animations" % Timing.EN[index],999)
		await review.render_frames(15)
		prepare(world,review,index)
		var start: float=world.spells.clock
		var count: int=[90,300,105,135][index]
		for frame in range(count):
			await review.render_frames(1)
			if frame in [0,5,11,17,23,35,48]:
				await RenderingServer.frame_post_draw
				review.get_viewport().get_texture().get_image().save_png("res://game/whispering_forest/preview/volley-v7-%d-%02d.png" % [index,frame])
		var events: Array=world.spells.release_events.duplicate(true)
		if events.size()!=5 or events[-1].at-start>0.801:
			push_error("Volley preview did not release five elements within its window")
			review.get_tree().quit(1); return
		trace.append({"index":index,"start":start,"releases":events,"sounds":world.spells.sound_events.duplicate(true)})
	var file:=FileAccess.open("res://game/whispering_forest/preview/volley-v7-events.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(trace,"\t")+"\n"); file.close()
	print("WF_VOLLEY_PREVIEW_OK: four elements, five releases each, 0.8-second release windows, complete animations")
	review.get_tree().quit()
