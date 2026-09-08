extends RefCounted

# Runtime consumes measured export metadata. No guessed image slopes or
# per-building fit-to-canvas scale remain in the active city renderer.
const ROOT := "res://game/whispering_forest/assets/city-reference-remake/"
const FRAMES = preload("res://game/whispering_forest/assets/city-reference-remake/frames.gd").FRAMES

static func footprint(asset: String) -> Vector2:
	var f: Array = FRAMES[asset].footprint
	return Vector2(f[0],f[1])

static func door_offset(asset: String) -> Vector2:
	var d: Array = FRAMES[asset].door
	return Vector2(d[0],d[1])
