extends GutTest


var audio: AudioManager
var _master_bus_index: int = -1
var _master_original_db: float = 0.0


func before_each() -> void:
	_master_bus_index = AudioServer.get_bus_index("Master")
	if _master_bus_index >= 0:
		_master_original_db = AudioServer.get_bus_volume_db(_master_bus_index)
	audio = AudioManager.new()
	audio.sfx_bus = "Master"
	audio.music_bus = "Master"
	add_child_autofree(audio)
	audio._ready()


func after_each() -> void:
	if _master_bus_index >= 0:
		AudioServer.set_bus_volume_db(_master_bus_index, _master_original_db)
	ServiceRegistry.clear()


func test_tc_audio_01_play_sfx_spawns_one_shot_player() -> void:
	var stream := _make_stream()
	audio.sfx_map["hit"] = stream
	var child_count := audio.get_child_count()

	audio.play_sfx("hit", -3.0)

	assert_eq(audio.get_child_count(), child_count + 1)
	var player := audio.get_child(audio.get_child_count() - 1) as AudioStreamPlayer
	assert_not_null(player)
	assert_eq(player.stream, stream)
	assert_eq(player.bus, audio.sfx_bus)
	assert_almost_eq(player.volume_db, -3.0, 0.001)

	audio.play_sfx("missing")
	assert_eq(audio.get_child_count(), child_count + 1)


func test_tc_audio_02_play_music_without_fade_sets_stream_and_current_id() -> void:
	var stream := _make_stream()
	audio.music_map["theme"] = stream

	audio.play_music("theme")

	assert_eq(audio.music_player.stream, stream)
	assert_eq(audio.current_music_id, "theme")
	assert_eq(audio.music_player.bus, audio.music_bus)
	assert_almost_eq(audio.music_player.volume_db, 0.0, 0.001)
	assert_null(audio._music_tween)


func test_tc_audio_03_play_music_with_fade_transitions_between_streams() -> void:
	var first := _make_stream()
	var second := _make_stream()
	audio.music_map["first"] = first
	audio.music_map["second"] = second
	audio.play_music("first")

	audio.play_music("second", 0.08)

	assert_not_null(audio._music_tween)
	assert_eq(audio.music_player.stream, first)
	await wait_seconds(0.14)
	assert_eq(audio.music_player.stream, second)
	assert_eq(audio.current_music_id, "second")
	assert_almost_eq(audio.music_player.volume_db, 0.0, 0.01)
	assert_null(audio._music_tween)


func test_tc_audio_04_stop_music_cancels_current_music() -> void:
	audio.music_map["theme"] = _make_stream()
	audio.play_music("theme", 0.1)

	audio.stop_music()

	assert_eq(audio.current_music_id, "")
	assert_false(audio.music_player.playing)
	assert_almost_eq(audio.music_player.volume_db, 0.0, 0.001)
	assert_null(audio._music_tween)


func test_tc_audio_05_repeated_current_music_cancels_pending_transition() -> void:
	var first := _make_stream()
	var second := _make_stream()
	audio.music_map["first"] = first
	audio.music_map["second"] = second
	audio.play_music("first")
	audio.play_music("second", 0.2)
	assert_not_null(audio._music_tween)

	audio.play_music("first")

	assert_null(audio._music_tween)
	assert_eq(audio.music_player.stream, first)
	assert_eq(audio.current_music_id, "first")
	assert_almost_eq(audio.music_player.volume_db, 0.0, 0.001)


func test_tc_audio_06_bus_volume_set_get_and_reject_paths() -> void:
	assert_true(audio.set_bus_volume("Master", -7.5))
	assert_almost_eq(AudioServer.get_bus_volume_db(_master_bus_index), -7.5, 0.001)
	assert_almost_eq(audio.get_bus_volume("Master"), -7.5, 0.001)

	assert_false(audio.set_bus_volume("", -1.0))
	assert_false(audio.set_bus_volume("mkit_missing_bus", -1.0))
	assert_almost_eq(audio.get_bus_volume("mkit_missing_bus"), 0.0, 0.001)


func test_tc_audio_07_save_load_roundtrips_bus_volumes() -> void:
	assert_eq(audio.save_id, "audio")
	assert_true(audio.set_bus_volume("Master", -5.0))
	var data := audio.to_save_data()
	AudioServer.set_bus_volume_db(_master_bus_index, _master_original_db)
	assert_almost_eq(AudioServer.get_bus_volume_db(_master_bus_index), _master_original_db, 0.001)

	var restored := AudioManager.new()
	add_child_autofree(restored)
	restored._ready()
	restored.from_save_data(data)

	assert_almost_eq(restored.get_bus_volume("Master"), -5.0, 0.001)
	assert_almost_eq(AudioServer.get_bus_volume_db(_master_bus_index), -5.0, 0.001)
	var restored_data := restored.to_save_data()
	var bus_data: Dictionary = restored_data.get("bus_volumes", {})
	assert_almost_eq(float(bus_data.get("Master", 0.0)), -5.0, 0.001)


func _make_stream() -> AudioStream:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	return stream
