extends RefCounted

const Base = preload("res://game/whispering_forest/scripts/character_frames.gd")
const Motion = preload("res://game/whispering_forest/art/characters/motion_spec.gd")
static var cache: Dictionary = {}
static var metadata: Dictionary = {}

static func staff_tip(action: String, direction: int, frame: int) -> Vector2:
	if metadata.is_empty(): metadata=JSON.parse_string(FileAccess.get_file_as_string(Motion.OUTPUT+"manifest.json"))
	var samples: Array=metadata.actors.mage.clips[action].staff_tips[direction]
	var point: Array=samples[clampi(frame,0,samples.size()-1)]
	return Vector2(point[0],point[1])/Motion.STAGE.SUPERSAMPLE

static func outline() -> ShaderMaterial:
	return Base.outline()

static func cell_for(kind: String, action: String) -> int:
	return int(Motion.CLIPS[action].cell) if kind=="mage" else (384 if action=="death" else 256)

static func pivot_for(action: String, kind: String = "mage") -> Vector2:
	return Motion.origin(cell_for(kind,action))

static func for_kind(kind: String) -> Dictionary:
	if cache.has(kind): return cache[kind]
	var clips: Dictionary = {}
	var specs: Dictionary = Motion.clips_for(kind)
	for action in specs:
		var cell := cell_for(kind,action)
		var path: String = Motion.OUTPUT+kind+"-"+action+".png"
		var atlas: Texture2D = load(path)
		var directions: Array = []
		for direction in range(8):
			var frames: Array[Texture2D] = []
			for frame in range(int(specs[action].frames)):
				var texture := AtlasTexture.new()
				texture.atlas = atlas
				texture.region = Rect2(frame*cell,direction*cell,cell,cell)
				texture.filter_clip = true
				frames.append(texture)
			directions.append(frames)
		clips[action] = directions
	cache[kind] = clips
	return clips
