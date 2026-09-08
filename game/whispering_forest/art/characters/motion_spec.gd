extends RefCounted

# Authored units are converted to the same metres used by the city models.
const STAGE = preload("res://game/whispering_forest/art/city/render_stage.gd")
const AUTHORED_HEIGHT := 2.60
const MODEL_TO_METRES: float = STAGE.SETTINGS.human_metres/AUTHORED_HEIGHT
const OUTPUT := "res://game/whispering_forest/assets/characters/world-motion/"
const TARGET := Vector3(0,0.9,0)
const WALK_STRIDE := 1.4
const RUN_STRIDE := 70.0/(MODEL_TO_METRES*STAGE.LOGICAL_UNITS_PER_METRE)
const CLIPS := {
	"idle":{"frames":32,"seconds":3.2,"loop":true,"cell":256},
	"look":{"frames":24,"seconds":2.0,"loop":false,"cell":256},
	"walk":{"frames":16,"seconds":0.64,"loop":true,"cell":256},
	"run":{"frames":16,"seconds":0.52,"loop":true,"cell":256},
	"ready":{"frames":24,"seconds":2.4,"loop":true,"cell":256},
	"attack":{"frames":8,"seconds":0.42,"loop":false,"cell":320},
	"cast_walk":{"frames":8,"seconds":0.42,"loop":false,"cell":320},
	"seal":{"frames":8,"seconds":1.3,"loop":false,"cell":256},
	"hurt":{"frames":8,"seconds":0.30,"loop":false,"cell":256},
	"death":{"frames":8,"seconds":0.72,"loop":false,"cell":384},
	"start":{"frames":8,"seconds":0.12,"loop":false,"cell":256},
	"stop":{"frames":8,"seconds":0.18,"loop":false,"cell":256},
	"stop_1":{"frames":8,"seconds":0.18,"loop":false,"cell":256},
	"stop_2":{"frames":8,"seconds":0.18,"loop":false,"cell":256},
	"stop_3":{"frames":8,"seconds":0.18,"loop":false,"cell":256},
	"dodge":{"frames":8,"seconds":0.20,"loop":false,"cell":256},
}

static func pivot(action: String) -> Vector2:
	var cell: int = CLIPS[action].cell
	return Vector2(cell*0.5,cell*0.5+TARGET.y*STAGE.PIXELS_PER_METRE*cos(PI/6))

static func stride_units(running: bool) -> float:
	return (RUN_STRIDE if running else WALK_STRIDE)*MODEL_TO_METRES*STAGE.LOGICAL_UNITS_PER_METRE

static func clips_for(kind: String) -> Dictionary:
	if kind=="mage": return CLIPS
	var result := {}
	for action in ["idle","walk","attack","seal","hurt","death"]:
		result[action]=CLIPS[action].duplicate()
		result[action].frames=8
		result[action].cell=384 if action=="death" else 256
	return result

static func model_scale(kind: String) -> float:
	return 0.52 if kind=="goblin" else MODEL_TO_METRES

static func origin(cell: int) -> Vector2:
	return Vector2(cell*0.5,cell*0.5+TARGET.y*STAGE.PIXELS_PER_METRE*cos(PI/6))
