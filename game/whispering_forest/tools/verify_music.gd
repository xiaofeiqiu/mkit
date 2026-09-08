extends SceneTree
## Exercise the real scene's audio lifecycle without loading or writing player saves.

var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("WF_MUSIC_CHECK_FAILED: "+message)

func run() -> void:
	var bootstrap = load("res://game/whispering_forest/bootstrap.tscn").instantiate()
	bootstrap.initial_scene_path = ""
	root.add_child(bootstrap)
	var world = load("res://game/whispering_forest/village.tscn").instantiate()
	world.review_mode = true
	world.intro_seen = true
	root.add_child(world)
	world.simulation = true
	world.set_process(false)
	var music = world.ambient
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 24.0
	AudioServer.add_bus_effect(0,capture)
	await create_timer(1.9).timeout
	check(music.current_cue=="city" and music.players[0].playing,"city starts on arrival")
	check(not music.players[1].playing,"battle is silent in the city")
	check(music.players[0].stream.loop and music.players[1].stream.loop,"both streams use native looping")
	check(music.players[0].stream.get_length()>100,"full city score is loaded")
	check(music.players[1].stream.get_length()>100,"full battle score is loaded")
	var city_position: float = music.players[0].get_playback_position()
	world.stage = 1
	world.enter_dungeon()
	await create_timer(.6).timeout
	check(music.current_cue=="battle","quest teleport selects battle music")
	check(music.players[0].playing and music.players[1].playing,"both streams run during the crossfade")
	check(absf(music.weights.length_squared()-1)<.02,"crossfade preserves equal-power envelope")
	await create_timer(1.2).timeout
	check(not music.players[0].playing and music.players[1].playing,"city releases after the fade")
	check(music.resume_positions.x>city_position,"city retains its position for a return visit")
	var before_mute: float = music.players[1].get_playback_position()
	world.toggle_sound()
	check(AudioServer.is_bus_mute(0),"existing mute button covers music")
	await create_timer(.25).timeout
	world.toggle_sound()
	check(not AudioServer.is_bus_mute(0),"unmute restores the game mix")
	check(music.players[1].get_playback_position()>before_mute,"mute does not restart the score")
	world.impact.duck_left = .22
	world.impact.advance(.05)
	check(music.volume_db<-5.0,"critical/meteor music ducking remains compatible")
	world.impact.advance(.4)
	check(is_equal_approx(music.volume_db,-5.0),"music returns to its normal level")
	# Verify the actual Vorbis playback wraps while remaining active.
	music.players[1].seek(music.players[1].stream.get_length()-.18)
	await create_timer(.48).timeout
	check(music.players[1].playing and music.players[1].get_playback_position()<1.0,"battle loop wraps without a finished/restart callback")
	world.return_to_city()
	await create_timer(1.9).timeout
	check(music.current_cue=="city" and music.players[0].playing,"return to city restores city music")
	check(music.players[0].get_playback_position()>city_position,"city resumes instead of replaying its opening")
	# Reverse an in-flight transition, then re-enter: no duplicate voices or stuck cue.
	world.enter_dungeon()
	await create_timer(.2).timeout
	world.return_to_city()
	await create_timer(.2).timeout
	world.enter_dungeon()
	await create_timer(1.9).timeout
	check(music.current_cue=="battle" and music.players[1].playing and not music.players[0].playing,"rapid map changes settle on the correct single score")
	check(music.get_child_count()==2,"switching does not leak music players")
	var frames := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample in frames:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	check(frames.size()>AudioServer.get_mix_rate()*5,"audio was actually mixed for more than five seconds")
	check(peak>.01 and peak<1.0,"decoded game mix is audible and not clipped")
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	music.stop()
	check(not music.players[0].playing and not music.players[1].playing,"capture/exit stop releases both playbacks")
	# Dummy audio mixes on its own clock; two unthrottled scene frames are not
	# necessarily an audio block. Let its pending stop command drain before exit.
	await create_timer(.15).timeout
	music.release_streams()
	world.queue_free()
	bootstrap.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("WF_MUSIC_OK: city, quest teleport, equal-power crossfade, mute/unmute, impact ducking, native looping, return/resume, rapid re-entry, non-silent decoded mix, cleanup")
	quit(0 if failures.is_empty() else 1)
