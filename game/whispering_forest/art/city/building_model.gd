extends Node3D

# Authoring source for independent Bellwake building scenes. Dimensions are
# metres; one metre is 32 logical map units. Geometry determines perspective.
const SPECS := {
	"guild": {"lot":Vector2(9.4,5.1),"height":5.5,"roof":1.8,"floors":2},
	"forge": {"lot":Vector2(5.7,5.0),"height":3.0,"roof":1.65,"floors":1},
	"apothecary": {"lot":Vector2(5.4,4.8),"height":5.0,"roof":1.55,"floors":2},
	"inn": {"lot":Vector2(5.8,4.8),"height":5.2,"roof":1.8,"floors":2},
	"market_hall": {"lot":Vector2(6.6,3.2),"height":2.65,"roof":1.55,"floors":1},
	"pet_lodge": {"lot":Vector2(5.7,4.4),"height":2.85,"roof":1.6,"floors":1},
	"garden_house": {"lot":Vector2(5.0,4.2),"height":2.95,"roof":1.7,"floors":1},
	"townhouse": {"lot":Vector2(5.6,4.6),"height":5.1,"roof":1.9,"floors":2},
	"baker_house": {"lot":Vector2(6.0,4.8),"height":5.1,"roof":1.6,"floors":2},
}
const VARIANTS := {
	"garden_house_sage":{"model":"garden_house","roof":"sage"},
	"garden_house_clay":{"model":"garden_house","roof":"clay"},
	"garden_house_ash":{"model":"garden_house","roof":"ash"},
	"townhouse_mauve":{"model":"townhouse","roof":"mauve"}
}
const ROOF_COLORS := {"blue":"486c91","sage":"718778","clay":"b87957","ash":"697b83","mauve":"8b6b80"}
const DEFAULT_ROOFS := {"guild":"blue","forge":"ash","apothecary":"sage","inn":"mauve","market_hall":"clay","pet_lodge":"sage","garden_house":"blue","townhouse":"ash","baker_house":"clay"}
var mats: Dictionary = {}
var lot := Vector2.ZERO
var kind := ""
var roof_finish := "blue"
var serial := 0
var groups: Dictionary = {}

func material(hex: String, texture_name: String="", uv_scale: float=1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.92
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not texture_name.is_empty():
		var path := "res://game/whispering_forest/art/city/materials/%s.png" % texture_name
		if ResourceLoader.exists(path):
			m.albedo_texture = load(path)
			m.uv1_triplanar = true
			m.uv1_scale = Vector3.ONE*uv_scale
	return m

func group(label: String,parent: Node3D=null) -> Node3D:
	if parent==null: parent=self
	var g := Node3D.new()
	g.name = label
	parent.add_child(g)
	return g

func mesh(parent: Node3D, shape: Mesh, at: Vector3, mat: Material, label: String="") -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label if not label.is_empty() else "Detail_%04d" % serial
	serial+=1
	n.mesh = shape
	n.material_override = mat
	n.position = at
	parent.add_child(n)
	return n

func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, label: String="") -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return mesh(parent,b,at,mat,label)

func cylinder(parent: Node3D, at: Vector3,height: float, radius: float, mat: Material, top: float=-1, sides: int=16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.height = height
	c.bottom_radius = radius
	c.top_radius = radius if top<0 else top
	c.radial_segments = sides
	return mesh(parent,c,at,mat)

func beam(parent: Node3D,a: Vector3,b: Vector3,width: float,mat: Material) -> void:
	var n := box(parent,(a+b)*0.5,Vector3(width,a.distance_to(b),width),mat)
	var up := (b-a).normalized()
	var across := up.cross(Vector3.FORWARD).normalized()
	if across.length_squared()<0.1: across = up.cross(Vector3.RIGHT).normalized()
	n.basis = Basis(across,up,across.cross(up)).orthonormalized()

func polygon(parent: Node3D,points: PackedVector3Array,mat: Material,label: String="") -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()-1):
		for p in [points[0],points[i],points[i+1]]:
			st.set_uv(Vector2(p.x,p.y))
			st.add_vertex(p)
	st.generate_normals()
	mesh(parent,st.commit(),Vector3.ZERO,mat,label)

func facade(at: Vector3, rotation_y: float=0) -> Node3D:
	var g := group("Facade_%04d" % serial,groups.facades)
	serial+=1
	g.position = at
	g.rotation.y = rotation_y
	return g

func arch(parent: Node3D,center: Vector3,width: float,height: float,mat: Material,thickness: float=0.13) -> void:
	var radius := width*0.5
	var spring := height-radius
	for side in [-1,1]:
		box(parent,center+Vector3(side*(radius+thickness*0.5),spring*0.5,0),Vector3(thickness,spring,0.19),mat)
	for i in range(13):
		var a := i*PI/13
		var b := (i+1)*PI/13
		var pts := PackedVector3Array()
		for t in [Vector2(a,radius),Vector2(b,radius),Vector2(b,radius+thickness),Vector2(a,radius+thickness)]:
			pts.append(center+Vector3(cos(t.x)*t.y,spring+sin(t.x)*t.y,0.01))
		polygon(parent,pts,mat)

func arched_fill(parent: Node3D,at: Vector3,width: float,height: float,mat: Material) -> void:
	var r := width*0.5
	var pts := PackedVector3Array([at+Vector3(-r,0,0),at+Vector3(r,0,0)])
	for i in range(17):
		var a := i*PI/16
		pts.append(at+Vector3(cos(a)*r,height-r+sin(a)*r,0))
	polygon(parent,pts,mat)

func window_at(at: Vector3,width: float=0.80,height: float=1.22,angle: float=0,shutters: bool=true,flowers: bool=false,arched: bool=false) -> void:
	var f := facade(at,angle)
	box(f,Vector3(0,height*0.5,0.025),Vector3(width+0.17,height+0.12,0.14),mats.recess,"Recess")
	if arched:
		arched_fill(f,Vector3(0,0,0.11),width,height,mats.glass)
		arch(f,Vector3(0,0,0.14),width,height,mats.stone)
	else:
		box(f,Vector3(0,height*0.5,0.105),Vector3(width,height,0.045),mats.glass,"Glass")
		for x in [-width*0.5,width*0.5]: box(f,Vector3(x,height*0.5,0.16),Vector3(0.09,height+0.12,0.10),mats.cream)
		for y in [0.0,height]: box(f,Vector3(0,y,0.16),Vector3(width+0.12,0.1,0.1),mats.cream)
	box(f,Vector3(0,height*0.5,0.18),Vector3(0.055,height,0.07),mats.wood)
	box(f,Vector3(0,height*0.52,0.18),Vector3(width,0.055,0.07),mats.wood)
	box(f,Vector3(0,-0.08,0.14),Vector3(width+0.3,0.14,0.35),mats.stone,"Sill")
	box(f,Vector3(0,height+0.16,0.07),Vector3(width+0.28,0.15,0.22),mats.stone,"Lintel")
	if shutters:
		for side in [-1,1]:
			var x: float = side*(width*0.5+0.24)
			box(f,Vector3(x,height*0.5,0.05),Vector3(0.33,height,0.10),mats.blue,"Shutter")
			for y in [height*0.22,height*0.77]: box(f,Vector3(x,y,0.11),Vector3(0.33,0.06,0.04),mats.iron)
			for dx in [-0.08,0.08]: box(f,Vector3(x+dx,height*0.5,0.11),Vector3(0.018,height,0.015),mats.blue_dark)
	if flowers: flower_box(f,Vector3(0,-0.08,0.36),width+0.15)

func door_at(at: Vector3,width: float=1.10,height: float=2.1,angle: float=0) -> void:
	var f := facade(at,angle)
	arched_fill(f,Vector3(0,0,0.04),width+0.15,height+0.12,mats.recess)
	arched_fill(f,Vector3(0,0,0.08),width,height,mats.wood)
	arch(f,Vector3(0,0,0.17),width,height,mats.stone,0.17)
	var r := width/2
	for i in range(1,8):
		var x := -r+i*width/8
		var h := height-r+sqrt(maxf(0,r*r-x*x))
		box(f,Vector3(x,h/2,0.10),Vector3(0.015,h,0.018),mats.wood_dark)
	for y in [0.37,1.45]:
		box(f,Vector3(-width*0.24,y,0.13),Vector3(width*0.40,0.075,0.055),mats.iron)
		for x in [-width*0.40,-width*0.1]: cylinder(f,Vector3(x,y,0.165),0.025,0.028,mats.gold).rotation.x=PI/2
	var ring := TorusMesh.new()
	ring.inner_radius=0.055
	ring.outer_radius=0.085
	mesh(f,ring,Vector3(width*0.25,0.98,0.20),mats.gold,"DoorRing").rotation.x=PI/2
	box(f,Vector3(0,-0.04,0.18),Vector3(width+0.4,0.10,0.52),mats.stone,"Threshold")

func flower_box(parent: Node3D,at: Vector3,width: float) -> void:
	box(parent,at,Vector3(width,0.22,0.3),mats.wood,"WindowBox")
	box(parent,at+Vector3(0,0.13,0),Vector3(width-0.08,0.05,0.23),mats.soil)
	for i in range(ceili(width*8)):
		var p := at+Vector3(-width*0.44+width*0.88*i/maxf(1,ceili(width*8)-1),0.21+sin(i*2.8)*0.04,cos(i*1.7)*0.09)
		var s := SphereMesh.new()
		s.radius=0.12
		s.height=0.18
		s.radial_segments=8
		s.rings=4
		mesh(parent,s,p,mats.leaf)
		var blossom := SphereMesh.new()
		blossom.radius=0.052
		blossom.height=0.07
		blossom.radial_segments=8
		blossom.rings=4
		mesh(parent,blossom,p+Vector3(0.03,0.10,0.06),mats.flower if i%3 else mats.cream)

func roof(parent: Node3D,center: Vector3,width: float,depth: float,rise: float,hipped: bool=true) -> void:
	var g := group("SlateRoof",parent)
	g.position = center
	var hw := width/2
	var hd := depth/2
	var hip := minf(hd,hw*0.7) if hipped else 0.0
	# Dark continuous sheathing remains visible only in narrow tile seams.
	for side in [-1,1]:
		polygon(g,PackedVector3Array([Vector3(-hw,0,side*hd),Vector3(hw,0,side*hd),Vector3(hw-hip,rise,0),Vector3(-hw+hip,rise,0)]),mats.roof_dark)
		beam(g,Vector3(-hw,0,side*hd),Vector3(hw,0,side*hd),0.17,mats.wood)
		beam(g,Vector3(-hw,0.10,side*hd),Vector3(hw,0.10,side*hd),0.09,mats.slate_edge)
	if hipped:
		for side in [-1,1]:
			polygon(g,PackedVector3Array([Vector3(side*hw,0,-hd),Vector3(side*hw,0,hd),Vector3(side*(hw-hip),rise,0)]),mats.roof_dark)
	else:
		for side in [-1,1]:
			polygon(g,PackedVector3Array([Vector3(side*(hw-0.18),0,-hd+0.18),Vector3(side*(hw-0.18),0,hd-0.18),Vector3(side*(hw-0.18),rise-0.1,0)]),mats.plaster)
			for z in [-hd,hd]: beam(g,Vector3(side*hw,0,z),Vector3(side*hw,rise,0),0.14,mats.wood)
	# Individual courses have true planar geometry and deterministic colour.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := ceili(Vector2(hd,rise).length()/0.34)
	for side in [-1,1]:
		for row in range(rows):
			var t0 := float(row)/rows
			var t1 := minf(1.0,float(row+1)/rows-0.012)
			var lo := hw-hip*t0
			var hi := hw-hip*t1
			for column in range(-ceili(hw/0.34)-1,ceili(hw/0.34)+1):
				var x0 := column*0.34+(row%2)*0.17
				var x1 := x0+0.32
				if x1<=-lo or x0>=lo: continue
				var q := [Vector3(clampf(x0,-lo,lo),rise*t0+0.045,side*hd*(1-t0)),Vector3(clampf(x1,-lo,lo),rise*t0+0.045,side*hd*(1-t0)),Vector3(clampf(x1,-hi,hi),rise*t1+0.045,side*hd*(1-t1)),Vector3(clampf(x0,-hi,hi),rise*t1+0.045,side*hd*(1-t1))]
				tile_quad(st,q,row,column)
	if hipped:
		for side in [-1,1]:
			for row in range(rows):
				var t0 := float(row)/rows
				var t1 := minf(1.0,float(row+1)/rows-0.012)
				var lo := hd*(1-t0)
				var hi := hd*(1-t1)
				for col in range(-ceili(hd/0.34)-1,ceili(hd/0.34)+1):
					var z0 := col*0.34+(row%2)*0.17
					var z1 := z0+0.32
					if z1<=-lo or z0>=lo: continue
					var q := [Vector3(side*(hw-hip*t0),rise*t0+0.045,clampf(z0,-lo,lo)),Vector3(side*(hw-hip*t0),rise*t0+0.045,clampf(z1,-lo,lo)),Vector3(side*(hw-hip*t1),rise*t1+0.045,clampf(z1,-hi,hi)),Vector3(side*(hw-hip*t1),rise*t1+0.045,clampf(z0,-hi,hi))]
					tile_quad(st,q,row,col)
	st.generate_normals()
	mesh(g,st.commit(),Vector3.ZERO,mats.slate,"IndividualSlateCourses")
	ridge(g,Vector3(-hw+hip,rise+0.06,0),Vector3(hw-hip,rise+0.06,0))
	if hipped:
		for x in [-1,1]:
			for z in [-1,1]: ridge(g,Vector3(x*hw,0.09,z*hd),Vector3(x*(hw-hip),rise+0.08,0))

func ridge(parent: Node3D,a: Vector3,b: Vector3) -> void:
	if a.distance_to(b)<0.02: return
	var direction := (b-a).normalized()
	var across := direction.cross(Vector3.UP).normalized()
	if across.length_squared()<0.1: across=Vector3.RIGHT
	var count := ceili(a.distance_to(b)/0.26)
	for i in range(count):
		var n := cylinder(parent,a.lerp(b,(i+0.5)/count),a.distance_to(b)/count+0.012,0.078,mats.slate_edge,-1,8)
		n.basis=Basis(across,direction,across.cross(direction)).orthonormalized()

func tile_quad(st: SurfaceTool,q: Array,row: int,col: int) -> void:
	# Hand-laid courses: slight edge wear and seating differences, not a
	# displaced roof grid. The supporting planes and ridge stay perfectly true.
	var seed_value := sin(row*63.17+col*17.73)
	var tone := 0.73+float(posmod(row*23+col*17+col*col,19))*0.015
	if posmod(row*37+col*19,43)==0: tone=0.66
	for i in range(4):
		q[i].y+=seed_value*0.013+sin(col*8.1+row*5.3+i*2.1)*0.007
	if posmod(row*11+col*7,19)==0:
		q[0]=q[0].lerp(q[1],0.07) # a few small chipped lower corners
	var pieces := 5 if roof_finish=="clay" else 1
	for segment in range(pieces):
		var s0 := float(segment)/pieces
		var s1 := float(segment+1)/pieces
		var top: Array = [q[0].lerp(q[1],s0),q[0].lerp(q[1],s1),q[3].lerp(q[2],s1),q[3].lerp(q[2],s0)]
		for i in range(4):
			var s := s0 if i in [0,3] else s1
			top[i].y+=sin(s*PI)*0.026 if roof_finish=="clay" else 0.007
			if i<2: top[i].y+=0.028 # proud lower edge casts a real course shadow
		var indices := [0,1,2,0,2,3] if (top[1]-top[0]).cross(top[2]-top[0]).y>=0 else [0,2,1,0,3,2]
		for i in indices:
			st.set_color(Color(tone,tone,tone))
			st.set_uv(Vector2(top[i].x,top[i].z)*0.5)
			st.add_vertex(top[i])
		# Close the exposed lower tile edge. Curved tiles are solid pieces,
		# never floating sheets with the roof underlay showing through.
		var face: Array = [q[0].lerp(q[1],s0),q[0].lerp(q[1],s1),top[1],top[0]]
		for i in [0,1,2,0,2,3]:
			st.set_color(Color(tone*0.91,tone*0.91,tone*0.91))
			st.set_uv(Vector2(face[i].x,face[i].z)*0.5)
			st.add_vertex(face[i])

func chimney(at: Vector3,height: float=1.5) -> void:
	var g := group("Chimney",groups.roof)
	for row in range(ceili(height/0.23)):
		var y := at.y+row*0.23
		box(g,Vector3(at.x,y+0.11,at.z),Vector3(0.59,0.215,0.64),mats.stone if row%3 else mats.stone_shadow)
	box(g,at+Vector3(0,height,0),Vector3(0.75,0.16,0.80),mats.stone)
	box(g,at+Vector3(0,height+0.09,0),Vector3(0.49,0.035,0.54),mats.recess)
	for x in [-0.15,0.15]: cylinder(g,at+Vector3(x,height+0.3,0),0.45,0.115,mats.terracotta)

func canopy(parent: Node3D,at: Vector3,width: float,depth: float,color: Material) -> void:
	var g := group("StripedCanopy",parent)
	g.position=at
	var count := ceili(width/0.30)
	for i in range(count):
		var x0 := -width/2+width*i/count
		var x1 := -width/2+width*(i+1)/count
		var m: Material = mats.fabric if i%2 else color
		polygon(g,PackedVector3Array([Vector3(x0,0,0),Vector3(x1,0,0),Vector3(x1,-0.35,depth),Vector3(x0,-0.35,depth)]),m)
		var points := PackedVector3Array([Vector3(x0,-0.35,depth),Vector3(x1,-0.35,depth)])
		for j in range(9):
			var t := j/8.0
			points.append(Vector3(lerpf(x1,x0,t),-0.35-0.18*sin(t*PI),depth))
		polygon(g,points,m)
	for side in [-1,1]:
		beam(g,Vector3(side*width/2,-0.4,0),Vector3(side*width/2,-0.4,depth),0.055,mats.iron)

func barrel(parent: Node3D,at: Vector3,height: float=0.7) -> void:
	var g := group("OakBarrel",parent)
	g.position=at
	cylinder(g,Vector3(0,height/2,0),height,height*0.34,mats.wood,-1,12)
	for y in [0.12,height-0.12]: cylinder(g,Vector3(0,y,0),0.065,height*0.35,mats.iron,-1,12)
	cylinder(g,Vector3(0,height+0.005,0),0.018,height*0.32,mats.wood_dark,-1,12)

func lantern(at: Vector3,angle: float=0) -> void:
	var f := facade(at,angle)
	beam(f,Vector3(0,0,0),Vector3(0,0,0.4),0.045,mats.iron)
	box(f,Vector3(0,-0.22,0.38),Vector3(0.20,0.30,0.18),mats.lamp)
	for x in [-0.11,0.11]: box(f,Vector3(x,-0.22,0.48),Vector3(0.025,0.32,0.025),mats.iron)
	cylinder(f,Vector3(0,-0.01,0.38),0.16,0.20,mats.iron,0.02,4)
	box(f,Vector3(0,-0.39,0.38),Vector3(0.25,0.05,0.24),mats.iron)

func clock_face(at: Vector3,angle: float=0) -> void:
	var f := facade(at,angle)
	var c := CylinderMesh.new()
	c.height=0.07
	c.top_radius=0.60
	c.bottom_radius=0.60
	c.radial_segments=48
	mesh(f,c,Vector3.ZERO,mats.cream).rotation.x=PI/2
	var ring := TorusMesh.new()
	ring.inner_radius=0.60
	ring.outer_radius=0.67
	mesh(f,ring,Vector3(0,0,0.05),mats.gold).rotation.x=PI/2
	for i in range(12):
		var a := i*TAU/12
		var n := box(f,Vector3(sin(a)*0.49,cos(a)*0.49,0.06),Vector3(0.032,0.1,0.02),mats.iron)
		n.rotation.z=-a
	beam(f,Vector3(0,0,0.08),Vector3(-0.25,0.19,0.08),0.043,mats.iron)
	beam(f,Vector3(0,0,0.09),Vector3(0.20,0.36,0.09),0.035,mats.iron)

func build(asset_kind: String) -> void:
	kind=VARIANTS[asset_kind].model if VARIANTS.has(asset_kind) else asset_kind
	name=asset_kind.to_pascal_case()
	var spec: Dictionary = SPECS[kind]
	lot=spec.lot
	set_meta("asset_id",asset_kind)
	set_meta("ground_size",lot*32.0)
	set_meta("ground_corner",Vector3(lot.x/2,0,lot.y/2))
	set_meta("door_ground",Vector3(0,0,lot.y/2))
	mats={"plaster":material("ffffff","plaster",0.23),"wood":material("ffffff","wood",0.8),"wood_dark":material("45382e"),"stone":material("d9d3bd"),"stone_shadow":material("b5b4a5"),"cream":material("f1e7cb"),"recess":material("283438"),"glass":material("4e7e89"),"blue":material("466b91"),"blue_dark":material("294059"),"iron":material("354047"),"gold":material("c3a04d"),"roof_dark":material("293c50"),"slate_edge":material("607993"),"slate":material("ffffff","slate"),"leaf":material("4b8e4d"),"flower":material("d97571"),"soil":material("4a4031"),"terracotta":material("a46547"),"fabric":material("e8ddbc"),"green":material("638967"),"red":material("a24e4b"),"lamp":material("f4d894")}
	var roof_tone: String = VARIANTS[asset_kind].roof if VARIANTS.has(asset_kind) else DEFAULT_ROOFS[kind]
	roof_finish=roof_tone
	var painted := ShaderMaterial.new()
	painted.shader=load("res://game/whispering_forest/art/city/painted_slate.gdshader")
	painted.set_shader_parameter("paint",load("res://game/whispering_forest/art/city/materials/slate.png"))
	painted.set_shader_parameter("roof_color",Color(ROOF_COLORS[roof_tone]))
	mats.slate=painted
	mats.roof_dark.albedo_color=Color(ROOF_COLORS[roof_tone]).darkened(0.25)
	mats.slate_edge.albedo_color=Color(ROOF_COLORS[roof_tone]).lightened(0.18)
	for stone_material in [mats.stone,mats.stone_shadow]:
		stone_material.vertex_color_use_as_albedo=true
		stone_material.albedo_texture=load("res://game/whispering_forest/assets/city-v2/masonry.png")
		stone_material.uv1_triplanar=true
		stone_material.uv1_scale=Vector3.ONE*0.17
	for label in ["foundation","walls","roof","facades","dressing"]: groups[label]=group(label.to_pascal_case())
	var w := lot.x-0.40
	var d := lot.y-1.10
	# Reserved space belongs to the same parcel: the apothecary has a side
	# stair, and the inn a lower rear wing. These are real changes of massing.
	var body_offset := Vector3.ZERO
	if kind=="apothecary":
		w-=1.20
		body_offset.x=0.60
	if kind=="inn":
		d-=0.95
		body_offset.z=0.475
	set_meta("body_width",w)
	set_meta("body_depth",d)
	set_meta("body_offset",body_offset)
	set_meta("door_ground",Vector3(body_offset.x,0,lot.y/2))
	var front := d/2-0.30
	var h: float = spec.floors*preload("res://game/whispering_forest/art/city/render_config.gd").DATA.storey_metres
	set_meta("height",h+6.45 if kind=="guild" else h+float(spec.roof)+0.8)
	# A whole, accurate rectangular parcel supports every protruding doorstep.
	box(groups.foundation,Vector3(0,0.055,0),Vector3(lot.x,0.11,lot.y),mats.stone_shadow,"FoundationFootprint")
	box(groups.foundation,Vector3(0,0.16,-0.30),Vector3(w+0.12,0.21,d+0.12),mats.stone,"RaisedPlinth")
	box(groups.walls,Vector3(0,(h+0.25)/2,-0.30),Vector3(w,h-0.25,d),mats.plaster,"PlasteredWalls")
	for y in [0.32,h-0.10]: box(groups.walls,Vector3(0,y,-0.30),Vector3(w+0.14,0.18,d+0.14),mats.stone,"StoneBelt")
	for side in [-1,1]:
		for z in [-d/2-0.30,front]:
			for row in range(ceili((h-0.4)/0.35)):
				box(groups.walls,Vector3(side*(w/2-0.06),0.54+row*0.35,z),Vector3(0.28 if row%2 else 0.39,0.31,0.29),mats.stone,"CornerQuoin_%d" % serial)
	for level in range(1,spec.floors):
		box(groups.walls,Vector3(0,0.2+h*level/spec.floors,-0.30),Vector3(w+0.12,0.18,d+0.12),mats.wood,"FloorBeam")
	roof(groups.roof,Vector3(0,h,-0.30),w+0.55,d+0.55,spec.roof,kind in ["guild","pet_lodge"])
	# Main entry uses the shared human/door scale.
	door_at(Vector3(0,0.27,front+0.045),1.05 if w<3 else 1.2,2.35)
	for i in range(3):
		box(groups.foundation,Vector3(0,0.055+i*0.07,front+0.63-i*0.16),Vector3(1.6,0.11+i*0.14,0.26),mats.stone,"EntryStep")
	var xs: Array = [-w*0.31,w*0.31] if w>3.5 else []
	for x in xs:
		if kind in ["baker_house","apothecary"]:
			window_at(Vector3(x,0.86,front+0.03),1.27 if kind=="baker_house" else 0.94,1.43,0,false)
		elif kind!="forge":
			window_at(Vector3(x,1.05,front+0.02),0.76,1.20,0,true,kind=="garden_house")
	if spec.floors>1:
		for i in range(maxi(2,int(w/1.6))):
			var x := lerpf(-w*0.34,w*0.34,float(i)/maxi(1,maxi(2,int(w/1.6))-1))
			window_at(Vector3(x,h-2.42,front+0.03),0.80,1.50,0,true,kind in ["inn","apothecary","townhouse","baker_house"])
	var side_count := maxi(1,int(d/1.7))
	for i in range(side_count):
		var z := -0.3+lerpf(-d*0.3,d*0.3,float(i)/maxi(1,side_count-1))
		for floor_index in range(spec.floors):
			window_at(Vector3(w/2+0.015,1.05+floor_index*(h/2),z),0.72,1.08,PI/2,true,kind=="inn" and floor_index==1)
			if kind!="apothecary":
				window_at(Vector3(-w/2-0.015,1.05+floor_index*(h/2),z),0.72,1.08,-PI/2,true,false)
	# The same model has inhabited rear and side facades for every direction.
	for floor_index in range(spec.floors):
		for x in [-w*0.28,w*0.28]:
			window_at(Vector3(x,1.05+floor_index*(h/2),-d/2-0.315),0.62,1.08,PI,w>3.0,false)
	chimney(Vector3(-w*0.33,h+spec.roof*0.5,-d*0.25-0.3),1.0 if kind!="forge" else 2.5)
	lantern(Vector3(-0.95 if w>3 else -0.75,2.3,front+0.03))
	if kind=="guild": guild_details(w,d,h,front)
	elif kind=="forge": forge_details(w,front)
	elif kind=="apothecary": apothecary_details(w,h,front)
	elif kind=="inn": inn_details(w,h,front)
	elif kind=="market_hall": market_details(w,front)
	elif kind=="pet_lodge": lodge_details(w,front)
	elif kind=="garden_house": garden_details(w,front)
	elif kind=="townhouse": townhouse_details(w,h,front)
	elif kind=="baker_house": bakery_details(w,front)
	if kind in ["garden_house","baker_house","inn","pet_lodge"]:
		dormer(Vector3(0,h+0.27,front-0.18))
	weathering(w,d,front,h)
	inhabited_facades(w,d,h,front)
	for label in groups:
		if label!="foundation": groups[label].position+=body_offset
	# Shift foundation's raised plinth/steps, retaining the true parcel slab.
	for child in groups.foundation.get_children():
		if child.name!="FoundationFootprint": child.position+=body_offset
	if kind=="apothecary": exterior_stair(w,d,body_offset)
	if kind=="inn": lower_inn_wing(w)
	# An editable hierarchy is packed into each generated source scene.
	assign_owner(self)

func inhabited_facades(w: float,d: float,h: float,front: float) -> void:
	# Aged patchwork exposes small areas of the masonry underneath the plaster.
	var brick := material("a68570")
	var old_mortar := material("aaa691")
	for side in range(4):
		var g := group("RepairedPlaster",groups.dressing)
		g.position=Vector3(0,0,-0.30)
		g.rotation.y=side*PI/2
		var width := w if side%2==0 else d
		var depth := d if side%2==0 else w
		var x := width*0.34*(1 if side%2 else -1)
		for row in range(3):
			for column in range(3-row):
				box(g,Vector3(x+(column-1)*0.23+(row%2)*0.10,0.47+row*0.15,depth/2+0.015),Vector3(0.215,0.125,0.032),brick)
		# Short cracks start at a patch edge, rather than covering every wall.
		beam(g,Vector3(x+0.15,0.90,depth/2+0.022),Vector3(x+0.22,1.12,depth/2+0.022),0.012,old_mortar)
		if h>5:
			for xpost in [-width*0.43,0.0,width*0.43]:
				box(g,Vector3(xpost,h-1.50,depth/2+0.04),Vector3(0.12,2.90,0.14),mats.wood)
	# Drainage is anchored to the wall and terminates above the foundation.
	var pipe := group("RainwaterPipe",groups.dressing)
	var pipe_x := w/2-0.18
	cylinder(pipe,Vector3(pipe_x,h*0.47,front+0.19),h*0.90,0.043,mats.iron,-1,8)
	for y in [0.55,h*0.45,h-0.65]:
		box(pipe,Vector3(pipe_x,y,front+0.18),Vector3(0.13,0.05,0.17),mats.iron)
	if kind=="garden_house":
		var shed := group("FirewoodLeanTo",groups.dressing)
		var z := -d/2-0.54
		for side in [-1,1]: box(shed,Vector3(side*0.78,0.85,z),Vector3(0.10,1.65,0.10),mats.wood)
		polygon(shed,PackedVector3Array([Vector3(-0.94,1.95,z+0.28),Vector3(0.94,1.95,z+0.28),Vector3(0.94,1.67,z-0.20),Vector3(-0.94,1.67,z-0.20)]),mats.slate)
		for row in range(4):
			for i in range(6-row%2):
				var log_piece := cylinder(shed,Vector3(-0.68+i*0.25+(row%2)*0.11,0.30+row*0.24,z),0.44,0.115,mats.wood,-1,9)
				log_piece.rotation.x=PI/2

func exterior_stair(w: float,d: float,offset: Vector3) -> void:
	var g := group("ApothecaryExteriorStair")
	var x := offset.x-w/2-0.57
	var front := d/2-0.30
	for i in range(16):
		var height := 0.27+(i+1)*0.205
		box(g,Vector3(x,height/2,front-i*0.20),Vector3(0.94,height,0.215),mats.stone)
		box(g,Vector3(x,height,front-i*0.20+0.025),Vector3(0.98,0.035,0.23),mats.cream)
	box(g,Vector3(x,3.51,front-3.21),Vector3(0.99,0.16,0.51),mats.stone)
	for i in range(0,16,3):
		var y := 0.27+(i+1)*0.205
		box(g,Vector3(x-0.44,y+0.40,front-i*0.20),Vector3(0.075,0.88,0.075),mats.wood)
	beam(g,Vector3(x-0.44,1.27,front+0.10),Vector3(x-0.44,4.38,front-3.01),0.09,mats.wood)
	# Facade group was translated above; supply coordinates in its local space.
	door_at(Vector3(-w/2-0.03,3.59,front-3.13),0.78,2.02,-PI/2)

func lower_inn_wing(w: float) -> void:
	var g := group("InnLowRearWing")
	var z := -lot.y/2+0.70
	box(g,Vector3(w*0.24,1.81,z),Vector3(w*0.52,3.1,1.15),mats.plaster)
	roof(g,Vector3(w*0.24,3.42,z),w*0.52+0.32,1.53,0.66,false)
	for side in [-1,1]: box(g,Vector3(w*0.24+side*w*0.25,1.78,z-0.58),Vector3(0.14,3.0,0.14),mats.wood)
	window_at(Vector3(w*0.24,1.02,z-0.59-0.475),0.86,1.26,PI,true,true)

func weathering(w: float,d: float,front: float,h: float) -> void:
	var patina := material("777565")
	patina.albedo_color.a=0.19
	patina.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	for side in [0,1,2,3]:
		var face_node := group("WallFootWeathering",groups.dressing)
		face_node.position=Vector3(0,0,-0.3)
		face_node.rotation.y=side*PI/2
		var span := w if side%2==0 else d
		var depth := d if side%2==0 else w
		var points := PackedVector3Array([Vector3(-span/2,0.3,depth/2+0.025),Vector3(span/2,0.3,depth/2+0.025)])
		for i in range(12,-1,-1):
			var x := -span/2+span*i/12
			points.append(Vector3(x,0.47+0.12*sin(i*2.15+side),depth/2+0.025))
		polygon(face_node,points,patina)
	# Short, localized runoff beneath the roof edge, not a whole-image filter.
	for i in range(maxi(2,int(w))):
		var x := -w*0.42+i*w*0.84/maxi(1,int(w)-1)
		polygon(groups.dressing,PackedVector3Array([Vector3(x,h-0.18,front+0.025),Vector3(x+0.05,h-0.18,front+0.025),Vector3(x+0.025,h-0.5-0.13*sin(i*2.3),front+0.025)]),patina)

func dormer(at: Vector3) -> void:
	var g := group("RoofDormer",groups.roof)
	g.position=at
	box(g,Vector3(0,0.45,-0.23),Vector3(1.0,0.9,0.95),mats.plaster)
	window_at(at+Vector3(0,0.13,0.26),0.48,0.61,0,false)
	var top := group("DormerGable",g)
	top.position=Vector3(0,0.93,-0.23)
	top.rotation.y=PI/2
	roof(top,Vector3.ZERO,1.3,1.25,0.58,false)

func assign_owner(parent: Node) -> void:
	for child in parent.get_children():
		child.owner=self
		assign_owner(child)

func guild_details(w: float,d: float,h: float,front: float) -> void:
	var tower := group("CivicClockTower",groups.walls)
	var tw := 2.25
	box(tower,Vector3(0,h+1.4,-0.45),Vector3(tw,3.0,2.05),mats.stone)
	for y in [h+0.05,h+2.0,h+2.9]: box(tower,Vector3(0,y,-0.45),Vector3(tw+0.20,0.16,2.25),mats.cream)
	clock_face(Vector3(0,h+2.05,0.62))
	clock_face(Vector3(tw/2+0.04,h+2.05,-0.45),PI/2)
	for x in [-0.9,0.9]:
		for z in [-1.27,0.37]: cylinder(tower,Vector3(x,h+3.5,z),1.0,0.12,mats.stone)
	var bell := cylinder(tower,Vector3(0,h+3.3,-0.45),0.7,0.45,mats.gold,0.20)
	bell.name="BronzeBell"
	roof(groups.roof,Vector3(0,h+4.1,-0.45),2.7,2.55,1.65)
	cylinder(tower,Vector3(0,h+6.05,-0.45),0.8,0.035,mats.gold)
	polygon(tower,PackedVector3Array([Vector3(0,h+6.4,-0.45),Vector3(1.2,h+6.15,-0.45),Vector3(0,h+5.9,-0.45)]),mats.blue)
	for x in [-1.5,1.5]:
		box(groups.walls,Vector3(x,1.7,front+0.15),Vector3(0.28,2.8,0.38),mats.stone)
		box(groups.walls,Vector3(x,3.05,front+0.15),Vector3(0.45,0.22,0.55),mats.stone)
	var porch := group("GabledEntry",groups.roof)
	porch.position=Vector3(0,3.18,front+0.05)
	porch.rotation.y=PI/2
	roof(porch,Vector3.ZERO,1.5,3.65,0.95,false)
	for x in [-w*0.43,w*0.43]:
		polygon(groups.dressing,PackedVector3Array([Vector3(x-0.22,4.7,front+0.25),Vector3(x+0.22,4.7,front+0.25),Vector3(x+0.22,3.2,front+0.25),Vector3(x,2.95,front+0.25),Vector3(x-0.22,3.2,front+0.25)]),mats.blue)

func forge_details(w: float,front: float) -> void:
	var g := group("OutdoorForge",groups.dressing)
	var x := -w*0.28
	box(g,Vector3(x,0.55,front+0.22),Vector3(1.25,0.6,0.68),mats.stone_shadow)
	box(g,Vector3(x,1.05,front+0.22),Vector3(1.1,0.50,0.55),mats.recess)
	for side in [-1,1]: box(g,Vector3(x+side*0.60,1.16,front+0.25),Vector3(0.18,0.8,0.6),mats.stone)
	box(g,Vector3(x,1.61,front+0.25),Vector3(1.40,0.20,0.70),mats.stone)
	for i in range(9): cylinder(g,Vector3(x-0.42+i*0.105,0.92,front+0.55),0.16+0.2*absf(sin(i*2.5)),0.065,mats.lamp,0.005,6)
	var anvil_x := w*0.27
	cylinder(g,Vector3(anvil_x,0.57,front+0.38),0.60,0.28,mats.wood,-1,12)
	box(g,Vector3(anvil_x,0.98,front+0.38),Vector3(0.6,0.19,0.3),mats.iron)
	box(g,Vector3(anvil_x,0.80,front+0.38),Vector3(0.23,0.20,0.22),mats.iron)
	canopy(groups.dressing,Vector3(0,2.95,front),w-0.1,0.72,mats.blue_dark)

func apothecary_details(w: float,h: float,front: float) -> void:
	# A tiled shop hood and an attic replace the old decorative sphere.
	roof(groups.roof,Vector3(0,2.72,front+0.20),w+0.10,1.15,0.32,false)
	dormer(Vector3(-w*0.18,h+0.26,front-0.25))
	for side in [-1,1]:
		var f := facade(Vector3(side*w*0.30,0.49,front+0.46))
		flower_box(f,Vector3.ZERO,0.65)

func inn_details(w: float,h: float,front: float) -> void:
	var g := group("TimberBalcony",groups.dressing)
	box(g,Vector3(0,h*0.51,front+0.28),Vector3(w-0.1,0.17,0.72),mats.wood)
	for i in range(13): box(g,Vector3(-w/2+0.16+i*(w-0.32)/12,h*0.51+0.42,front+0.59),Vector3(0.065,0.72,0.065),mats.wood)
	box(g,Vector3(0,h*0.51+0.79,front+0.59),Vector3(w,0.09,0.10),mats.wood)
	for side in [-1,1]: beam(g,Vector3(side*w*0.33,1.95,front),Vector3(side*w*0.33,h*0.51,front+0.6),0.11,mats.wood)
	barrel(g,Vector3(w/2-0.4,0.12,front+0.42))

func market_details(w: float,front: float) -> void:
	canopy(groups.dressing,Vector3(0,2.60,front),w+0.02,0.72,mats.green)
	for side in [-1,1]:
		var x: float = side*w*0.31
		box(groups.dressing,Vector3(x,0.68,front+0.42),Vector3(w*0.30,0.90,0.46),mats.wood)
		for i in range(12):
			var s := SphereMesh.new()
			s.radius=0.1
			s.height=0.17
			s.radial_segments=8
			s.rings=5
			mesh(groups.dressing,s,Vector3(x+(i%6-2.5)*0.19,1.21,front+0.30+(i/6)*0.21),mats.red if side==1 else mats.leaf)

func lodge_details(w: float,front: float) -> void:
	for x in [-w*0.38,w*0.38]:
		box(groups.dressing,Vector3(x,1.55,front+0.46),Vector3(0.15,2.55,0.15),mats.wood)
	canopy(groups.dressing,Vector3(0,2.95,front),w+0.05,0.75,mats.blue)
	barrel(groups.dressing,Vector3(w*0.31,0.12,front+0.43),0.6)
	var pet := group("CompanionEmblem",groups.dressing)
	pet.position=Vector3(0,2.72,front+0.08)
	var medallion := CylinderMesh.new()
	medallion.height=0.08
	medallion.top_radius=0.32
	medallion.bottom_radius=0.32
	mesh(pet,medallion,Vector3.ZERO,mats.wood).rotation.x=PI/2
	for at in [Vector2(0,-0.05),Vector2(-0.16,0.12),Vector2(0,0.19),Vector2(0.16,0.12)]:
		var s := SphereMesh.new()
		s.radius=0.10 if at.y<0 else 0.065
		s.height=s.radius*2
		mesh(pet,s,Vector3(at.x,at.y,0.08),mats.cream)

func garden_details(w: float,front: float) -> void:
	var g := group("DoorPergola",groups.dressing)
	for side in [-1,1]:
		box(g,Vector3(side*0.92,1.37,front+0.43),Vector3(0.13,2.45,0.13),mats.wood)
	for i in range(6): box(g,Vector3(-1.02+i*0.408,2.61,front+0.29),Vector3(0.09,0.12,0.85),mats.wood)
	box(g,Vector3(0,2.53,front+0.64),Vector3(2.25,0.14,0.14),mats.wood)
	flower_box(g,Vector3(w*0.34,0.25,front+0.42),0.70)

func townhouse_details(w: float,h: float,front: float) -> void:
	box(groups.walls,Vector3(0,h/2,front+0.09),Vector3(0.15,h,0.12),mats.wood,"PartyWallTimber")
	for x in [-w*0.25,w*0.25]:
		var g := group("FrontGable",groups.roof)
		g.position=Vector3(x,h-0.08,front-0.38)
		g.rotation.y=PI/2
		roof(g,Vector3.ZERO,1.6,w*0.50,1.25,false)

func bakery_details(w: float,front: float) -> void:
	canopy(groups.dressing,Vector3(0,2.45,front),w+0.13,0.73,mats.red)
	var side := facade(Vector3(w/2+0.04,1.0,-0.8),PI/2)
	box(side,Vector3(0,0.05,0.25),Vector3(2.2,0.9,0.45),mats.wood,"BreadCounter")
	for i in range(7):
		var s := SphereMesh.new()
		s.radius=0.12
		s.height=0.48
		s.radial_segments=10
		s.rings=6
		var n := mesh(side,s,Vector3(-0.8+i*0.26,0.60,0.31),mats.fabric)
		n.rotation.z=0.5
