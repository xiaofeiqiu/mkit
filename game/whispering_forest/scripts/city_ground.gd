@tool
extends Node2D

const City = preload("res://game/whispering_forest/scripts/city.gd")
const Curbs = preload("res://game/whispering_forest/scripts/city_curbs.gd")
var grass: Texture2D
var stone: Texture2D
var street: Texture2D
var world: Node

func _ready() -> void:
	grass = load("res://game/whispering_forest/assets/grass-daylight.png")
	stone = load("res://game/whispering_forest/art/city/reference-remake/materials/flagstone.png")
	street = load("res://game/whispering_forest/art/city/reference-remake/materials/cobblestone.png")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()

func polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([WFIso.project(rect.position),WFIso.project(Vector2(rect.end.x,rect.position.y)),WFIso.project(rect.end),WFIso.project(Vector2(rect.position.x,rect.end.y))])

func slab(rect: Rect2,color: Color,texture: Texture2D=null,unit: float=260.0) -> void:
	var poly := polygon(rect)
	if texture!=null:
		var uv := PackedVector2Array([rect.position/unit,Vector2(rect.end.x,rect.position.y)/unit,rect.end/unit,Vector2(rect.position.x,rect.end.y)/unit])
		draw_polygon(poly,PackedColorArray([color]),uv,texture)
	else: draw_colored_polygon(poly,color)

func paving(rect: Rect2,light: bool=false) -> void:
	slab(rect,Color("d7d4c6") if light else Color("99a3a4"))
	slab(rect,Color(1,1,1,0.78),stone if light else street,128 if light else 112)

func rounded_surface(rect: Rect2,color: Color,texture: Texture2D=null,unit: float=300.0,radius: float=Curbs.RADIUS) -> void:
	var logical := Curbs.outline(rect,radius)
	var projected := PackedVector2Array()
	var uv := PackedVector2Array()
	for p in logical:
		projected.append(WFIso.project(p))
		uv.append(p/unit)
	if texture!=null: draw_polygon(projected,PackedColorArray([color]),uv,texture)
	else: draw_colored_polygon(projected,color)

func ring_rect(rect: Rect2,width: float,color: Color) -> void:
	var p := polygon(rect)
	p.append(p[0])
	draw_polyline(p,color,width,true)

func _draw() -> void:
	# A single water plane surrounds the built island. The two bridges cross
	# this visible moat; gatehouses stand on its stone embankment.
	slab(Rect2(-4000,-4000,8000,8000),Color("438baa"))
	for y in range(-1200,1200,53):
		for x in range(-1300,1300,103):
			if abs(x)<960 and abs(y)<800: continue
			var p := WFIso.project(Vector2(x+(y%31),y))
			draw_line(p,p+Vector2(17,0),Color(0.68,0.85,0.87,0.15),1,true)
	# Layered embankment, wall foundations and a broad inner patrol walk.
	slab(Rect2(-930,-770,1860,1540),Color("778b82"))
	slab(Rect2(-922,-762,1844,1524),Color("d5d2bb"))
	slab(Rect2(-898,-738,1796,1476),Color("72a97b"))
	slab(Rect2(-898,-738,1796,1476),Color(0.88,0.95,1.02,0.42),grass,600)
	for r in [Rect2(-880,-720,1760,36),Rect2(-880,684,1760,36),Rect2(-880,-684,36,1368),Rect2(844,-684,36,1368)]: paving(r,true)
	# Bridge slabs are wider than the actual path, with readable edges.
	for side in [-1,1]:
		var x := 905.0 if side==1 else -1110.0
		slab(Rect2(x,-13,205,106),Color("787f77"))
		paving(Rect2(x,-6,205,92),true)
		for y in [-9,87]: slab(Rect2(x,y,205,4),Color("e5dfc8"))
		var landing := Rect2(1040 if side==1 else -1220,-80,180,240)
		slab(landing.grow(7),Color("989e83"))
		slab(landing,Color("79ad7b"))
		slab(landing,Color(0.9,1.0,1.0,0.4),grass,600)
		paving(Rect2(1040 if side==1 else -1200,-6,160,92),true)
	# Worn sandstone walks surround cooler small-block granite carriageways.
	for road in City.STREETS: paving(road,true)
	for road in City.STREETS: paving(road.grow(-9))
	for walk in City.GARDEN_WALKS: paving(walk,true)
	for plaza in City.PLAZAS:
		rounded_surface(plaza,Color("d7d4c6"))
		rounded_surface(plaza,Color(1,1,1,0.78),stone,128)
	# Each facade has a deliberate forecourt linked to its frontage lane.
	for b in City.BUILDINGS:
		var foot := City.footprint(b)
		paving(foot.grow(9),true)
		paving(City.door_path(b),true)
	# Formal parterres, dwelling gardens and the companion pond are separate
	# plots. No random forest scatter occupies the principal avenues.
	for garden in City.GARDENS:
		rounded_surface(garden,Color("649d75"))
		rounded_surface(garden.grow(-6),Color(0.83,0.96,1.0,0.40),grass,600,18)
		if not garden.has_point(City.POND):
			slab(Rect2(garden.get_center()-Vector2(garden.size.x/2,9),Vector2(garden.size.x,18)),Color("c9cbb1"))
			slab(Rect2(garden.get_center()-Vector2(9,garden.size.y/2),Vector2(18,garden.size.y)),Color("c9cbb1"))
	# Deliberately small reflecting pool within the southern garden.
	var water := WFIso.disc(City.POND,61)
	for i in range(water.size()): water[i] = WFIso.project(City.POND+(WFIso.unproject(water[i])-City.POND)*Vector2(1.2,0.9))
	draw_colored_polygon(water,Color("e0dbc1"))
	var inside := PackedVector2Array()
	for i in range(48): inside.append(WFIso.project(City.POND+Vector2.from_angle(i*TAU/48)*Vector2(65,48)))
	draw_colored_polygon(inside,Color("63b0c0"))
	for i in range(5):
		var p := WFIso.project(City.POND+Vector2(-35+i*14,sin(i*2)*23))
		draw_line(p,p+Vector2(12,0),Color("a7d5d1"),1,true)
	# Inlaid civic rosette; the arrival marker remains the gameplay START.
	# Small flush grates sit at the low edges of carriageways. Their bars
	# follow the ground axes, and have no volume above the walking surface.
	for at in [Vector2(-610,109),Vector2(610,109),Vector2(-720,-204),Vector2(612,326)]:
		slab(Rect2(at-Vector2(10,6),Vector2(20,12)),Color("636f6d"))
		for i in range(6):
			var p: Vector2 = at+Vector2(-8+i*3.2,-4)
			draw_line(WFIso.project(p),WFIso.project(p+Vector2(0,8)),Color("a4aaa0"),1.0,true)
	var center := Vector2(-60,60)
	for item in [[87,Color("839c9b")],[82,Color("e1ddc7")],[75,Color("adbec0")],[64,Color("769fa8")]]:
		draw_colored_polygon(WFIso.disc(center,item[0]),item[1])
	for radius in [61,49,27]: draw_polyline(WFIso.ring(center,radius),Color("dcead8"),1.7,true)
	for i in range(8):
		var a := Vector2.from_angle(i*TAU/8)
		draw_line(WFIso.project(center+a*29),WFIso.project(center+a*59),Color("d9e5cb"),2,true)
		var p := WFIso.project(center+a*70)
		draw_circle(p,2,Color("d6c58d"))
	# Junction medallions establish a consistent street language.
	for at in [Vector2(-535,40),Vector2(555,40),Vector2(0,447)]:
		draw_colored_polygon(WFIso.disc(at,27),Color("8eaaa4"))
		draw_polyline(WFIso.ring(at,24),Color("d8d9be"),2,true)
