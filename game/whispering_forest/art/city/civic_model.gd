extends "res://game/whispering_forest/art/city/building_model.gd"

# Editable civic modules, measured in metres. Wall endpoints and gate aperture
# are shared with the logical city plan; neither images nor meshes are stretched.
static func catalog() -> Dictionary:
	var result := {
		"wall_long":{"type":"wall","length":1800.0/19},
		"wall_north":{"type":"wall","length":714.0/8},
		"wall_south":{"type":"wall","length":634.0/7},
		"tower_corner":{"type":"tower","radius":36.0,"height":5.0},
		"tower_curtain":{"type":"tower","radius":30.0,"height":4.65},
		"gatehouse":{"type":"gate","height":5.0},
		"civic_bench":{"type":"bench","height":0.92},
		"civic_lamp":{"type":"lamp","height":2.8},
		"civic_planter":{"type":"planter","height":0.8},
		"curb_arc":{"type":"arc","radius":24.0,"height":0.12},
		"curb_outer":{"type":"outer","height":0.12},
		"curb_inner":{"type":"inner","height":0.12},
		"curb_chamfer":{"type":"chamfer","height":0.12},
		"curb_end":{"type":"end","height":0.12},
		"curb_ramp":{"type":"ramp","height":0.12}
	}
	for length_value in [32,16,8,4,2,1]: result["curb_%d" % length_value]={"type":"curb","length":length_value,"height":0.12}
	for length_value in [60.0,50.0,160.0/3,195.0/4,170.0/3,145.0/3]:
		result["fence_%d" % roundi(length_value*1000)]={"type":"fence","length":length_value,"height":0.95}
	return result

func build(asset_kind: String) -> void:
	kind=asset_kind
	name=kind.to_pascal_case()
	var spec: Dictionary = catalog()[kind]
	set_meta("asset_id",kind)
	set_meta("ground_size",Vector2.ZERO)
	set_meta("ground_corner",Vector3.ZERO)
	set_meta("door_ground",Vector3.ZERO)
	set_meta("height",spec.get("height",4.1))
	set_meta("module_spec",spec)
	mats={"stone":material("e1e0d2","wallstone",0.34),"shade":material("a8ac9e","wallstone",0.34),"cap":material("e6e4d7","wallstone",0.25),"mortar":material("858d84"),"iron":material("48565a"),"wood":material("c3b099","wood",0.8),"gold":material("bda675"),"glass":material("e5d9a8"),"leaf":material("6c9b78"),"flower":material("cbb3cb")}
	for key in ["stone","shade","cap"]:
		var limestone := ShaderMaterial.new()
		limestone.shader=load("res://game/whispering_forest/art/city/painted_limestone.gdshader")
		limestone.set_shader_parameter("paint",load("res://game/whispering_forest/art/city/materials/wallstone.png"))
		limestone.set_shader_parameter("stone_color",Color({"stone":"c9c9b8","shade":"b9bfae","cap":"dddccb"}[key]))
		mats[key]=limestone
	match spec.type:
		"wall": curtain(float(spec.length)/32.0)
		"tower": stone_tower(float(spec.radius)/32.0,float(spec.height))
		"gate": gatehouse()
		"bench": street_bench()
		"lamp": street_lamp()
		"planter": stone_planter()
		"fence": fence(float(spec.length)/32.0)
		"curb": curb_line(Vector2(-float(spec.length)/64,0),Vector2(float(spec.length)/64,0))
		"arc": curb_arc()
		"outer","inner":
			curb_line(Vector2(-0.5,0),Vector2.ZERO)
			curb_line(Vector2(0,0),Vector2(0,0.5 if spec.type=="outer" else -0.5))
		"chamfer": curb_line(Vector2(-0.5,0),Vector2(0,0.5))
		"end":
			curb_line(Vector2(-0.125,0),Vector2(0.125,0))
			cylinder(self,Vector3(0.125,0.06,0),0.12,0.065,mats.cap,-1,12)
		"ramp": ramp()
	assign_owner(self)

func stone_box(parent: Node3D,at: Vector3,size: Vector3,tone: int=0) -> void:
	# Recessed mortar, a clipped cap and a slightly proud stone face give every
	# course real depth. Wear comes from the shared surface, not screen noise.
	box(parent,at,size,mats.stone if tone%4 else mats.shade)
	if size.y>0.16:
		box(parent,at+Vector3(0,size.y/2-0.018,0),Vector3(size.x-0.035,0.035,size.z-0.025),mats.cap)

func courses(parent: Node3D,size: Vector3,at: Vector3=Vector3.ZERO) -> void:
	box(parent,at+Vector3(0,size.y/2,0),size-Vector3(0.025,0,0.025),mats.mortar)
	var rows := ceili(size.y/0.32)
	for row in range(rows):
		var height := size.y/rows
		var count := maxi(1,ceili(size.x/0.66))
		var span := size.x/count
		var cuts: Array[float] = [-size.x/2]
		for i in range(count+1):
			var x := -size.x/2+(i+0.5*(row%2))*span
			if x>cuts[0]+0.02 and x<size.x/2-0.02: cuts.append(x)
		cuts.append(size.x/2)
		for i in range(cuts.size()-1):
			stone_box(parent,at+Vector3((cuts[i]+cuts[i+1])/2,(row+0.5)*height,0),Vector3(cuts[i+1]-cuts[i]-0.026,height-0.021,size.z),row*7+i*3)

func curtain(span: float) -> void:
	var wall := group("CoursedCurtainWall")
	courses(wall,Vector3(span,3.35,1.10))
	box(wall,Vector3(0,0.10,0),Vector3(span,0.20,1.27),mats.shade,"BatteredFoundation")
	box(wall,Vector3(0,3.36,0),Vector3(span,0.13,1.17),mats.cap,"StoneWallWalk")
	for side in [-1,1]:
		box(wall,Vector3(0,3.58,side*0.44),Vector3(span,0.35,0.22),mats.stone,"Parapet")
		var count := maxi(2,roundi(span/0.87))
		for i in range(count):
			var p := Vector3(-span/2+(i+0.5)*span/count,3.94,side*0.44)
			stone_box(wall,p,Vector3(0.43,0.45,0.29),i)
			box(wall,p+Vector3(0,0.23,0),Vector3(0.48,0.06,0.34),mats.cap)
	# End coordinates are exact, so all three selected wall lengths tile.
	set_meta("connectors",[Vector3(-span/2,0,0),Vector3(span/2,0,0)])

func stone_tower(r: float,h: float) -> void:
	var tower := group("RoundMasonryTower")
	cylinder(tower,Vector3(0,0.12,0),0.24,r+0.17,mats.shade,-1,20)
	cylinder(tower,Vector3(0,h/2,0),h,r-0.025,mats.mortar,-1,20)
	var rows := ceili(h/0.32)
	for row in range(rows):
		for i in range(16):
			var a := TAU*(i+(row%2)*0.5)/16
			var n := box(tower,Vector3(cos(a)*(r-0.07),(row+0.5)*h/rows,sin(a)*(r-0.07)),Vector3(0.14,h/rows-0.013,2*r*tan(PI/16)-0.013),mats.stone if (row+i)%5 else mats.shade)
			n.rotation.y=-a
	cylinder(tower,Vector3(0,h-0.15,0),0.12,r+0.045,mats.cap,-1,20)
	cylinder(tower,Vector3(0,h+0.035,0),0.13,r+0.085,mats.cap,-1,20)
	for i in range(12):
		var a := i*TAU/12
		var n := box(tower,Vector3(cos(a)*(r-0.08),h+0.37,sin(a)*(r-0.08)),Vector3(0.30,0.50,0.28),mats.stone)
		n.rotation.y=-a
		box(n,Vector3(0,0.27,0),Vector3(0.36,0.07,0.34),mats.cap)
	for a in [0.0,PI/2,PI,PI*1.5]:
		var slit := group("DeepArrowSlit",tower)
		slit.rotation.y=a
		box(slit,Vector3(0,h*0.66,r+0.012),Vector3(0.07,0.65,0.016),mats.iron)
		box(slit,Vector3(0,h*0.66-0.34,r+0.026),Vector3(0.28,0.08,0.12),mats.cap)
	set_meta("height",h+0.67)

func gatehouse() -> void:
	var gate := group("DeepStoneGateway")
	var radius := 66.0/32.0
	var depth := 62.0/32.0
	for side in [-1,1]:
		courses(gate,Vector3(depth,4.65,0.77),Vector3(0,0,side*(radius+0.385)))
	# Each voussoir is a closed extruded solid through the whole passage.
	for i in range(18):
		var a := i*PI/18+0.006
		var b := (i+1)*PI/18-0.006
		var outline := [Vector2(cos(a)*radius,2.15+sin(a)*1.63),Vector2(cos(b)*radius,2.15+sin(b)*1.63),Vector2(cos(b)*(radius+0.33),2.15+sin(b)*1.63+0.42),Vector2(cos(a)*(radius+0.33),2.15+sin(a)*1.63+0.42)]
		extrude_arch_stone(gate,outline,depth,mats.cap if i%3 else mats.stone)
		for side in [-1,1]:
			var face_points := PackedVector3Array([Vector3(side*depth/2,outline[3].y,outline[3].x),Vector3(side*depth/2,outline[2].y,outline[2].x),Vector3(side*depth/2,4.68,outline[2].x),Vector3(side*depth/2,4.68,outline[3].x)])
			polygon(gate,face_points,mats.stone)
	box(gate,Vector3(0,4.73,0),Vector3(depth+0.15,0.17,5.7),mats.cap,"BridgeAcrossArch")
	for side in [-1,1]:
		box(gate,Vector3(side*(depth/2-0.12),4.9,0),Vector3(0.26,0.22,5.7),mats.stone)
		for i in range(7): stone_box(gate,Vector3(side*(depth/2-0.12),5.18,-2.59+i*0.86),Vector3(0.30,0.37,0.48),i)
	# Portcullis is visibly raised above the traversable aperture.
	for i in range(13):
		var z := -radius+0.2+i*(radius*2-0.4)/12
		box(gate,Vector3(-0.05,4.22,z),Vector3(0.08,0.68,0.045),mats.iron)
	box(gate,Vector3(-0.05,4.11,0),Vector3(0.08,0.06,radius*2),mats.iron)
	set_meta("height",5.4)
	set_meta("aperture",{"half_width":66.0,"depth":62.0,"clear_height_metres":2.15})
	set_meta("connectors",[Vector3(0,0,-95.0/32),Vector3(0,0,95.0/32)])

func extrude_arch_stone(parent: Node3D,outline: Array,depth: float,mat: Material) -> void:
	for side in [-1,1]:
		var poly := PackedVector3Array()
		for p in outline: poly.append(Vector3(side*depth/2,p.y,p.x))
		polygon(parent,poly,mat)
	for i in range(outline.size()):
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i+1)%outline.size()]
		polygon(parent,PackedVector3Array([Vector3(-depth/2,a.y,a.x),Vector3(depth/2,a.y,a.x),Vector3(depth/2,b.y,b.x),Vector3(-depth/2,b.y,b.x)]),mat)

func street_bench() -> void:
	for x in [-0.67,0.67]:
		box(self,Vector3(x,0.24,0),Vector3(0.09,0.48,0.54),mats.iron)
		beam(self,Vector3(x,0.32,-0.23),Vector3(x,0.91,-0.27),0.065,mats.iron)
	for z in [-0.20,-0.065,0.065,0.20]: box(self,Vector3(0,0.49,z),Vector3(1.8,0.07,0.115),mats.wood)
	for y in [0.71,0.87]: box(self,Vector3(0,y,-0.26),Vector3(1.8,0.12,0.055),mats.wood)

func street_lamp() -> void:
	cylinder(self,Vector3(0,0.10,0),0.20,0.18,mats.cap,-1,8)
	cylinder(self,Vector3(0,1.3,0),2.5,0.045,mats.iron,0.03,12)
	for y in [0.28,0.48,2.23]: cylinder(self,Vector3(0,y,0),0.07,0.085,mats.iron,-1,12)
	box(self,Vector3(0,2.48,0),Vector3(0.24,0.34,0.24),mats.glass)
	for x in [-0.13,0.13]:
		for z in [-0.13,0.13]: beam(self,Vector3(x,2.28,z),Vector3(x,2.68,z),0.027,mats.iron)
	cylinder(self,Vector3(0,2.74,0),0.22,0.24,mats.iron,0.025,4).rotation.y=PI/4

func stone_planter() -> void:
	box(self,Vector3(0,0.16,0),Vector3(1.38,0.32,1.38),mats.shade)
	for side in [-1,1]:
		box(self,Vector3(side*0.70,0.37,0),Vector3(0.12,0.12,1.52),mats.cap)
		box(self,Vector3(0,0.37,side*0.70),Vector3(1.52,0.12,0.12),mats.cap)
	box(self,Vector3(0,0.34,0),Vector3(1.26,0.07,1.26),mats.mortar)
	for i in range(12):
		var sphere := SphereMesh.new()
		sphere.radius=0.25
		sphere.height=0.35
		sphere.radial_segments=10
		sphere.rings=6
		var a := i*2.39996
		var p := Vector3(cos(a)*0.43,0.54+sin(i*1.4)*0.035,sin(a)*0.43)
		mesh(self,sphere,p,mats.leaf)
		cylinder(self,p+Vector3(0,0.19,0),0.05,0.06,mats.flower,-1,7)

func fence(span: float) -> void:
	for x in [-span/2,span/2]:
		courses(self,Vector3(0.15,0.87,0.15),Vector3(x,0,0))
		box(self,Vector3(x,0.90,0),Vector3(0.23,0.08,0.23),mats.cap)
	for y in [0.35,0.72]: box(self,Vector3(0,y,0),Vector3(span,0.055,0.06),mats.iron)
	for i in range(maxi(2,int(span/0.20))):
		var x := -span/2+(i+0.5)*span/maxi(2,int(span/0.20))
		box(self,Vector3(x,0.51,0),Vector3(0.032,0.55,0.032),mats.iron)

func curb_line(a: Vector2,b: Vector2) -> void:
	var center := (a+b)*0.5
	var stone := box(self,Vector3(center.x,0.056,center.y),Vector3(a.distance_to(b),0.112,0.13),mats.cap)
	stone.rotation.y=-a.angle_to_point(b)
	box(stone,Vector3(0,0.052,0),Vector3(a.distance_to(b)-0.006,0.016,0.105),mats.cap)
	set_meta("connectors",[Vector3(a.x,0,a.y),Vector3(b.x,0,b.y)])

func curb_arc() -> void:
	# The inner edge follows an exact 24-unit radius, matching the paving path.
	var radius := 24.0/32
	for i in range(12):
		var a := i*PI/24
		var b := (i+1)*PI/24
		var p := Vector2(cos(a),sin(a))*(radius+0.025)
		var q := Vector2(cos(b),sin(b))*(radius+0.025)
		curb_line(p,q)
	set_meta("connectors",[Vector3(radius,0,0),Vector3(0,0,radius)])

func ramp() -> void:
	var top := PackedVector3Array([Vector3(-0.5,0.015,-0.25),Vector3(0.5,0.015,-0.25),Vector3(0.5,0.12,0.25),Vector3(-0.5,0.12,0.25)])
	polygon(self,top,mats.cap,"SlopedAccessibleThreshold")
	for side in [-1,1]: polygon(self,PackedVector3Array([Vector3(side*0.5,0,-0.25),Vector3(side*0.5,0.015,-0.25),Vector3(side*0.5,0.12,0.25),Vector3(side*0.5,0,0.25)]),mats.stone)
