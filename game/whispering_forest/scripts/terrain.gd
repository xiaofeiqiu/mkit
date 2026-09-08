extends Node2D

# Calibrated against the user's sunlit grass reference; source pixels stay intact.
const GRASS_LIGHT := Color(0.89,0.84,1.03)

var grass: Texture2D
var cobbles: Texture2D
var tile_records: Array[Dictionary] = []
var stones: Array[Dictionary] = []
var tufts: Array[Dictionary] = []
var world: Node
var pond := Vector2(-255, 235)

func _ready() -> void:
	grass = load("res://game/whispering_forest/assets/grass-daylight.png")
	cobbles = load("res://game/whispering_forest/assets/cobbles.png")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 60103
	var extent_x := 25 if world.area=="city" else 19
	var extent_y := 21 if world.area=="city" else 19
	for y in range(-extent_y, extent_y):
		for x in range(-extent_x, extent_x):
			var at := Vector2(x, y) * 32.0
			tile_records.append({"at": at, "shade": rng.randf_range(0.91, 1.04)})
	# Irregular cobbles follow two intersecting village lanes, in ground space.
	for y in range(-42, 43):
		for x in range(-42, 43):
			var at := Vector2(x * 14 + (y % 2) * 7, y * 14)
			var path := absf(at.y - 24 - sin(at.x * 0.008) * 22) < 32 or (absf(at.x + 90) < 27 and at.y < 50 and at.y > -330)
			if path and absf(at.x) < 525:
				stones.append({"at": at + Vector2(rng.randf_range(-1.5,1.5),rng.randf_range(-1.5,1.5)), "size": Vector2(rng.randf_range(10,13),rng.randf_range(9,12)), "shade": rng.randf_range(0.83,1.1)})
	for i in range(1600):
		var at := Vector2(rng.randf_range(-extent_x*32, extent_x*32), rng.randf_range(-extent_y*32,extent_y*32))
		if absf(at.y - 24 - sin(at.x * 0.008) * 22) < 36 or at.distance_to(pond) < 100:
			continue
		if world.area=="city" and world.City.is_road(at):
			continue
		tufts.append({"at": at, "color": Color("6d9b75") if i % 5 else Color("97b69a"), "size": rng.randf_range(1.5,3.5)})
	queue_redraw()

func _draw() -> void:
	for tile in tile_records:
		var p: Vector2 = tile.at
		var points := PackedVector2Array([WFIso.project(p), WFIso.project(p + Vector2(32,0)), WFIso.project(p + Vector2(32,32)), WFIso.project(p + Vector2(0,32))])
		var uv := p / 420.0
		var unit := 32.0 / 420.0
		draw_polygon(points, PackedColorArray([GRASS_LIGHT]), PackedVector2Array([uv,uv+Vector2(unit,0),uv+Vector2(unit,unit),uv+Vector2(0,unit)]), grass)
	if world.area=="city":
		# Streets and squares are independent textured ground geometry, not a scene image.
		for street in [Rect2(-735,20,1470,80),Rect2(-100,-580,80,1170),Rect2(-512,-330,64,780),Rect2(448,-330,64,780),Rect2(-512,-362,1024,64),Rect2(-512,418,1024,64)]:
			stone_rect(street)
		for station in world.City.STATIONS:
			stone_rect(Rect2(station.at-Vector2(70,60),Vector2(155,150)))
		# Low limestone edging marks the city footprint.
		for edge in [Rect2(-785,-657,1570,14),Rect2(-785,643,1570,14),Rect2(-785,-657,14,1314),Rect2(771,-657,14,1314)]:
			stone_rect(edge)
	else:
		for x in range(-540,540,12):
			var left := float(x)
			var right := float(x+12)
			var ly := 24+sin(left*0.008)*22
			var ry := 24+sin(right*0.008)*22
			stone_quad([Vector2(left,ly-30),Vector2(right,ry-30),Vector2(right,ry+30),Vector2(left,ly+30)])
		stone_quad([Vector2(-117,-340),Vector2(-63,-340),Vector2(-63,36),Vector2(-117,36)])
	for tuft in tufts:
		if world.area=="city" and absf(tuft.at.x+40)<185 and absf(tuft.at.y-40)<165:
			continue
		var p := WFIso.project(tuft.at)
		draw_line(p, p + Vector2(1,-tuft.size), tuft.color, 1.0, true)
		if int(p.x) % 7 == 0:
			draw_circle(p + Vector2(0,-3),1.3,Color("d4dfd9"))
	# The pond uses the same projection as collisions and combat circles.
	draw_colored_polygon(WFIso.disc(pond, 92), Color("5f7766"))
	draw_colored_polygon(WFIso.disc(pond, 85), Color("438eb6"))
	draw_colored_polygon(WFIso.disc(pond+Vector2(-5,-5), 72), Color("69aed2"))
	for i in range(8):
		var at := pond + Vector2(sin(i*2.7)*60,cos(i*1.9)*45)
		var p := WFIso.project(at)
		draw_line(p-Vector2(10,0),p+Vector2(10,0),Color(0.68,0.83,0.71,0.36),1,true)
	for i in range(5):
		var at := pond+Vector2(-35+i*17, 30+sin(i)*10)
		draw_colored_polygon(WFIso.disc(at, 6), Color("a5b776"))
		draw_circle(WFIso.project(at)+Vector2(0,-2),2,Color("ecd2ab"))
	if world.area=="city":
		# The civic square uses the same logical plane as every foot pivot.
		stone_quad([Vector2(-220,-120),Vector2(140,-120),Vector2(140,205),Vector2(-220,205)])
		var center: Vector2 = world.START
		draw_colored_polygon(WFIso.disc(center,61),Color("c8d9d6"))
		draw_polyline(WFIso.ring(center,61),Color("eff0dc"),5,true)
		draw_colored_polygon(WFIso.disc(center,51),Color("97bfc4"))
		draw_polyline(WFIso.ring(center,44),Color("e7f4df"),2,true)
		for i in range(8):
			var a := center+Vector2.from_angle(i*TAU/8)*39
			var b := center+Vector2.from_angle((i+3)*TAU/8)*39
			draw_line(WFIso.project(a),WFIso.project(b),Color("d4edf0"),1.5,true)

func stone_rect(rect: Rect2) -> void:
	stone_quad([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func stone_quad(corners: Array) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for p in corners:
		points.append(WFIso.project(p))
		uvs.append(p/240.0)
	draw_polygon(points,PackedColorArray([Color(1.18,1.18,1.14) if world.area=="city" else Color.WHITE]),uvs,cobbles)
