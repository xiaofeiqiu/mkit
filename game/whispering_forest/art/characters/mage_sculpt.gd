extends RefCounted

# Young anime-fantasy mage: editable mesh profiles on the shared animation rig.
# The live rig replaces the historical weapon builder with the upright long staff.
var r: Node3D
var mat: Dictionary = {}

func rebuild(rig: Node3D) -> void:
	r = rig
	remove_meshes(r)
	mat = {
		"skin": surface("efbd9d"), "skin_shadow":surface("b57266"),
		"hair":surface("252b42"), "hair_lit":surface("3b4863"),
		"hair_warm":surface("536580"), "ink":surface("202539"),
		"coat":fabric("315f76"), "coat_lit":fabric("51818d"),
		"navy":fabric("303f53"), "lining":fabric("9bafb1"),
		"cream":fabric("e4d7bd"), "gold":surface("bca16c",0.74,0.16),
		"gold_lit":surface("deca93",0.68,0.16),
		"leather":fabric("654d44",true), "sole":surface("30313a"),
		"sash":fabric("9a6159"), "white":surface("fff9e9"),
		"iris":surface("4c9aa9"), "iris_shadow":surface("245475"), "gem":surface("37b9d2",0.25,0.18),
		"gem_light":surface("b3f8ef",0.22,0.1), "wood":surface("293c50"),
	}
	body()
	legs()
	arms_and_hands()
	face()
	hair()
	wand(r.staff)
	wand(r.back_staff)
	r.staff.position = Vector3(0,0,0.050)
	r.staff.rotation = Vector3.ZERO
	r.back_staff.position = Vector3(0.32,0.05,-0.23)
	r.back_staff.rotation = Vector3(0.05,0,-0.18)

func surface(hex: String, roughness: float = 0.87, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = roughness
	m.metallic = metal
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func fabric(hex: String,leather: bool=false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader=load("res://game/whispering_forest/art/characters/painted_cloth.gdshader")
	material.set_shader_parameter("pigment",Color(hex))
	material.set_shader_parameter("leather",1.0 if leather else 0.0)
	return material

func remove_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			child.free()
		else: remove_meshes(child)

func finish(parent: Node3D, st: SurfaceTool, material: Material, label: String, make_normals: bool = true) -> MeshInstance3D:
	if make_normals:
		st.index()
		st.generate_normals()
	var result := MeshInstance3D.new()
	result.name = label
	result.mesh = st.commit()
	result.material_override = material
	parent.add_child(result)
	return result

func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tint: Color = Color.WHITE) -> void:
	for p in [a,b,c]:
		st.set_color(tint)
		st.add_vertex(p)

func shaded_triangle(st: SurfaceTool, positions: Array, normals: Array) -> void:
	# Godot uses clockwise front faces; keep the authored outward normals.
	for i in [0,2,1]:
		st.set_color(Color.WHITE)
		st.set_normal(normals[i])
		st.add_vertex(positions[i])

func section_normal(sections: Array, index: int, angle: float) -> Vector3:
	var lower: Array = sections[maxi(0,index-1)]
	var upper: Array = sections[mini(sections.size()-1,index+1)]
	var center: Array = sections[index]
	var height := maxf(0.001,float(upper[0])-float(lower[0]))
	var around := Vector3(cos(angle)*float(center[1]),0,-sin(angle)*float(center[2]))
	var up := Vector3(sin(angle)*(float(upper[1])-float(lower[1]))/height,1,(cos(angle)*(float(upper[2])-float(lower[2]))+float(upper[3])-float(lower[3]))/height)
	return around.cross(up).normalized()

# Elliptical sections [height, half-width, half-depth, forward offset].
# Wide shoulders, shaped waists, jaw/cheek planes and boot toes all have unique profiles.
func loft(parent: Node3D, sections: Array, material: Material, label: String, sides: int = 24) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for j in range(sections.size()-1):
		var low: Array = sections[j]
		var high: Array = sections[j+1]
		for i in range(sides):
			var a := TAU*i/sides
			var b := TAU*(i+1)/sides
			var p := Vector3(sin(a)*float(low[1]),low[0],cos(a)*float(low[2])+float(low[3]))
			var q := Vector3(sin(b)*float(low[1]),low[0],cos(b)*float(low[2])+float(low[3]))
			var u := Vector3(sin(a)*float(high[1]),high[0],cos(a)*float(high[2])+float(high[3]))
			var v := Vector3(sin(b)*float(high[1]),high[0],cos(b)*float(high[2])+float(high[3]))
			var np := section_normal(sections,j,a)
			var nq := section_normal(sections,j,b)
			var nu := section_normal(sections,j+1,a)
			var nv := section_normal(sections,j+1,b)
			shaded_triangle(st,[p,q,u],[np,nq,nu])
			shaded_triangle(st,[q,v,u],[nq,nv,nu])
	return finish(parent,st,material,label,false)

func tube(parent: Node3D, points: Array, widths: Array, depth: float, material: Material, label: String, sides: int = 10) -> MeshInstance3D:
	if points.size()<=8:
		var curved: Array = []
		var radii: Array = []
		for j in range(points.size()-1):
			for k in range(5):
				var phase := k/5.0
				curved.append(points[j].cubic_interpolate(points[j+1],points[maxi(0,j-1)],points[mini(points.size()-1,j+2)],phase))
				radii.append(lerpf(float(widths[j]),float(widths[j+1]),phase))
		curved.append(points.back()); radii.append(widths.back())
		points = curved; widths = radii
	var rings: Array = []
	var normals: Array = []
	for j in range(points.size()):
		var tangent: Vector3 = (points[mini(j+1,points.size()-1)]-points[maxi(0,j-1)]).normalized()
		var right := tangent.cross(Vector3(0,0,1)).normalized()
		if right.length_squared()<0.1: right = Vector3.RIGHT
		var normal := right.cross(tangent).normalized()
		var ring: Array[Vector3] = []
		var ring_normals: Array[Vector3] = []
		var j0 := maxi(0,j-1)
		var j1 := mini(points.size()-1,j+1)
		var slope := (float(widths[j1])-float(widths[j0]))/maxf(0.001,points[j1].distance_to(points[j0]))
		for i in range(sides):
			var a := TAU*i/sides
			ring.append(points[j]+right*cos(a)*float(widths[j])+normal*sin(a)*float(widths[j])*depth)
			ring_normals.append((right*cos(a)+normal*sin(a)/depth-tangent*slope).normalized())
		rings.append(ring)
		normals.append(ring_normals)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for j in range(rings.size()-1):
		for i in range(sides):
			var k := (i+1)%sides
			shaded_triangle(st,[rings[j][i],rings[j+1][i],rings[j][k]],[normals[j][i],normals[j+1][i],normals[j][k]])
			shaded_triangle(st,[rings[j][k],rings[j+1][i],rings[j+1][k]],[normals[j][k],normals[j+1][i],normals[j+1][k]])
	return finish(parent,st,material,label,false)

func patch(parent: Node3D, points: Array, material: Material, label: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()-1): triangle(st,points[0],points[i],points[i+1])
	return finish(parent,st,material,label)

func body() -> void:
	loft(r.hips,[[-0.14,0.21,0.15,0],[-0.05,0.27,0.18,0],[0.11,0.25,0.18,0],[0.19,0.23,0.16,0]],mat.navy,"TailoredTrousers")
	loft(r.chest,[[-0.015,0.225,0.16,0],[0.17,0.24,0.17,0],[0.38,0.30,0.185,0],[0.52,0.335,0.18,-0.01],[0.61,0.255,0.145,0],[0.65,0.13,0.11,0]],mat.coat,"FittedSplitCoat")
	# Cream inset and diagonally overlapping lapels; no rectangular shirt stripe.
	patch(r.chest,[Vector3(-0.095,0.56,0.166),Vector3(0.095,0.56,0.166),Vector3(0.08,0.09,0.185),Vector3(-0.065,0.06,0.184)],mat.cream,"LinenInset")
	for side in [-1.0,1.0]:
		patch(r.chest,[Vector3(side*0.12,0.62,0.15),Vector3(side*0.275,0.49,0.17),Vector3(side*0.065,0.25,0.196),Vector3(side*0.022,0.46,0.183)],mat.navy,"FoldedLapel")
		tube(r.chest,[Vector3(side*0.12,0.62,0.165),Vector3(side*0.21,0.48,0.19),Vector3(side*0.065,0.25,0.21)],[0.011,0.009,0.005],0.5,mat.gold,"LapelPiping")
	# Two coat panels are attached to the existing independently animated cloth pivots.
	for i in range(2):
		var side := -1.0 if i==0 else 1.0
		var tail: Node3D = r.coat_tails[i]
		patch(tail,[Vector3(-0.14,0.08,0.13),Vector3(0.14,0.08,0.13),Vector3(0.19,-0.44,0.08),Vector3(side*0.10,-0.57,-0.03),Vector3(-0.18,-0.43,-0.03)],mat.coat,"SplitCoatPanel")
		patch(tail,[Vector3(-0.14,0.06,-0.105),Vector3(0.14,0.06,-0.105),Vector3(0.19,-0.45,-0.09),Vector3(0,-0.57,-0.07),Vector3(-0.18,-0.43,-0.09)],mat.navy,"RearCoatPanel")
		tube(tail,[Vector3(-0.18,-0.43,-0.02),Vector3(side*0.10,-0.57,-0.02),Vector3(0.19,-0.44,0.09)],[0.013,0.013,0.013],0.5,mat.gold,"CoatHem")
	loft(r.hips,[[0.115,0.256,0.182,0],[0.165,0.256,0.182,0],[0.208,0.241,0.176,0]],mat.leather,"WaistBelt")
	r.box(r.hips,Vector3(0.02,0.164,0.194),Vector3(0.09,0.075,0.023),mat.gold)
	r.box(r.hips,Vector3(0.02,0.164,0.209),Vector3(0.044,0.039,0.014),mat.navy)
	# A small leather-bound spellbook makes the profession readable from the back/side.
	var book: Node3D = r.joint(r.hips,"Spellbook",Vector3(-0.30,-0.05,0.01))
	book.rotation = Vector3(-0.08,0.18,-0.16)
	r.box(book,Vector3.ZERO,Vector3(0.17,0.26,0.10),mat.leather)
	r.box(book,Vector3(0.012,0,0.06),Vector3(0.15,0.225,0.028),mat.cream)
	r.box(book,Vector3(0,0,0.08),Vector3(0.19,0.28,0.025),mat.navy)
	r.box(book,Vector3(0,0,0.098),Vector3(0.033,0.28,0.008),mat.gold)
	# A curved asymmetric shoulder mantle, including a visible lining.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i in range(20):
		var a := lerpf(-0.35,PI+0.9,i/20.0)
		var b := lerpf(-0.35,PI+0.9,(i+1)/20.0)
		var inner_a := Vector3(-sin(a)*0.17,0.68,-cos(a)*0.14)
		var inner_b := Vector3(-sin(b)*0.17,0.68,-cos(b)*0.14)
		var outer_a := Vector3(-sin(a)*0.435,0.34-0.13*maxf(0,sin(a)),-cos(a)*0.25)
		var outer_b := Vector3(-sin(b)*0.435,0.34-0.13*maxf(0,sin(b)),-cos(b)*0.25)
		triangle(st,inner_a,outer_a,inner_b)
		triangle(st,inner_b,outer_a,outer_b)
	finish(r.chest,st,mat.coat_lit,"AsymmetricShoulderMantle")
	r.oval(r.chest,Vector3(-0.155,0.58,0.185),Vector3(0.06,0.06,0.017),mat.gold)
	r.oval(r.chest,Vector3(-0.155,0.58,0.205),Vector3(0.034,0.038,0.014),mat.gem)
	loft(r.chest,[[0.61,0.13,0.105,0],[0.77,0.125,0.105,0]],mat.skin,"Neck")
	loft(r.chest,[[0.62,0.22,0.17,0],[0.69,0.235,0.17,0],[0.76,0.15,0.125,0]],mat.cream,"SoftCowlCollar")
	patch(r.scarf,[Vector3(-0.07,0,0),Vector3(0.10,0,0),Vector3(0.13,-0.22,-0.08),Vector3(0.02,-0.46,-0.10),Vector3(-0.08,-0.39,-0.10),Vector3(-0.05,-0.20,-0.05)],mat.cream,"TaperedScarf")

func legs() -> void:
	for i in range(2):
		loft(r.thighs[i],[[-0.43,0.088,0.092,0],[-0.24,0.10,0.115,0],[-0.02,0.135,0.13,0],[0.025,0.08,0.09,0]],mat.navy,"ShapedTrouserLeg")
		loft(r.knees[i],[[-0.425,0.085,0.075,0],[-0.32,0.092,0.089,0],[-0.13,0.109,0.115,0],[0.015,0.112,0.107,0]],mat.leather,"BootShaft")
		loft(r.knees[i],[[-0.075,0.117,0.119,0],[-0.045,0.124,0.12,0],[0.01,0.116,0.11,0]],mat.cream,"FoldedBootCuff")
		loft(r.ankles[i],[[0.005,0.10,0.20,0.08],[0.025,0.135,0.236,0.087],[0.060,0.13,0.223,0.085],[0.12,0.12,0.178,0.065],[0.19,0.085,0.080,0],[0.22,0.075,0.065,0]],mat.leather,"ShapedBootFoot")
		loft(r.ankles[i],[[0.002,0.115,0.215,0.082],[0.013,0.14,0.241,0.087],[0.037,0.14,0.237,0.087]],mat.sole,"BootSole")
		r.box(r.knees[i],Vector3(0,-0.18,0.116),Vector3(0.15,0.036,0.017),mat.gold)

func arms_and_hands() -> void:
	for i in range(2):
		loft(r.arms[i],[[-0.33,0.108,0.10,0],[-0.26,0.124,0.112,0],[-0.12,0.157,0.145,0],[0.025,0.123,0.123,0],[0.075,0.05,0.06,0]],mat.coat,"TailoredSleeve")
		loft(r.elbows[i],[[-0.24,0.09,0.073,0],[-0.18,0.096,0.082,0],[-0.02,0.115,0.103,0],[0.025,0.102,0.092,0]],mat.cream,"LinenUndersleeve")
		loft(r.elbows[i],[[-0.26,0.107,0.083,0],[-0.23,0.112,0.087,0],[-0.18,0.106,0.083,0]],mat.leather,"WristGuard")
		loft(r.elbows[i],[[-0.242,0.113,0.09,0],[-0.228,0.113,0.09,0]],mat.gold,"WristGuardTrim")
		var hand: Node3D = r.elbows[i].get_node("Hand")
		r.oval(hand,Vector3(-0.012,0,0),Vector3(0.077,0.098,0.051),mat.skin)
		for finger in range(4):
			var y := 0.056-finger*0.034
			var reach := 0.061 if i==1 else 0.046
			tube(hand,[Vector3(0.018,y,0.035),Vector3(reach,y-0.008,0.060),Vector3(0.018,y-0.012,0.084),Vector3(-0.027,y-0.016,0.073)],[0.020,0.020,0.019,0.013],0.95,mat.skin,"CurledFinger")
		tube(hand,[Vector3(-0.062,0.045,0.02),Vector3(-0.076,-0.005,0.075),Vector3(-0.022,-0.02,0.085)],[0.031,0.029,0.023],0.85,mat.skin,"OpposedThumb")

func face() -> void:
	loft(r.head,[[-0.35,0.045,0.075,0.078],[-0.30,0.175,0.185,0.04],[-0.19,0.31,0.275,0.018],[-0.06,0.38,0.315,0],[0.11,0.398,0.32,-0.01],[0.27,0.365,0.29,-0.025],[0.39,0.245,0.20,-0.04],[0.435,0.07,0.07,-0.04]],mat.skin,"SculptedJawCheeksAndForehead",32)
	r.brows.clear(); r.pupils.clear(); r.lids.clear()
	for i in range(2):
		var side := -1.0 if i==0 else 1.0
		r.oval(r.head,Vector3(side*0.382,-0.085,-0.008),Vector3(0.075,0.112,0.060),mat.skin)
		r.oval(r.head,Vector3(side*0.405,-0.079,0.034),Vector3(0.034,0.064,0.014),mat.skin_shadow)
		var eye: Node3D = r.eyes[i]
		eye.position = Vector3(side*0.166,0.005,0.296)
		var border: Array = [Vector3.ZERO]
		var white: Array = [Vector3(0,-0.005,0.007)]
		for j in range(25):
			var a := TAU*j/24.0
			var tilt := side*cos(a)*0.018
			border.append(Vector3(cos(a)*0.118,sin(a)*(0.084 if sin(a)>0 else 0.056)+tilt,0))
			white.append(Vector3(cos(a)*0.107,sin(a)*(0.073 if sin(a)>0 else 0.046)-0.004+tilt,0.007))
		patch(eye,border,mat.ink,"AlmondEyeOutline")
		patch(eye,white,mat.white,"AlmondEyeWhite")
		r.oval(eye,Vector3(0,-0.005,0.021),Vector3(0.052,0.064,0.008),mat.iris)
		r.oval(eye,Vector3(0,0.021,0.027),Vector3(0.050,0.037,0.004),mat.iris_shadow)
		var pupil: MeshInstance3D = r.oval(eye,Vector3(0,-0.004,0.032),Vector3(0.022,0.046,0.005),mat.ink)
		r.pupils.append(pupil)
		r.oval(eye,Vector3(-0.017,0.030,0.041),Vector3(0.017,0.020,0.003),mat.white)
		r.oval(eye,Vector3(0.021,-0.033,0.040),Vector3(0.010,0.010,0.003),mat.gem_light)
		var lid := tube(eye,[Vector3(-0.101,-0.028,0.016),Vector3(-0.053,-0.002,0.020),Vector3(0.018,0.001,0.019),Vector3(0.103,-0.023,0.015)],[0.003,0.006,0.006,0.002],0.55,mat.ink,"UpperLash")
		r.lids.append(lid)
		var brow := tube(r.head,[Vector3(-0.081,-side*0.010,0),Vector3(0,0.014,0.01),Vector3(0.072,side*0.010,0)],[0.005,0.014,0.004],0.55,mat.hair,"ExpressiveBrow")
		brow.position = Vector3(side*0.166,0.145,0.303)
		r.brows.append(brow)
	# Faceted bridge and tapered nose replace the round button nose.
	patch(r.head,[Vector3(-0.036,-0.097,0.323),Vector3(0,-0.055,0.336),Vector3(0.023,-0.12,0.371),Vector3(-0.013,-0.134,0.352)],mat.skin,"NoseBridge")
	patch(r.head,[Vector3(-0.036,-0.097,0.323),Vector3(-0.013,-0.134,0.352),Vector3(0.033,-0.134,0.330)],mat.skin_shadow,"NoseUnderside")
	tube(r.head,[Vector3(-0.070,-0.218,0.296),Vector3(-0.015,-0.228,0.313),Vector3(0.040,-0.219,0.309),Vector3(0.067,-0.207,0.296)],[0.002,0.007,0.006,0.002],0.55,mat.skin_shadow,"QuietAsymmetricSmile")

func hair() -> void:
	# A continuous short cut with an open forehead and cropped nape. The cap is
	# authored directly; editing an old cap's vertices left stale surface normals.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for row in range(12):
		for column in range(48):
			var a := TAU*column/48.0
			var b := TAU*(column+1)/48.0
			var p := hair_cap_point(a,row/12.0)
			var q := hair_cap_point(b,row/12.0)
			var u := hair_cap_point(a,(row+1)/12.0)
			var v := hair_cap_point(b,(row+1)/12.0)
			triangle(st,p,q,u)
			triangle(st,q,v,u)
	finish(r.head,st,mat.hair,"LayeredHairCap")
	# Broad, shallow overlapping blades taper to separate ends. These are not
	# round tubes: the cross-section is a flattened wedge with a swept ridge.
	var locks := [
		[[Vector3(0.12,0.46,0.085),Vector3(0.0,0.445,0.26),Vector3(-0.14,0.315,0.358),Vector3(-0.285,0.14,0.31)],[0.045,0.13,0.09,0.001]],
		[[Vector3(0.25,0.37,0.115),Vector3(0.28,0.33,0.256),Vector3(0.215,0.215,0.339),Vector3(0.13,0.09,0.336)],[0.055,0.102,0.076,0.001]],
		[[Vector3(0.33,0.29,0.035),Vector3(0.43,0.14,0.13),Vector3(0.425,-0.025,0.14),Vector3(0.37,-0.13,0.16)],[0.065,0.085,0.048,0.001]],
		[[Vector3(-0.16,0.41,0.065),Vector3(-0.335,0.30,0.16),Vector3(-0.422,0.10,0.10),Vector3(-0.388,-0.12,0.095)],[0.06,0.12,0.08,0.001]],
		[[Vector3(-0.06,0.465,-0.12),Vector3(-0.25,0.40,-0.24),Vector3(-0.43,0.24,-0.24),Vector3(-0.515,0.17,-0.20)],[0.06,0.125,0.075,0.001]],
		[[Vector3(0.09,0.43,-0.14),Vector3(0.30,0.34,-0.285),Vector3(0.435,0.15,-0.29),Vector3(0.49,0.065,-0.21)],[0.07,0.14,0.075,0.001]],
		[[Vector3(-0.18,0.36,-0.30),Vector3(-0.225,0.17,-0.38),Vector3(-0.195,-0.03,-0.35),Vector3(-0.27,-0.175,-0.235)],[0.07,0.125,0.10,0.001]],
		[[Vector3(0.015,0.41,-0.265),Vector3(0.08,0.205,-0.406),Vector3(0.09,-0.025,-0.365),Vector3(0.015,-0.18,-0.29)],[0.07,0.12,0.10,0.001]],
	]
	for i in range(locks.size()):
		hair_blade(locks[i][0],locks[i][1],mat.hair_lit if i in [0,4,7] else mat.hair,"SweptHairLock%d" % i)
	hair_blade([Vector3(0.07,0.47,-0.10),Vector3(-0.12,0.565,-0.03),Vector3(-0.29,0.56,0.045),Vector3(-0.43,0.425,0.115)],[0.045,0.12,0.083,0.001],mat.hair_lit,"CrownSweep")
	hair_blade([Vector3(0.015,0.435,-0.19),Vector3(0.17,0.485,-0.19),Vector3(0.34,0.43,-0.265),Vector3(0.415,0.365,-0.315)],[0.065,0.125,0.066,0.001],mat.hair,"CrownBackTip")
	# Two small tips break the forehead silhouette without covering the eyes.
	hair_blade([Vector3(0.10,0.41,0.27),Vector3(0.02,0.29,0.365),Vector3(-0.035,0.105,0.344)],[0.055,0.068,0.001],mat.hair_lit,"FringeTip")

func hair_cap_point(angle: float, t: float) -> Vector3:
	var front := maxf(0,cos(angle))
	var back := maxf(0,-cos(angle))
	var hem := 1.80-0.69*pow(front,3)+0.22*back
	var polar := lerpf(0.012,hem,t)
	var wave := 0.006*cos(angle*7.0+t*2.0)*t*t
	return Vector3(sin(angle)*sin(polar)*(0.433+wave)-0.035*(1-t),0.055+cos(polar)*0.445+0.045*pow(1-t,2),cos(angle)*sin(polar)*(0.373+wave)-0.035)

func hair_blade(points: Array, widths: Array, material: Material, label: String) -> void:
	var rings: Array=[]
	var profile := [Vector2(-1,0),Vector2(-0.55,0.60),Vector2(-0.08,1),Vector2(0.55,0.62),Vector2(1,0),Vector2(0.55,-0.18),Vector2(-0.55,-0.18)]
	for index in range((points.size()-1)*6+1):
		var segment := mini(index/6,points.size()-2)
		var t := (index-segment*6)/6.0
		var a: Vector3=points[maxi(0,segment-1)]
		var b: Vector3=points[segment]
		var c: Vector3=points[segment+1]
		var d: Vector3=points[mini(points.size()-1,segment+2)]
		var at := b.cubic_interpolate(c,a,d,t)
		var tangent := (b.cubic_interpolate(c,a,d,t+0.001)-b.cubic_interpolate(c,a,d,t-0.001)).normalized()
		var outward := (at-Vector3(0,0.06,-0.035)).normalized()
		var across := tangent.cross(outward).normalized()
		outward=across.cross(tangent).normalized()
		var width := lerpf(widths[segment],widths[segment+1],smoothstep(0,1,t))
		var thickness := width*0.20
		var ring: Array[Vector3]=[]
		for uv in profile: ring.append(at+across*uv.x*width+outward*uv.y*thickness)
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for row in range(rings.size()-1):
		for side in range(profile.size()):
			var next := (side+1)%profile.size()
			triangle(st,rings[row][side],rings[row+1][side],rings[row][next])
			triangle(st,rings[row][next],rings[row+1][side],rings[row+1][next])
	finish(r.head,st,material,label)

func wand(parent: Node3D) -> void:
	# Leather grip and pommel are above the hand; the crystal points down/outward.
	loft(parent,[[-0.17,0.048,0.046,0],[-0.10,0.055,0.052,0],[0.075,0.051,0.048,0],[0.105,0.037,0.036,0]],mat.leather,"WrappedWandGrip",16)
	loft(parent,[[0.075,0.058,0.056,0],[0.108,0.063,0.059,0],[0.142,0.017,0.017,0]],mat.gold,"WandPommel",8)
	var wrap: Array = []
	var widths: Array = []
	for i in range(33):
		var t := i/32.0
		wrap.append(Vector3(cos(t*TAU*2.5)*0.055,0.07-t*0.22,sin(t*TAU*2.5)*0.052))
		widths.append(0.008)
	tube(parent,wrap,widths,1,mat.gold,"GripBinding",6)
	tube(parent,[Vector3(0,-0.15,0),Vector3(0.018,-0.33,0),Vector3(0.057,-0.49,0),Vector3(0.072,-0.63,0)],[0.048,0.042,0.047,0.063],0.8,mat.wood,"CurvedWandShaft",12)
	tube(parent,[Vector3(0,-0.17,0.039),Vector3(0.026,-0.34,0.034),Vector3(0.059,-0.50,0.039),Vector3(0.072,-0.63,0.056)],[0.009,0.007,0.008,0.008],0.6,mat.gold_lit,"ShaftInlay",8)
	var crown: Node3D = r.joint(parent,"CrystalCrown",Vector3(0.072,-0.65,0))
	loft(crown,[[-0.035,0.070,0.063,0],[0,0.090,0.074,0],[0.035,0.061,0.058,0]],mat.gold,"CrownCollar",10)
	# Long six-sided cut crystal with pointed end and visible light/dark facets.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(6):
		var a := TAU*i/6
		var b := TAU*(i+1)/6
		var p := Vector3(sin(a)*0.116,-0.14,cos(a)*0.10)
		var q := Vector3(sin(b)*0.116,-0.14,cos(b)*0.10)
		var u := Vector3(sin(a)*0.075,-0.04,cos(a)*0.067)
		var v := Vector3(sin(b)*0.075,-0.04,cos(b)*0.067)
		var tint := Color(0.57,0.75,0.88) if i%3==0 else (Color(0.9,1,1) if i%3==1 else Color(0.73,0.87,0.97))
		triangle(st,u,p,v,tint); triangle(st,v,p,q,tint)
		triangle(st,p,Vector3(0,-0.33,0),q,tint)
	finish(crown,st,mat.gem,"CutAetherCrystal")
	for i in range(3):
		var a := TAU*i/3+0.25
		tube(crown,[Vector3(sin(a)*0.06,0.014,cos(a)*0.06),Vector3(sin(a)*0.15,-0.09,cos(a)*0.13),Vector3(sin(a)*0.11,-0.23,cos(a)*0.10)],[0.021,0.022,0.009],0.8,mat.gold_lit,"CrystalSettingClaw",8)
	tube(crown,[Vector3(-0.015,-0.07,0.071),Vector3(0,-0.15,0.105),Vector3(0.007,-0.24,0.047)],[0.008,0.012,0.003],0.25,mat.gem_light,"CrystalGlint",6)
