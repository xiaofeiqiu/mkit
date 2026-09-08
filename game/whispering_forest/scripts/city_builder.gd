extends RefCounted

const City = preload("res://game/whispering_forest/scripts/city.gd")
const SpriteProp = preload("res://game/whispering_forest/scripts/city_sprite.gd")
const Architecture = preload("res://game/whispering_forest/scripts/architecture.gd")
const Ground = preload("res://game/whispering_forest/scripts/city_ground.gd")
const Curbs = preload("res://game/whispering_forest/scripts/city_curbs.gd")
const Shadows = preload("res://game/whispering_forest/scripts/city_shadows.gd")

static func sprite(parent: Node2D,asset: String,at: Vector2,world_scale: float=1.0,radius: float=0) -> Node2D:
	var prop := SpriteProp.new()
	prop.asset = asset
	prop.ground = at
	prop.world_scale = world_scale
	prop.radius = radius
	prop.name = asset+"_%d" % parent.get_child_count()
	parent.add_child(prop)
	prop.owner = parent
	return prop

static func module(parent: Node2D,kind: String,at: Vector2,length: float=96,variant: int=0) -> Node2D:
	var prop := Architecture.new()
	prop.kind = kind
	prop.ground = at
	prop.length = length
	prop.variant = variant
	prop.name = kind+"_%d" % parent.get_child_count()
	parent.add_child(prop)
	prop.owner = parent
	return prop

static func wall_line(parent: Node2D,a: Vector2,b: Vector2) -> void:
	var count := ceili(a.distance_to(b)/96)
	for i in range(count):
		var c := a.lerp(b,float(i)/count)
		var d := a.lerp(b,float(i+1)/count)
		module(parent,"wall_u" if a.y==b.y else "wall_v",(c+d)*0.5,c.distance_to(d))

static func create() -> Node2D:
	var city := Node2D.new()
	city.name = "BellwakeLayout"
	city.y_sort_enabled = true
	var ground := Ground.new()
	ground.name = "StreetsGardensMoat"
	ground.z_index = -10
	city.add_child(ground)
	ground.owner = city
	var shadows := Shadows.new()
	shadows.name="SharedSunGroundShadows"
	shadows.z_index=-8
	city.add_child(shadows)
	shadows.owner=city
	var curbs := Curbs.new()
	curbs.name="RaisedCurbsAndRoundedCorners"
	curbs.z_index=-7
	city.add_child(curbs)
	curbs.owner=city
	for b in City.BUILDINGS:
		var prop := sprite(city,b.asset,b.at)
		prop.name = b.id
		prop.footprint = City.footprint(b).size
		prop.building_id = b.id
		prop.title_zh = b.zh
		prop.title_en = b.en
	# A closed rectangular perimeter, with exactly two intentional apertures.
	for y in [-City.WALL.y,City.WALL.y]:
		wall_line(city,Vector2(-City.WALL.x,y),Vector2(City.WALL.x,y))
	for x in [-City.WALL.x,City.WALL.x]:
		wall_line(city,Vector2(x,-City.WALL.y),Vector2(x,City.GATE_Y-City.GATE_HALF))
		wall_line(city,Vector2(x,City.GATE_Y+City.GATE_HALF),Vector2(x,City.WALL.y))
		module(city,"gate",Vector2(x,City.GATE_Y))
		for y in [City.GATE_Y-95,City.GATE_Y+95]: module(city,"tower",Vector2(x,y),96,1)
		for y in [-City.WALL.y,City.WALL.y]: module(city,"tower",Vector2(x,y))
		for y in [-420,430]: module(city,"tower",Vector2(x,y),96,1)
		# Bridge balustrades and square stone terminal posts share the bridge.
		for y in [-10,90]:
			for bx in [955,1020,1080]: module(city,"fence_u",Vector2(bx*signf(x),y),60)
	for y in [-City.WALL.y,City.WALL.y]:
		for x in [-460,0,460]: module(city,"tower",Vector2(x,y),96,1)
	for side in [-1,1]:
		for y in [-45,127]: sprite(city,"linden_young",Vector2(side*1160,y),1.0,10)
	# Small, repeated street trees occupy verge strips; none are random.
	for x in [-790,-665,-355,315,455,680,815]:
		for y in [-73,130]:
			var tree_x: float = -745 if x==-665 and y==130 else (-320 if x==-355 and y==130 else x)
			var species: String = ["linden","linden_young","linden_lean"][posmod(int(x+y),3)]
			sprite(city,species,Vector2(tree_x,y),1.0,11)
	for x in [-812,814]:
		for y in [-620,-400,-240,225,470,650]:
			var species: String = ["birch","linden_lean","spruce"][posmod(int(y),3)]
			sprite(city,species,Vector2(x,y),1.0,11)
	# Cypress pairs frame the guild frontage and the northern formal gardens.
	for x in [-160,200]:
		for y in [-380,-285]: sprite(city,"cypress",Vector2(x,y),1.0,8)
	for at in [Vector2(-410,-665),Vector2(-255,-665),Vector2(105,-665),Vector2(200,-665),Vector2(660,-620),Vector2(770,-620),Vector2(-400,550),Vector2(-280,625),Vector2(320,520),Vector2(460,640)]:
		sprite(city,"garden_tree" if at.y>0 else "cypress",at,1.0,8)
	for at in [Vector2(-140,-75),Vector2(155,-75),Vector2(-140,190),Vector2(170,195),Vector2(-470,-25),Vector2(-265,100),Vector2(-115,460),Vector2(210,485),Vector2(720,-12),Vector2(820,160)]:
		module(city,"planter",at,96,int(at.x)%2)
	for at in [Vector2(-165,120),Vector2(170,25),Vector2(-355,-610),Vector2(155,-610),Vector2(340,650),Vector2(-330,525)]: module(city,"bench",at)
	for x in [-745,-410,260,625]:
		for y in [-30,110]: module(city,"lamp",Vector2(x,y))
	for at in [Vector2(-140,-140),Vector2(215,-140),Vector2(-95,370),Vector2(210,385)]: module(city,"lamp",at)
	# Low fences define garden plots, with openings toward the paved lanes.
	for garden in City.GARDENS:
		wall_fence(city,garden)
	return city

static func wall_fence(parent: Node2D,rect: Rect2) -> void:
	for y in [rect.position.y,rect.end.y]:
		var n := ceili(rect.size.x/60)
		for i in range(n):
			if i==0 or i==n-1: continue # open rounded corners frame the rail's straight run
			if y==rect.end.y and i==n/2: continue
			module(parent,"fence_u",Vector2(rect.position.x+(i+0.5)*rect.size.x/n,y),rect.size.x/n)
