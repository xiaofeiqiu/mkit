@tool
extends "res://game/whispering_forest/scripts/city_ground.gd"

const CURB_HEIGHT := 4.5
const WALK_WIDTH := 17.0
var road_contours: Array[PackedVector2Array] = []

func _ready() -> void:
	super._ready()
	road_contours = outline_roads()
	queue_redraw()

static func area(poly: PackedVector2Array) -> float:
	var sum := 0.0
	for i in range(poly.size()): sum+=poly[i].cross(poly[(i+1)%poly.size()])
	return sum*0.5

static func bevel(poly: PackedVector2Array, distance: float) -> PackedVector2Array:
	var clean := PackedVector2Array()
	for i in range(poly.size()):
		var a := poly[(i-1+poly.size())%poly.size()]
		var b := poly[i]
		var c := poly[(i+1)%poly.size()]
		if absf((b-a).cross(c-b))>0.01: clean.append(b)
	var result := PackedVector2Array()
	for i in range(clean.size()):
		var p := clean[i]
		var before := clean[(i-1+clean.size())%clean.size()]-p
		var after := clean[(i+1)%clean.size()]-p
		var trim := minf(distance,minf(before.length(),after.length())*0.28)
		result.append(p+before.normalized()*trim)
		result.append(p+after.normalized()*trim)
	return result

static func outline_roads() -> Array[PackedVector2Array]:
	# Exact union on the rectangles' coordinate grid, retaining interior holes.
	# Only exposed edges receive curbs; intersections never get duplicate rails.
	var rects: Array[Rect2] = []
	var xs: Array[float] = []
	var ys: Array[float] = []
	for r in City.STREETS+City.PLAZAS:
		rects.append(r)
		for x in [r.position.x,r.end.x]:
			if not xs.has(x): xs.append(x)
		for y in [r.position.y,r.end.y]:
			if not ys.has(y): ys.append(y)
	xs.sort()
	ys.sort()
	var occupied: Dictionary = {}
	for y in range(ys.size()-1):
		for x in range(xs.size()-1):
			var center := Vector2((xs[x]+xs[x+1])*0.5,(ys[y]+ys[y+1])*0.5)
			for rect in rects:
				if rect.has_point(center):
					occupied[Vector2i(x,y)]=true
					break
	var edges: Dictionary = {}
	for cell: Vector2i in occupied:
		var a := Vector2(xs[cell.x],ys[cell.y])
		var b := Vector2(xs[cell.x+1],ys[cell.y])
		var c := Vector2(xs[cell.x+1],ys[cell.y+1])
		var d := Vector2(xs[cell.x],ys[cell.y+1])
		if not occupied.has(cell+Vector2i.UP): edges[a]=b
		if not occupied.has(cell+Vector2i.RIGHT): edges[b]=c
		if not occupied.has(cell+Vector2i.DOWN): edges[c]=d
		if not occupied.has(cell+Vector2i.LEFT): edges[d]=a
	var loops: Array[PackedVector2Array] = []
	while not edges.is_empty():
		var start: Vector2 = edges.keys()[0]
		var point := start
		var path := PackedVector2Array()
		while edges.has(point):
			path.append(point)
			var next: Vector2 = edges[point]
			edges.erase(point)
			point=next
			if point==start: break
		if path.size()>=3 and point==start: loops.append(bevel(path,23))
	return loops

static func offset_left(poly: PackedVector2Array, amount: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(poly.size()):
		var incoming := (poly[i]-poly[(i-1+poly.size())%poly.size()]).normalized()
		var outgoing := (poly[(i+1)%poly.size()]-poly[i]).normalized()
		var n1 := Vector2(incoming.y,-incoming.x)
		var n2 := Vector2(outgoing.y,-outgoing.x)
		var bisector := (n1+n2).normalized()
		result.append(poly[i]+bisector*amount/maxf(bisector.dot(n2),0.3))
	return result

func projected(poly: PackedVector2Array, height: float=0) -> PackedVector2Array:
	var output := PackedVector2Array()
	for p in poly: output.append(WFIso.project(p)-Vector2(0,height))
	return output

func fill(poly: PackedVector2Array, color: Color, tex: Texture2D=null, height: float=0) -> void:
	if tex==null:
		draw_colored_polygon(projected(poly,height),color)
	else:
		var uv := PackedVector2Array()
		for p in poly: uv.append(p/220.0)
		draw_polygon(projected(poly,height),PackedColorArray([color]),uv,tex)

func curb(poly: PackedVector2Array) -> void:
	var outside := offset_left(poly,WALK_WIDTH)
	var top := projected(poly,CURB_HEIGHT)
	var outer := projected(outside,CURB_HEIGHT)
	var bottom := projected(poly)
	for i in range(poly.size()):
		var j := (i+1)%poly.size()
		draw_colored_polygon(PackedVector2Array([bottom[i],bottom[j],bottom[j]+Vector2(3,2),bottom[i]+Vector2(3,2)]),Color(0.20,0.27,0.27,0.24))
		var shade := Color("aab5b4") if (bottom[j]-bottom[i]).x>0 else Color("829597")
		draw_colored_polygon(PackedVector2Array([bottom[i],bottom[j],top[j],top[i]]),shade)
		draw_colored_polygon(PackedVector2Array([top[i],top[j],outer[j],outer[i]]),Color("d7d9ce"))
		draw_line(top[i],top[j],Color("edf0de"),1.3,true)
		draw_line(outer[i],outer[j],Color("8c9e91"),0.8,true)
		var count := maxi(1,ceili(poly[i].distance_to(poly[j])/29))
		for k in range(count):
			var t := float(k)/count
			draw_line(top[i].lerp(top[j],t),outer[i].lerp(outer[j],t),Color("a6b0a7"),0.8,true)

static func rounded_rect(rect: Rect2, radius: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var centers := [Vector2(rect.end.x-radius,rect.position.y+radius),rect.end-Vector2.ONE*radius,Vector2(rect.position.x+radius,rect.end.y-radius),rect.position+Vector2.ONE*radius]
	for corner in range(4):
		for i in range(7):
			var a := -PI/2+corner*PI/2+float(i)/6*PI/2
			result.append(centers[corner]+Vector2.from_angle(a)*radius)
	return result

func garden_plot(rect: Rect2) -> void:
	var outline := rounded_rect(rect.grow(4),24)
	var cap := projected(outline,6)
	var base := projected(outline)
	for i in range(outline.size()):
		var j := (i+1)%outline.size()
		draw_colored_polygon(PackedVector2Array([base[i],base[j],cap[j],cap[i]]),Color("8c7662"))
	fill(outline,Color("b2a58e"),null,6)
	fill(rounded_rect(rect.grow(-3),19),Color("619c78"),null,6)
	fill(rounded_rect(rect.grow(-3),19),Color(0.8,1,0.94,0.23),grass,6)
	# A few uneven plant tufts, avoiding the perfectly manicured miniature look.
	for i in range(12):
		var x := rect.position.x+12+fposmod(i*37.0,rect.size.x-24)
		var y := rect.position.y+12+fposmod(i*53.0,rect.size.y-24)
		var p := WFIso.project(Vector2(x,y))-Vector2(0,6)
		draw_line(p,p+Vector2(-2,-3),Color(0.32,0.49,0.36,0.25),1,true)

func _draw() -> void:
	super._draw()
	if road_contours.is_empty(): return
	# Preserve the original embankments/bridges, rebuild only the inner surface.
	slab(Rect2(-838,-700,1676,1400),Color("78ad88"))
	slab(Rect2(-838,-700,1676,1400),Color(0.82,1.0,1.0,0.25),grass,600)
	for contour in road_contours:
		if area(contour)>0:
			fill(contour,Color("8b9da8"))
			fill(contour,Color(0.82,0.92,1.0,0.48),stone)
	for contour in road_contours:
		if area(contour)<0:
			fill(contour,Color("78ad88"))
			fill(contour,Color(0.82,1.0,0.97,0.25),grass)
	for contour in road_contours: curb(contour)
	# Distinct paved forecourts meet the existing functional doorstep routes.
	for b in City.BUILDINGS:
		var foot := City.footprint(b)
		fill(bevel(PackedVector2Array([foot.position,Vector2(foot.end.x,foot.position.y),foot.end,Vector2(foot.position.x,foot.end.y)]),12),Color("cbd0c5"))
		var door := City.doorstep(b)
		var entry := Rect2(Vector2(door.x-23,b.at.y-5),Vector2(46,67))
		fill(rounded_rect(entry,10),Color("d0d4c9"))
	for garden in City.GARDENS: garden_plot(garden)
	# Retain the pond and summon rosette as navigation landmarks.
	var pond := WFIso.disc(City.POND,61)
	draw_colored_polygon(pond,Color("d9d6c4"))
	draw_colored_polygon(WFIso.disc(City.POND,55),Color("5aafbf"))
	draw_polyline(WFIso.ring(City.POND,52),Color("8dc7ce"),1.5,true)
	var center := Vector2(-60,60)
	for item in [[86,Color("829ba2")],[80,Color("d5ddcd")],[72,Color("9bb3b9")]]:
		draw_colored_polygon(WFIso.disc(center,item[0]),item[1])
	for radius in [62,49,27]: draw_polyline(WFIso.ring(center,radius),Color("dfe9d8"),1.5,true)
	for i in range(8):
		var direction := Vector2.from_angle(i*TAU/8)
		draw_line(WFIso.project(center+direction*29),WFIso.project(center+direction*60),Color("dce5d1"),2,true)
