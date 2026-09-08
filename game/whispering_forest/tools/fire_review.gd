extends RefCounted

const Cue = preload("res://game/whispering_forest/scripts/combat/fire_cue.gd")

func test(world: Node, review: Node) -> void:
	for muted in [false,true]:
		review.prepare(10000,5)
		world.spells.levels[0]=1
		world.muted=muted
		world.impact.sound_events.clear()
		world.spells.cast(0,world.enemies[0])
		var flame: Node2D=world.spells.visuals[0]
		var length: float=Cue.STREAM.get_length()
		review.check(absf(flame.duration-length)<1.0/48000,"L1 fire ends at the exact imported audio duration")
		review.check(flame.animation_frame_count()==8,"L1 fire keeps eight authored poses")
		if not muted:
			var events: Array=world.spells.sound_events
			review.check(events.size()==1 and events[0].kind=="fire-sequence" and is_equal_approx(events[0].pitch,1.0),"One complete fire cue starts with the effect, without pitch timing drift")
			if not events.is_empty():
				review.check(absf(events[0].duration-flame.duration)<1.0/48000,"Actual audio playback duration equals the visual lifetime")
		world.spells.advance(0.5)
		var alpha: float=flame.opacity()
		world.spells.advance(0.4)
		review.check(flame.opacity()>0 and flame.opacity()<alpha,"Fire fades through the audio tail rather than popping away")
		world.spells.advance(length-0.90-0.001)
		review.check(not world.spells.visuals.is_empty(),"Fire is retained until its shared audio endpoint")
		world.spells.advance(0.002)
		review.check(world.spells.visuals.is_empty() and flame.opacity()==0,"Fire is gone immediately after the audio endpoint, including when muted")
		for event in world.spells.sound_events:
			review.check(event.kind not in ["fire","fire-ignite"],"Old layered fire cues cannot extend the short L1 sound tail")
		for event in world.impact.sound_events:
			review.check(event.kind!="fire","AOE victims do not add a second generic fire recording")
	world.muted=false
	review.prepare(10000,1)
	world.impact.sound_gates.clear()
	world.impact.sound_events.clear()
	world.deal_damage(world.player,world.enemies[0],1,"fire")
	review.check(not world.impact.sound_events.is_empty(),"Ordinary fire bolt contact still retains its own feedback")
	world.spells.cast(0,world.enemies[0])
	world.spells.reset()
	var playing:=false
	for voice in world.spells.voices: playing=playing or voice.playing
	review.check(not playing and world.spells.visuals.is_empty(),"Reset interrupts the complete fire cue and animation together")

func preview(world: Node, review: Node) -> void:
	world.set_process_input(false)
	world.set_process_unhandled_input(false)
	world.set_process_unhandled_key_input(false)
	var trace: Array=[]
	for take in range(3):
		review.prepare(10000,3)
		world.spells.levels.fill(1)
		world.paused=false; world.muted=false; world.dialogue.clear()
		world.toast("一级火爆术 · 8 帧 · 音画同在 1.13 秒结束","L1 Flame Burst · 8 poses · sound and visual end at 1.13 s",999)
		await review.render_frames(15)
		world.spells.cast(0,world.enemies[take%3])
		var start: float=world.spells.clock
		var last_visible:=0.0
		for frame in range(60):
			await review.render_frames(1)
			if not world.spells.visuals.is_empty(): last_visible=world.spells.clock-start
			if take==0 and frame in [1,3,8,15,24,33,34]:
				await RenderingServer.frame_post_draw
				review.get_viewport().get_texture().get_image().save_png("res://game/whispering_forest/preview/fire-v5-%02d.png" % frame)
		if world.spells.sound_events.is_empty() or not world.spells.visuals.is_empty():
			push_error("Fire preview is missing its cue or exceeded its lifetime")
			review.get_tree().quit(1); return
		trace.append({"take":take+1,"start":start,"last_visible":last_visible,"sound_length":Cue.duration(),"events":world.spells.sound_events.duplicate(true)})
	var file:=FileAccess.open("res://game/whispering_forest/preview/fire-v5-events.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(trace,"\t")+"\n")
	file.close()
	print("WF_FIRE_PREVIEW_OK: three L1 casts; eight poses; stream length drives visual endpoint")
	review.get_tree().quit()
