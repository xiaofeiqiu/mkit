@tool
extends Node2D

# Low, traversable curbs assembled from fixed-density renders of 3D modules.
# Curves and paving consume the same rounded-rectangle path.
const City = preload("res://game/whispering_forest/scripts/city.gd")
const Art = preload("res://game/whispering_forest/scripts/city_art.gd")
const RADIUS := 24.0
var textures := {}
var placements: Array[Dictionary] = []
var world: Node

static func outline(rect: Rect2,radius: float=RADIUS) -> PackedVector2Array:
	var points := PackedVector2Array()
	var centers := [rect.end-Vector2(radius,radius),Vector2(rect.position.x+radius,rect.end.y-radius),rect.position+Vector2(radius,radius),Vector2(rect.end.x-radius,rect.position.y+radius)]
	for corner in range(4):
		for i in range(9):
			var a := corner*PI/2+i*PI/16
			points.append(centers[corner]+Vector2(cos(a),sin(a))*radius)
	return points

func _ready() -> void:
	for i in range(City.STREETS.size()):
		var r: Rect2 = City.STREETS[i]
		for y in [r.position.y,r.end.y]: line(Vector2(r.position.x,y),Vector2(r.end.x,y),i)
		for x in [r.position.x,r.end.x]: line(Vector2(x,r.position.y),Vector2(x,r.end.y),i)
	for i in range(City.PLAZAS.size()): rounded(City.PLAZAS[i],100+i)
	for i in range(City.GARDENS.size()): rounded(City.GARDENS[i],200+i)
	for ramp in City.RAMPS: placements.append(ramp)
	for item in placements:
		if not textures.has(item.asset): textures[item.asset]=load(Art.ROOT+item.asset+".png")
	queue_redraw()

func covered(p: Vector2,source: int) -> bool:
	for walk in City.GARDEN_WALKS:
		if walk.grow(1).has_point(p): return true
	for i in range(City.STREETS.size()):
		if source!=i and City.STREETS[i].grow(1).has_point(p): return true
	for i in range(City.PLAZAS.size()):
		if source!=100+i and Geometry2D.is_point_in_polygon(p,outline(City.PLAZAS[i])): return true
	for b in City.BUILDINGS:
		if City.footprint(b).grow(10).has_point(p) or City.door_path(b).grow(2).has_point(p): return true
	return absf(p.x)>875 or absf(p.y)>715

func line(a: Vector2,b: Vector2,source: int) -> void:
	var remaining := roundi(a.distance_to(b))
	var direction := (b-a).normalized()
	var cursor := a
	var suffix := "_r90" if direction.y!=0 else ""
	while remaining>0:
		var span := 1
		for candidate in [32,16,8,4,2,1]:
			if candidate<=remaining:
				span=candidate
				break
		var mid := cursor+direction*span*0.5
		# Split only at a coverage boundary; a long stone must never bridge a
		# road junction simply because its midpoint was outside that road.
		while span>1:
			var state := covered(cursor+direction*0.5,source)
			var uniform := true
			for unit in range(1,span):
				if covered(cursor+direction*(unit+0.5),source)!=state:
					uniform=false
					break
			if uniform: break
			span=int(span/2)
		mid=cursor+direction*span*0.5
		if not covered(mid,source): placements.append({"asset":"curb_%d%s" % [span,suffix],"at":mid})
		cursor+=direction*span
		remaining-=span

func rounded(rect: Rect2,source: int) -> void:
	var r := RADIUS
	for y in [rect.position.y,rect.end.y]: line(Vector2(rect.position.x+r,y),Vector2(rect.end.x-r,y),source)
	for x in [rect.position.x,rect.end.x]: line(Vector2(x,rect.position.y+r),Vector2(x,rect.end.y-r),source)
	var centers := [rect.end-Vector2(r,r),Vector2(rect.end.x-r,rect.position.y+r),rect.position+Vector2(r,r),Vector2(rect.position.x+r,rect.end.y-r)]
	var middle := [Vector2(1,1),Vector2(1,-1),Vector2(-1,-1),Vector2(-1,1)]
	for i in range(4):
		if not covered(centers[i]+middle[i].normalized()*r,source):
			placements.append({"asset":"curb_arc"+("_r%d" % (i*90) if i>0 else ""),"at":centers[i]})

func _draw() -> void:
	for item in placements:
		var data: Dictionary = Art.FRAMES[item.asset]
		var scale_value: float = data.scale
		var p := WFIso.project(item.at)-Vector2(data.pivot[0],data.pivot[1])*scale_value
		var size := Vector2(data.region[2],data.region[3])*scale_value
		# A single small contact shadow complements the source self-shadow.
		draw_texture_rect(textures[item.asset],Rect2(p+Vector2(2,1.2),size),false,Color(0.26,0.34,0.33,0.19))
		draw_texture_rect(textures[item.asset],Rect2(p,size),false)
