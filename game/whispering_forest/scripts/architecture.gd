@tool
extends Node2D

# Deterministic architectural modules. All vertices use the gameplay ground
# projection, so wall ends, crenellations and gate apertures meet exactly.
@export_enum("wall_u","wall_v","tower","gate","planter","bench","lamp","fence_u","fence_v") var kind := "wall_u"
@export var ground := Vector2.ZERO
@export var length := 96.0
@export var wall_height := 108.0
@export var variant := 0
var world: Node
var masonry: Texture2D
var radius := 0.0
var asset := ""
var native_sprite: Sprite2D
const Art = preload("res://game/whispering_forest/scripts/city_art.gd")

func asset_id() -> String:
	match kind:
		"wall_u","wall_v":
			var base := "wall_long" if length>93 else ("wall_north" if length<90 else "wall_south")
			return base+("_r90" if kind=="wall_v" else "")
		"tower": return "tower_corner" if variant==0 else "tower_curtain"
		"gate": return "gatehouse"
		"planter": return "civic_planter"
		"bench": return "civic_bench"
		"lamp": return "civic_lamp"
		"fence_u","fence_v": return "fence_%d%s" % [roundi(length*1000),"_r90" if kind=="fence_v" else ""]
	return ""

func blocks(at: Vector2, actor_radius: float) -> bool:
	var local := at-ground
	match kind:
		"tower": return local.length()<(36.0 if variant==0 else 30.0)+actor_radius
		"planter": return Rect2(-24,-24,48,48).grow(actor_radius).has_point(local)
		"bench": return Rect2(-29,-12,58,27).grow(actor_radius).has_point(local)
		"lamp": return local.length()<5+actor_radius
		"fence_u": return Rect2(-length/2,-3,length,6).grow(actor_radius).has_point(local)
		"fence_v": return Rect2(-3,-length/2,6,length).grow(actor_radius).has_point(local)
	return false # curtain walls / aperture boundaries are continuous City geometry

func _ready() -> void:
	position = WFIso.project(ground)
	asset=asset_id()
	if Art.FRAMES.has(asset):
		var entry: Dictionary = Art.FRAMES[asset]
		native_sprite=Sprite2D.new()
		native_sprite.name="SharedProjectionArtwork"
		native_sprite.texture=load(Art.ROOT+asset+".png")
		native_sprite.centered=false
		native_sprite.offset=-Vector2(entry.pivot[0],entry.pivot[1])
		native_sprite.scale=Vector2.ONE*float(entry.scale)
		native_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(native_sprite)
		wall_height=float(entry.height_metres)*39.19184
	masonry = load("res://game/whispering_forest/assets/city-v2/masonry.png")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()

func point(p: Vector2, h: float=0.0) -> Vector2:
	return WFIso.project(p)-Vector2(0,h)

func quad(points: Array, color: Color, textured: bool=false) -> void:
	var poly := PackedVector2Array(points)
	if textured and masonry!=null:
		var uv := PackedVector2Array()
		for p in poly: uv.append((p+position)/210.0)
		draw_polygon(poly,PackedColorArray([color]),uv,masonry)
	else:
		draw_colored_polygon(poly,color)

func face(a: Vector2,b: Vector2,low: float,high: float,tint: Color) -> void:
	var poly := PackedVector2Array([point(a,low),point(b,low),point(b,high),point(a,high)])
	# Mortar courses follow the world-facing wall, rather than screen x/y.
	var u := (ground.x+ground.y+a.x+a.y)/180.0
	var span := a.distance_to(b)/180.0
	var uv := PackedVector2Array([Vector2(u,-low/180),Vector2(u+span,-low/180),Vector2(u+span,-high/180),Vector2(u,-high/180)])
	if masonry!=null: draw_polygon(poly,PackedColorArray([tint]),uv,masonry)
	else: draw_colored_polygon(poly,tint)
	draw_line(point(a,high),point(b,high),Color(0.97,0.95,0.84,0.7),1,true)

func box(rect: Rect2,height: float,base: float=0.0,tint: Color=Color.WHITE) -> void:
	var a := rect.position
	var b := Vector2(rect.end.x,rect.position.y)
	var c := rect.end
	var d := Vector2(rect.position.x,rect.end.y)
	face(b,c,base,base+height,Color(0.71,0.77,0.82)*tint)
	face(c,d,base,base+height,Color(0.95,0.93,0.85)*tint)
	quad([point(a,base+height),point(b,base+height),point(c,base+height),point(d,base+height)],Color(1.08,1.06,0.98)*tint,true)

func wall(axis: Vector2) -> void:
	var size := Vector2(length,26) if axis.x>0 else Vector2(26,length)
	var rect := Rect2(-size*0.5,size)
	box(rect.grow(5),13)
	box(rect,wall_height)
	box(rect.grow(3),7,wall_height-10)
	# Thick coping caps and separated merlons; no disconnected gate props.
	var count := maxi(1,int(length/28))
	for i in range(count):
		var at := axis*((i+0.5)*length/count-length*0.5)
		var merlon := Vector2(16,30) if axis.x>0 else Vector2(30,16)
		box(Rect2(at-merlon*0.5,merlon),19,wall_height)
		box(Rect2(at-merlon*0.5,merlon).grow(1.5),3,wall_height+19)
	# Buttress end shared by every 96-unit section hides no geometry gaps.
	box(Rect2(-Vector2(15,15),Vector2(30,30)),wall_height-8,0,Color(0.98,0.97,0.93))

func cylinder(radius: float,height: float,base: float=0.0) -> void:
	var count := 16
	for i in range(count):
		var a := Vector2.from_angle(i*TAU/count)*radius
		var b := Vector2.from_angle((i+1)*TAU/count)*radius
		if (a+b).x+(a+b).y<0: continue
		var shade := 0.82+0.12*cos(i*TAU/count-1.8)
		face(a,b,base,base+height,Color(shade,shade+0.02,shade+0.02))
	var cap := PackedVector2Array()
	for i in range(count): cap.append(point(Vector2.from_angle(i*TAU/count)*radius,base+height))
	draw_colored_polygon(cap,Color("ded8c4"))

func tower() -> void:
	var r := 36.0 if variant==0 else 30.0
	var h := 150.0 if variant==0 else 137.0
	cylinder(r+6,12)
	cylinder(r,h)
	cylinder(r+3,7,h-12)
	cylinder(r+5,8,h)
	for i in range(10):
		var a := Vector2.from_angle(i*TAU/10)*(r-1)
		box(Rect2(a-Vector2(6,6),Vector2(12,12)),17,h+7)
	# Recessed arrow slit and a crisp stone sill, on the lit face.
	var slit := point(Vector2(9,r-4),h*0.63)
	draw_line(slit+Vector2(0,-9),slit+Vector2(0,12),Color("535a58"),3,true)
	draw_line(slit+Vector2(-5,11),slit+Vector2(5,11),Color("efe7d3"),2,true)

func gate() -> void:
	# The opening spans v = -66..66. Curved arch stones span the same opening
	# as the wall/collision aperture and bridge, with a 56-unit deep passage.
	var depth := 31.0
	for rear in [true,false]:
		var u := -depth if rear else depth
		var tint := Color(0.70,0.76,0.79) if rear else Color(1.0,0.96,0.86)
		for i in range(16):
			var a := PI*i/16
			var b := PI*(i+1)/16
			var y1 := -cos(a)*66
			var y2 := -cos(b)*66
			var h1 := 66+sin(a)*57
			var h2 := 66+sin(b)*57
			quad([point(Vector2(u,y1),h1),point(Vector2(u,y2),h2),point(Vector2(u,y2),158),point(Vector2(u,y1),158)],tint,true)
			draw_line(point(Vector2(u,y1),h1),point(Vector2(u,y1),minf(h1+20,158)),Color("a6977d"),1.5,true)
		if not rear:
			for side in [-1,1]:
				face(Vector2(u,side*66),Vector2(u,side*90),0,158,tint)
	box(Rect2(-depth,-95,depth*2,190),10,154)
	for i in range(7): box(Rect2(depth-5,-91+i*27,15,15),18,164)
	# Blue pennants are placed over masonry, never across the walking aperture.
	for side in [-1,1]:
		var p := point(Vector2(depth+1,side*83),145)
		quad([p,p+Vector2(13,6),p+Vector2(13,44),p+Vector2(6,39),p+Vector2(0,38)],Color("397c9d"))
		draw_line(p+Vector2(-2,-2),p+Vector2(15,6),Color("c8ab65"),2,true)

func planter() -> void:
	box(Rect2(-22,-22,44,44),10)
	box(Rect2(-24,-24,48,48),3,10)
	var center := point(Vector2.ZERO,14)
	draw_set_transform(center,0,Vector2(1,0.55))
	draw_circle(Vector2.ZERO,24,Color("385e43"))
	draw_circle(Vector2(0,-2),21,Color("51815b"))
	for i in range(9):
		var p := Vector2.from_angle(i*2.4)*sqrt(float(i))*6
		draw_circle(p,3.2,Color("e5dde9") if variant%2 else Color("f1eacb"))
	draw_set_transform(Vector2.ZERO)

func bench() -> void:
	for x in [-22,22]: box(Rect2(x,-8,5,20),15,0,Color("8c8477"))
	for y in [-9,-3,3,9]:
		var a := point(Vector2(-29,y),17)
		var b := point(Vector2(29,y),17)
		draw_line(a,b,Color("997143"),4,true)
	for h in [27,34]: draw_line(point(Vector2(-29,-12),h),point(Vector2(29,-12),h),Color("967041"),5,true)

func lamp() -> void:
	box(Rect2(-6,-6,12,12),6)
	draw_line(Vector2.ZERO,Vector2(0,-77),Color("424e4a"),3,true)
	draw_line(Vector2(0,-77),Vector2(10,-84),Color("424e4a"),2,true)
	quad([Vector2(5,-83),Vector2(16,-83),Vector2(14,-67),Vector2(7,-67)],Color("d4be78"))
	draw_rect(Rect2(5,-84,11,3),Color("4d5a56"))
	draw_line(Vector2(10,-83),Vector2(10,-67),Color("646d58"),1,true)

func fence(axis: Vector2) -> void:
	for t in [-0.5,0,0.5]:
		var p: Vector2 = axis*length*t
		box(Rect2(p-Vector2(3,3),Vector2(6,6)),29,0,Color("b6ab8e"))
	for h in [12,23]: draw_line(point(-axis*length/2,h),point(axis*length/2,h),Color("aa9672"),3,true)

func _draw() -> void:
	if native_sprite!=null: return
	match kind:
		"wall_u": wall(Vector2.RIGHT)
		"wall_v": wall(Vector2.DOWN)
		"tower": tower()
		"gate": gate()
		"planter": planter()
		"bench": bench()
		"lamp": lamp()
		"fence_u": fence(Vector2.RIGHT)
		"fence_v": fence(Vector2.DOWN)
