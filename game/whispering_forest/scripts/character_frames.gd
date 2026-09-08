extends RefCounted

const CELL := 256
const PIVOT := Vector2(128,218)
const DIRECTIONS := ["S","SW","W","NW","N","NE","E","SE"]
const ACTIONS := ["idle","walk","attack","seal","hurt","death"]
static var cache: Dictionary = {}
static var outline_material: ShaderMaterial

static func outline() -> ShaderMaterial:
	if outline_material==null:
		outline_material = ShaderMaterial.new()
		outline_material.shader = load("res://game/whispering_forest/assets/characters/outline.gdshader")
	return outline_material

static func for_kind(kind: String) -> Dictionary:
	if cache.has(kind):
		return cache[kind]
	var result: Dictionary = {}
	for action in ACTIONS:
		var atlas: Texture2D = load("res://game/whispering_forest/assets/characters/%s-%s.png" % [kind,action])
		var directions: Array = []
		for direction in range(8):
			var frames: Array[Texture2D] = []
			for frame in range(8):
				var texture := AtlasTexture.new()
				texture.atlas = atlas
				texture.region = Rect2(frame*CELL,direction*CELL,CELL,CELL)
				texture.filter_clip = true
				frames.append(texture)
			directions.append(frames)
		result[action] = directions
	cache[kind] = result
	return result

static func facing_for_screen(direction: Vector2) -> int:
	return posmod(roundi(-atan2(direction.x,direction.y)/(PI/4)),8)
