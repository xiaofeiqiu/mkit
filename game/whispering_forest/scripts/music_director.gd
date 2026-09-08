extends Node
## Two original looping scores, with equal-power city/instance transitions.
## volume_db is also the existing impact system's music-ducking control.

const CUES := [
	{"id":"city", "file":"res://game/whispering_forest/assets/music/bellwake_city.ogg"},
	{"id":"battle", "file":"res://game/whispering_forest/assets/music/rift_battle.ogg"},
]
const CROSSFADE_SECONDS := 1.6

var world: Node
var volume_db := -5.0
var players: Array[AudioStreamPlayer] = []
var current_cue := ""
var running := false
var weights := Vector2.ZERO
var resume_positions := Vector2.ZERO
var _start_weights := Vector2.ZERO
var _target_index := 0
var _transition_age := 0.0

func _ready() -> void:
	for cue in CUES:
		var voice := AudioStreamPlayer.new()
		voice.name = "CityMusic" if cue.id=="city" else "BattleMusic"
		var stream := load(cue.file) as AudioStreamOggVorbis
		if stream==null:
			push_error("Could not load music: "+cue.file)
			continue
		# Each resource is private; this does not change the import or another player.
		stream = stream.duplicate() as AudioStreamOggVorbis
		stream.loop = true
		stream.loop_offset = 0.0
		voice.stream = stream
		voice.volume_db = -80.0
		add_child(voice)
		players.append(voice)

func start(area: String = "city") -> void:
	if players.size()!=2:
		return
	running = true
	select_area(area)

func select_area(area: String) -> void:
	if not running:
		return
	var next_index := 0 if area=="city" else 1
	var next_cue: String = CUES[next_index].id
	if current_cue==next_cue:
		return
	current_cue = next_cue
	_target_index = next_index
	_start_weights = weights
	_transition_age = 0.0
	if not players[next_index].playing:
		# Resume a visit to the city. A fresh instance starts its combat opening.
		players[next_index].play(resume_positions.x if next_index==0 else 0.0)

func _process(delta: float) -> void:
	if not running:
		return
	if is_instance_valid(world):
		select_area(world.area)
	_transition_age = minf(CROSSFADE_SECONDS, _transition_age+delta)
	var progress := _transition_age/CROSSFADE_SECONDS
	for i in range(2):
		var target := 1.0 if i==_target_index else 0.0
		weights[i] = sqrt(lerpf(_start_weights[i]*_start_weights[i],target,progress))
		players[i].volume_db = volume_db+linear_to_db(maxf(weights[i],0.0001))
		if progress>=1.0 and i!=_target_index and players[i].playing:
			resume_positions[i] = players[i].get_playback_position()
			players[i].stop()

func stop() -> void:
	running = false
	current_cue = ""
	weights = Vector2.ZERO
	for voice in players:
		voice.stop()

func release_streams() -> void:
	stop()
	for voice in players:
		voice.stream = null
