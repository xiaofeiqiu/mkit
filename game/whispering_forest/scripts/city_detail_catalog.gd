extends RefCounted

const ROOT := "res://game/whispering_forest/assets/city-detail/"
const FRAMES = preload("res://game/whispering_forest/assets/city-detail/frames.gd").FRAMES
const BUILDINGS := {
	"apothecary":"apothecary_se", "west_homes":"baker_sw",
	"southeast_homes":"baker_sw", "east_homes":"residence_ne",
	"northeast_homes":"residence_ne", "northwest_homes":"workshop_nw",
	"east_homes_2":"workshop_nw",
}

static func key(asset: String, building_id: String, at: Vector2) -> String:
	if BUILDINGS.has(building_id): return BUILDINGS[building_id]
	var variation := posmod(roundi(at.x*0.13+at.y*0.17),7)
	if asset=="cypress": return "silver_tree" if variation==2 else "weathered_fir"
	if asset=="linden": return "silver_tree" if variation in [1,4,6] else "old_linden"
	return ""

static func basis(entry: Dictionary) -> Transform2D:
	if not entry.has("slopes"): return Transform2D.IDENTITY
	var slopes: Array = entry.slopes
	var vertical := 1.0/(float(slopes[0])-float(slopes[1]))
	# Both ground axes become +/-0.5; vertical edges remain vertical.
	return Transform2D(Vector2(1,0.5-vertical*float(slopes[0])),Vector2(0,vertical),Vector2.ZERO)

static func bounds(entry: Dictionary) -> Rect2:
	var transform := basis(entry)
	var points: Array = entry.base
	var rect := Rect2(WFIso.unproject(transform*Vector2(points[0][0],points[0][1])),Vector2.ZERO)
	for p in points: rect = rect.expand(WFIso.unproject(transform*Vector2(p[0],p[1])))
	return rect
