extends "res://game/whispering_forest/art/city/building_model.gd"

const KINDS := ["linden","linden_young","linden_lean","birch","spruce","cypress","garden_tree","waystone"]
const TREE_SPECS := {
	"linden":{"height":4.6,"tone":"76ad7e","seed":7021},
	"linden_young":{"height":3.55,"tone":"88b880","seed":7427},
	"linden_lean":{"height":4.8,"tone":"69a185","seed":9113},
	"birch":{"height":4.55,"tone":"a2bdaa","seed":4219},
	"spruce":{"height":5.25,"tone":"66978c","seed":3137},
	"cypress":{"height":5.25,"tone":"729e83","seed":6103},
	"garden_tree":{"height":3.6,"tone":"8aae77","seed":1999}
}
var random := RandomNumberGenerator.new()

func build(asset_kind: String) -> void:
	kind=asset_kind
	name=kind.to_pascal_case()
	set_meta("asset_id",kind)
	set_meta("ground_size",Vector2.ZERO)
	set_meta("ground_corner",Vector3.ZERO)
	set_meta("door_ground",Vector3.ZERO)
	set_meta("height",2.28 if kind=="waystone" else TREE_SPECS[kind].height)
	mats={"wood":material("b6a387","wood",0.8),"leaf":material("76af72"),"stone":material("deded0"),"gold":material("b79852"),"blue":material("529eae"),"iron":material("526a77")}
	if kind=="waystone":
		waystone()
	else:
		var spec: Dictionary = TREE_SPECS[kind]
		random.seed=spec.seed
		var foliage_paint := ShaderMaterial.new()
		foliage_paint.shader=load("res://game/whispering_forest/art/city/painted_foliage.gdshader")
		foliage_paint.set_shader_parameter("paint",load("res://game/whispering_forest/art/city/materials/foliage.png"))
		foliage_paint.set_shader_parameter("leaf_color",Color(spec.tone))
		mats.leaf=foliage_paint
		if kind=="birch": mats.wood=material("c1c7ba","wood",0.65)
		var trunk := group("TrunkAndBranches")
		var crown := SurfaceTool.new()
		crown.begin(Mesh.PRIMITIVE_TRIANGLES)
		var h: float = spec.height
		var lean := Vector3(0.34,0,-0.18) if kind=="linden_lean" else Vector3(-0.06,0,0.08)
		beam(trunk,Vector3.ZERO,Vector3(0,h*0.58,0)+lean,0.21 if kind!="birch" else 0.13,mats.wood)
		for i in range(5):
			var a := i*TAU/5
			beam(trunk,Vector3(cos(a)*0.29,0.03,sin(a)*0.29),Vector3(0,0.46,0),0.09,mats.wood)
		if kind=="cypress":
			for i in range(11):
				var radius := 0.50*pow(1.0-i/11.5,0.58)
				leaf_cluster(crown,Vector3(sin(i)*0.04,1.15+i*0.34,0),Vector3(radius,0.56,radius),70)
		elif kind=="spruce":
			beam(trunk,Vector3(0,1,0),Vector3(0,h-0.2,0),0.10,mats.wood)
			for tier in range(7):
				var y := 1.25+tier*0.49
				var radius := 1.03*(1.0-tier/8.0)
				for branch in range(5):
					var a := branch*TAU/5+tier*0.59
					var tip := Vector3(cos(a)*radius*0.55,y-0.12,sin(a)*radius*0.55)
					beam(trunk,Vector3(0,y+0.12,0),tip,0.045,mats.wood)
					leaf_cluster(crown,tip,Vector3(radius*0.56,0.36,radius*0.56),30)
			leaf_cluster(crown,Vector3(0,4.85,0),Vector3(0.20,0.40,0.20),35)
		else:
			var count := 9 if kind in ["birch","linden_young"] else 13
			var spread := 1.0 if kind in ["linden","linden_lean"] else 0.73
			if kind=="garden_tree": spread=1.04
			for i in range(count):
				var a := i*2.39996
				var radial := spread*sqrt(float(i%5)/4)*random.randf_range(0.76,1.08)
				var y := h*0.59+(float(i)/count)*h*0.19+random.randf_range(-0.1,0.16)
				if kind=="birch": y=h*0.53+float(i%3)*0.52
				var center := Vector3(cos(a)*radial,y,sin(a)*radial)+lean
				beam(trunk,Vector3(0,h*0.37,0)+lean*0.5,center,0.065,mats.wood)
				var radius := Vector3(0.48,0.62,0.49) if kind=="birch" else Vector3(0.76,0.46,0.68)
				if kind=="linden_young": radius*=0.82
				leaf_cluster(crown,center,radius*random.randf_range(0.88,1.10),65)
		crown.generate_normals()
		mesh(self,crown.commit(),Vector3.ZERO,mats.leaf,"CrownSilhouetteLeaves")
	assign_owner(self)

func leaf_cluster(st: SurfaceTool,center: Vector3,radius: Vector3,count: int) -> void:
	var core := SphereMesh.new()
	core.radius=1.0
	core.height=2.0
	core.radial_segments=16
	core.rings=10
	var arrays := core.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	var phase := random.randf()*TAU
	for i in range(vertices.size()):
		var v := vertices[i]
		var lump := sin(v.x*7.3+phase)*sin(v.y*5.2-v.z*6.1)
		vertices[i]*=0.93+lump*0.12+sin(v.z*13.0+phase)*0.035
		var tone := 0.88+0.09*sin(v.x*6.2+v.z*8.4+phase)+0.06*v.y
		colors.append(Color(tone,tone,tone))
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	var lobed := ArrayMesh.new()
	lobed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var crown := mesh(self,lobed,center,mats.leaf,"FoliageMass_%04d" % serial)
	crown.scale=radius*0.91
	crown.rotation.y=random.randf_range(-0.45,0.45)
	for i in range(count):
		var direction := Vector3(random.randf_range(-1,1),random.randf_range(-1,1),random.randf_range(-1,1)).normalized()
		var p := center+direction*radius*random.randf_range(0.88,1.06)
		var normal := (direction+Vector3.UP*0.8).normalized()
		var right := normal.cross(Vector3.FORWARD).normalized()
		if right.length_squared()<0.1: right=Vector3.RIGHT
		var up := right.cross(normal).normalized()
		var extent := random.randf_range(0.095,0.16)
		var points := [p+up*extent,p+right*extent*0.55,p-up*extent,p-right*extent*0.55]
		var tone := random.randf_range(0.72,1.04)
		for index in [0,1,2,0,2,3]:
			st.set_color(Color(tone*0.87,tone,tone*0.84))
			st.add_vertex(points[index])

func waystone() -> void:
	var base := group("CarvedWaystoneBase")
	for i in range(3): cylinder(base,Vector3(0,0.07+i*0.10,0),0.12,0.53-i*0.06,mats.stone,-1,8)
	cylinder(base,Vector3(0,0.53,0),0.54,0.31,mats.stone,0.26,8)
	cylinder(base,Vector3(0,0.85,0),0.12,0.37,mats.gold,-1,8)
	var crystal := group("AzureCrystal")
	for i in range(6):
		var a := i*TAU/6
		var b := (i+1)*TAU/6
		var r := 0.25
		var material_index := material("75bfd2" if i%2 else "388aa8")
		polygon(crystal,PackedVector3Array([Vector3(cos(a)*r,1.05,sin(a)*r),Vector3(cos(b)*r,1.05,sin(b)*r),Vector3(cos(b)*r,1.88,sin(b)*r),Vector3(cos(a)*r,1.88,sin(a)*r)]),material_index)
		polygon(crystal,PackedVector3Array([Vector3(cos(a)*r,1.88,sin(a)*r),Vector3(cos(b)*r,1.88,sin(b)*r),Vector3(0,2.28,0)]),material_index)
	var ring := TorusMesh.new()
	ring.inner_radius=0.38
	ring.outer_radius=0.41
	var orbit := mesh(self,ring,Vector3(0,1.4,0),mats.gold,"BronzeOrbit")
	orbit.rotation.z=0.35
