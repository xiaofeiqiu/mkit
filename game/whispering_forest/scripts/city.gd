extends RefCounted

const Art = preload("res://game/whispering_forest/scripts/city_art.gd")

# Civic axis, inhabited blocks, continuous curtain wall and two bridge gates.
const BOUNDS := Vector2(1230,870)
const WALL := Vector2(900,740)
const GATE_Y := 40.0
const GATE_HALF := 66.0
const STATIONS := [
	{"id":"square","zh":"召唤广场","en":"Summoning Square","at":Vector2(105,130),"landing":Vector2(130,168),"note_zh":"梅尔 · 就职任务 · 副本传送","note_en":"Mel · initiation quests · quest instances"},
	{"id":"guild","zh":"冒险者公会","en":"Adventurers' Guild","at":Vector2(160,-175),"landing":Vector2(175,-130),"note_zh":"钟楼公会 · 委托前庭","note_en":"Bell-tower guild · commission forecourt"},
	{"id":"market","zh":"工匠商业街","en":"Artisans' Market","at":Vector2(-475,70),"landing":Vector2(-450,115),"note_zh":"铁匠铺 · 药草店 · 市集","note_en":"Smithy · apothecary · market hall"},
	{"id":"garden","zh":"宠物与采集区","en":"Companions' Garden","at":Vector2(125,420),"landing":Vector2(155,455),"note_zh":"伙伴之家 · 采集者庭院","note_en":"Companion lodge · gatherers' courtyard"},
	{"id":"gate","zh":"晨铃城门","en":"Bellwake Gate","at":Vector2(785,108),"landing":Vector2(820,70),"note_zh":"东城门 · 护城桥 · 出发广场","note_en":"East gate · moat bridge · departure square"},
]

# Anchors are foreground ground corners. Doors face a street; each ground
# footprint is independent of roof overhang and has rectangular collision.
const BUILDINGS := [
	{"id":"guild","asset":"guild","at":Vector2(175,-240),"zh":"晨铃公会","en":"Bellwake Guild"},
	{"id":"forge","asset":"forge","at":Vector2(-600,-240),"zh":"炉火工坊","en":"Hearthfire Smithy"},
	{"id":"apothecary","asset":"apothecary_r90","at":Vector2(-250,-240),"zh":"青叶药草店","en":"Greenleaf Apothecary"},
	{"id":"inn","asset":"inn_r270","at":Vector2(495,-240),"zh":"归人旅馆","en":"Wayfarer's Rest"},
	{"id":"market","asset":"market_hall_r180","at":Vector2(-250,290),"zh":"晨间市集","en":"Morning Market"},
	{"id":"lodge","asset":"pet_lodge_r180","at":Vector2(180,650),"zh":"伙伴之家","en":"Companion Lodge"},
	{"id":"west_homes","asset":"baker_house_r90","at":Vector2(-600,310),"zh":"麦香面包房","en":"Wheatsheaf Bakery"},
	{"id":"southwest_homes","asset":"garden_house_sage_r180","at":Vector2(-600,590),"zh":"花窗巷","en":"Flowerbox Lane"},
	{"id":"east_homes","asset":"townhouse_r270","at":Vector2(495,310),"zh":"东街民居","en":"East Street Homes"},
	{"id":"east_homes_2","asset":"garden_house_clay_r180","at":Vector2(790,290),"zh":"石桥巷","en":"Stonebridge Lane"},
	{"id":"northwest_homes","asset":"garden_house_ash","at":Vector2(-600,-550),"zh":"钟楼后街","en":"Belltower Lane"},
	{"id":"northeast_homes","asset":"townhouse_mauve_r180","at":Vector2(495,-530),"zh":"风铃巷","en":"Windchime Lane"},
	{"id":"southeast_homes","asset":"garden_house_sage","at":Vector2(790,590),"zh":"南墙民居","en":"South Wall Homes"},
]
const STREETS := [
	Rect2(-840,-35,1680,150),Rect2(-1110,-10,270,100),Rect2(840,-10,270,100),
	Rect2(-70,-240,140,720),Rect2(-50,-690,100,170),
	Rect2(-825,-210,1650,76),Rect2(-825,320,1650,135),
	Rect2(-805,-510,1610,80),
	Rect2(-579,-650,88,1325),Rect2(511,-650,88,1325),
	Rect2(-224,-495,64,815),Rect2(220,-495,72,1195),
	Rect2(-805,612,740,64),Rect2(228,620,577,64),
]
const PLAZAS := [Rect2(-180,-105,375,320),Rect2(-175,-240,420,135),Rect2(-520,-5,280,150),Rect2(-160,350,365,130),Rect2(705,-40,160,205),Rect2(-860,-35,110,180)]
const GARDENS := [Rect2(-430,-690,200,155),Rect2(75,-690,160,155),Rect2(-410,500,160,160),Rect2(290,485,195,180),Rect2(630,-650,170,190),Rect2(650,-365,145,140)]
const GARDEN_WALKS := [Rect2(-346,455,32,45),Rect2(109,-535,32,25)]
const RAMPS := [{"at":Vector2(-330,455),"asset":"curb_ramp"},{"at":Vector2(125,-510),"asset":"curb_ramp_r180"}]
const POND := Vector2(375,580)

static func footprint(building: Dictionary) -> Rect2:
	var size := Art.footprint(building.asset)
	return Rect2(building.at-size,size)

static func doorstep(building: Dictionary) -> Vector2:
	var offset := Art.door_offset(building.asset)
	return building.at+offset

static func door_normal(building: Dictionary) -> Vector2:
	var n: Array = Art.FRAMES[building.asset].door_normal
	return Vector2(n[0],n[1])

static func door_path(building: Dictionary) -> Rect2:
	var n := door_normal(building)
	var door := doorstep(building)
	var threshold := door-n*float(Art.FRAMES[building.asset].get("door_approach",24.0))
	var target := door+n*32.0
	var nearest := INF
	var walks := STREETS+PLAZAS+[Rect2(-880,-720,1760,36)]
	for walk in walks:
		var p := door.clamp(walk.position,walk.end)
		var delta := p-threshold
		if delta.dot(n)<1.0 or absf(delta.cross(n))>0.1: continue
		if delta.length()<nearest:
			nearest=delta.length()
			target=p+n*3.0
	var result := Rect2(threshold.min(target),(target-threshold).abs())
	if n.x==0: return Rect2(result.position-Vector2(22,0),result.size+Vector2(44,1))
	return Rect2(result.position-Vector2(0,22),result.size+Vector2(1,44))

static func station_near(at: Vector2, maximum: float = INF) -> int:
	var closest := -1
	for i in range(STATIONS.size()):
		var distance := at.distance_to(STATIONS[i].at)
		if distance<maximum:
			closest = i
			maximum = distance
	return closest

static func is_road(at: Vector2) -> bool:
	for street in STREETS:
		if street.has_point(at): return true
	for plaza in PLAZAS:
		if plaza.has_point(at): return true
	return false

static func inside_city(at: Vector2, radius: float) -> bool:
	if absf(at.x)<WALL.x-20-radius and absf(at.y)<WALL.y-20-radius:
		return true
	if absf(at.x)>1040+radius and absf(at.x)<1220-radius and at.y>-80+radius and at.y<160-radius:
		return true
	return absf(at.x)<1095-radius and absf(at.y-GATE_Y)<GATE_HALF-16-radius

static func blocked(at: Vector2, radius: float) -> bool:
	if not inside_city(at,radius): return true
	for building in BUILDINGS:
		if footprint(building).grow(radius).has_point(at): return true
	return ((at-POND)/Vector2(1.2,0.9)).length()<55+radius
