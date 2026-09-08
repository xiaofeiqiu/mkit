extends Node3D

# Editable, articulated 3D source. Sprite directions are rendered from this one model.
# Feet follow a planted stance and lifted swing; two-link IK bends each knee.
var kind := "mage"
var hips: Node3D
var chest: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var thighs: Array[Node3D] = []
var knees: Array[Node3D] = []
var ankles: Array[Node3D] = []
var eyes: Array[Node3D] = []
var coat_tails: Array[Node3D] = []
var scarf: Node3D
var staff: Node3D
var back_staff: Node3D
var mats: Dictionary = {}
const LEG := 0.425

func material(hex: String, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = roughness
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m

func joint(parent: Node3D, label: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = at
	parent.add_child(node)
	return node

func mesh(parent: Node3D, primitive: Mesh, at: Vector3, scale_value: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = primitive
	node.material_override = mat
	node.position = at
	node.scale = scale_value
	parent.add_child(node)
	return node

func oval(parent: Node3D, at: Vector3, radii: Vector3, mat: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	sphere.radial_segments = 16
	sphere.rings = 10
	return mesh(parent,sphere,at,radii,mat)

func cylinder(parent: Node3D, at: Vector3, length: float, top: float, bottom: float, mat: Material, squash: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.height = length
	c.top_radius = top
	c.bottom_radius = bottom
	c.radial_segments = 12
	return mesh(parent,c,at,squash,mat)

func box(parent: Node3D, at: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = dimensions
	return mesh(parent,b,at,Vector3.ONE,mat)

func spike(parent: Node3D, base: Vector3, tip: Vector3, width: float, mat: Material, depth: float = 0.7) -> void:
	var axis := (tip-base).normalized()
	var across := axis.cross(Vector3.FORWARD).normalized()
	if across.length_squared()<0.1:
		across = Vector3.RIGHT
	var normal := axis.cross(across).normalized()
	var center := base.lerp(tip,0.5)
	var ring: Array[Vector3] = [base+across*width,base+normal*width*depth,base-across*width,base-normal*width*depth]
	var mid: Array[Vector3] = []
	for p in ring:
		mid.append(center+(p-base)*0.64)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(4):
		var j := (i+1)%4
		for p in [ring[i],mid[i],ring[j],ring[j],mid[i],mid[j],mid[i],tip,mid[j]]:
			st.add_vertex(p)
	st.generate_normals()
	mesh(parent,st.commit(),Vector3.ZERO,Vector3.ONE,mat)

func build(actor_kind: String) -> void:
	kind = actor_kind
	mats = {"skin":material("e7ac7b"),"skin_shadow":material("c87e58"),"hair":material("913f29"),"hair_light":material("bd6335"),"blue":material("327dba"),"blue_dark":material("245278"),"cream":material("f5e4b5"),"leather":material("73503c"),"sole":material("302e34"),"eye":material("263647"),"white":material("fff3d9"),"gold":material("dea44d"),"wood":material("694735"),"gem":material("ee9950")}
	if kind=="mentor":
		mats.skin = material("dcb393")
		mats.hair = material("d6d6d0")
		mats.hair_light = material("eee4d2")
		mats.blue = material("6b658f")
		mats.blue_dark = material("454665")
	elif kind=="goblin":
		mats.skin = material("80aa69")
		mats.skin_shadow = material("527755")
		mats.hair = material("754631")
		mats.hair_light = material("bd7045")
		mats.blue = material("927443")
		mats.blue_dark = material("665334")
		mats.cream = material("d0c297")
	name = actor_kind.capitalize()+"Rig"
	hips = joint(self,"Pelvis",Vector3(0,0.89,0))
	oval(hips,Vector3(0,0.05,0),Vector3(0.285,0.20,0.195),mats.blue_dark)
	chest = joint(hips,"Chest",Vector3(0,0.16,0))
	cylinder(chest,Vector3(0,0.30,0),0.62,0.30,0.285,mats.blue,Vector3(1,1,0.70))
	oval(chest,Vector3(0,0.55,0),Vector3(0.325,0.14,0.205),mats.blue)
	# A cream shirt, two broad lapels and a belt keep the costume readable at 72px.
	box(chest,Vector3(0,0.32,0.213),Vector3(0.16,0.46,0.025),mats.cream)
	for side in [-1.0,1.0]:
		var lapel := box(chest,Vector3(side*0.145,0.41,0.20),Vector3(0.105,0.34,0.035),mats.blue_dark)
		lapel.rotation.z = side*-0.14
		var tail := joint(hips,"CoatTail"+str(side),Vector3(side*0.15,0.08,-0.08))
		var cloth := cylinder(tail,Vector3(0,-0.21,0),0.43,0.16,0.225,mats.blue,Vector3(1,1,0.66))
		cloth.rotation.z = side*0.07
		coat_tails.append(tail)
	cylinder(hips,Vector3(0,0.17,0),0.095,0.305,0.305,mats.leather,Vector3(1,1,0.70))
	box(hips,Vector3(0,0.17,0.219),Vector3(0.11,0.083,0.035),mats.gold)
	oval(hips,Vector3(-0.31,0.02,-0.015),Vector3(0.11,0.15,0.085),mats.leather)
	# Separate hip, knee and ankle pivots, rather than a whole-sprite bob.
	for side in [-1.0,1.0]:
		var thigh := joint(hips,"Hip"+str(side),Vector3(side*0.175,-0.05,0))
		cylinder(thigh,Vector3(0,-LEG/2,0),LEG,0.125,0.10,mats.blue_dark)
		oval(thigh,Vector3.ZERO,Vector3(0.13,0.13,0.13),mats.blue_dark)
		var knee := joint(thigh,"Knee",Vector3(0,-LEG,0))
		oval(knee,Vector3.ZERO,Vector3(0.105,0.10,0.105),mats.blue_dark)
		cylinder(knee,Vector3(0,-LEG*0.48,0),LEG*0.96,0.105,0.085,mats.leather)
		cylinder(knee,Vector3(0,-0.06,0),0.09,0.122,0.117,mats.cream)
		var ankle := joint(knee,"Ankle",Vector3(0,-LEG,0))
		oval(ankle,Vector3(0,0.07,0.105),Vector3(0.14,0.12,0.23),mats.leather)
		oval(ankle,Vector3(0,0.009,0.115),Vector3(0.148,0.038,0.235),mats.sole)
		thighs.append(thigh)
		knees.append(knee)
		ankles.append(ankle)
	for side in [-1.0,1.0]:
		var shoulder := joint(chest,"Shoulder"+str(side),Vector3(side*0.35,0.49,0))
		oval(shoulder,Vector3(0,-0.04,0),Vector3(0.14,0.15,0.14),mats.blue)
		cylinder(shoulder,Vector3(0,-0.16,0),0.31,0.132,0.108,mats.blue)
		var elbow := joint(shoulder,"Elbow",Vector3(0,-0.31,0))
		oval(elbow,Vector3.ZERO,Vector3(0.105,0.11,0.105),mats.blue)
		cylinder(elbow,Vector3(0,-0.105,0),0.23,0.105,0.09,mats.cream)
		cylinder(elbow,Vector3(0,-0.235,0),0.08,0.105,0.10,mats.leather)
		var hand := joint(elbow,"Hand",Vector3(0,-0.30,0))
		oval(hand,Vector3.ZERO,Vector3(0.105,0.12,0.09),mats.skin)
		oval(hand,Vector3(side*-0.065,0,0.07),Vector3(0.046,0.073,0.05),mats.skin)
		arms.append(shoulder)
		elbows.append(elbow)
		if side>0:
			staff = joint(hand,"Staff",Vector3(0,0,0.075))
			if kind=="goblin":
				cylinder(staff,Vector3(0,0.13,0),0.62,0.115,0.04,mats.wood)
				oval(staff,Vector3(0,0.43,0),Vector3(0.12,0.18,0.11),mats.wood)
			else:
				cylinder(staff,Vector3(0,0.13,0),1.32,0.029,0.04,mats.wood)
				cylinder(staff,Vector3(0,0.75,0),0.13,0.085,0.045,mats.gold)
				oval(staff,Vector3(0,0.88,0),Vector3(0.10,0.14,0.095),mats.gem)
				oval(staff,Vector3(-0.025,0.92,0.073),Vector3(0.028,0.045,0.014),mats.cream)
	# Neck, scarf and head remain distinct so breathing and glances have a center.
	cylinder(chest,Vector3(0,0.72,0),0.20,0.125,0.13,mats.skin)
	oval(chest,Vector3(0,0.68,0.015),Vector3(0.24,0.11,0.22),mats.cream)
	scarf = joint(chest,"ScarfEnd",Vector3(-0.15,0.67,-0.15))
	var ribbon := box(scarf,Vector3(0,-0.18,-0.04),Vector3(0.13,0.37,0.028),mats.cream)
	ribbon.rotation.x = 0.18
	head = joint(chest,"Head",Vector3(0,1.02,0))
	oval(head,Vector3.ZERO,Vector3(0.43,0.365,0.37),mats.skin)
	for side in [-1.0,1.0]:
		if kind=="goblin":
			spike(head,Vector3(side*0.33,0,0),Vector3(side*0.79,0.20,-0.08),0.14,mats.skin)
		else:
			oval(head,Vector3(side*0.405,-0.045,0),Vector3(0.09,0.125,0.065),mats.skin)
		var eye := joint(head,"Eye"+str(side),Vector3(side*0.155,0.022,0.337))
		oval(eye,Vector3.ZERO,Vector3(0.060,0.079,0.017),mats.white)
		oval(eye,Vector3(side*-0.006,-0.003,0.016),Vector3(0.030,0.051,0.010),mats.eye)
		oval(eye,Vector3(-0.009,0.022,0.027),Vector3(0.009,0.015,0.005),mats.white)
		eyes.append(eye)
		var brow := box(head,Vector3(side*0.155,0.155,0.324),Vector3(0.14,0.035,0.038),mats.hair)
		brow.rotation.z = side*0.1
	oval(head,Vector3(0,-0.07,0.359),Vector3(0.053,0.059,0.065),mats.skin)
	oval(head,Vector3(0,-0.205,0.309),Vector3(0.063,0.017,0.018),mats.skin_shadow)
	if kind=="goblin":
		var hat := cylinder(head,Vector3(0,0.41,-0.04),0.49,0.01,0.46,mats.hair_light)
		hat.rotation.z = -0.17
		cylinder(head,Vector3(0,0.235,-0.015),0.085,0.48,0.48,mats.hair)
	elif kind=="mentor":
		oval(head,Vector3(0,0.15,-0.08),Vector3(0.45,0.275,0.36),mats.hair)
		for side in [-1.0,1.0]:
			oval(head,Vector3(side*0.31,-0.12,0.14),Vector3(0.125,0.21,0.13),mats.hair)
			oval(head,Vector3(side*0.105,-0.145,0.335),Vector3(0.135,0.055,0.06),mats.hair_light)
		spike(head,Vector3(0,-0.235,0.22),Vector3(0,-0.57,0.22),0.24,mats.hair_light,0.6)
	else:
		oval(head,Vector3(0,0.19,-0.07),Vector3(0.455,0.30,0.415),mats.hair)
		# A few sculpted hair locks: broad facets, no ornamental texture noise.
		for lock in [[Vector3(-0.31,0.32,0.12),Vector3(-0.44,0.46,0.26),0.15],[Vector3(-0.14,0.36,0.23),Vector3(-0.26,0.11,0.41),0.14],[Vector3(0.05,0.41,0.25),Vector3(-0.08,0.06,0.41),0.16],[Vector3(0.21,0.36,0.21),Vector3(0.27,0.12,0.37),0.14],[Vector3(0.25,0.39,0.02),Vector3(0.44,0.58,0.02),0.15],[Vector3(-0.03,0.43,-0.01),Vector3(0.05,0.64,-0.08),0.18],[Vector3(-0.28,0.22,-0.24),Vector3(-0.43,0.09,-0.39),0.16],[Vector3(0.29,0.18,-0.22),Vector3(0.38,-0.03,-0.34),0.16]]:
			spike(head,lock[0],lock[1],lock[2],mats.hair_light if lock[0].x<0 else mats.hair)
		for side in [-1.0,1.0]:
			spike(head,Vector3(side*0.37,0.16,0.04),Vector3(side*0.42,-0.15,0.12),0.12,mats.hair)
	back_staff = staff.duplicate() as Node3D
	back_staff.name = "StowedStaff"
	chest.add_child(back_staff)
	back_staff.position = Vector3(0.25,0.18,-0.255)
	back_staff.rotation = Vector3(0,0,-0.35)
	pose("idle",0,0)

static func yaw_for_facing(direction: int) -> float:
	var a := direction*PI/4
	return atan2(-sin(a),cos(a)/0.5)

func pose(action: String, phase: float, direction: int) -> void:
	staff.visible = action!="seal"
	back_staff.visible = action=="seal"
	rotation.y = yaw_for_facing(direction)
	var walk := action=="walk"
	var wave := sin(phase*TAU)
	var bounce := 0.022*cos(phase*TAU*2) if walk else 0.008*sin(phase*TAU)
	hips.position = Vector3(0.016*wave if walk else 0.01*sin(phase*TAU),0.89+bounce,0)
	hips.rotation = Vector3.ZERO
	chest.rotation = Vector3(-0.05 if walk else 0,0.075*wave if walk else 0.025*wave,-0.025*wave if walk else 0.015*wave)
	head.rotation = Vector3(0.02*sin(phase*TAU+0.4),-chest.rotation.y*0.45,0)
	head.position.y = 1.02 + 0.008*sin(phase*TAU)
	scarf.rotation.x = 0.16+0.22*wave if walk else 0.06*wave
	scarf.rotation.z = 0.10*sin(phase*TAU-0.5)
	for i in range(2):
		var p := fposmod(phase+i*0.5,1.0)
		var z := 0.0
		var lift := 0.0
		var foot_pitch := 0.0
		if walk:
			if p<0.60:
				z = lerpf(0.28,-0.28,p/0.60)
				if p<0.13:
					foot_pitch = lerpf(-0.22,0,p/0.13)
				elif p>0.45:
					foot_pitch = lerpf(0,0.32,(p-0.45)/0.15)
				lift += maxf(0,sin(foot_pitch))*0.31
			else:
				var t := (p-0.60)/0.40
				z = lerpf(-0.28,0.28,t*t*(3-2*t))
				lift = 0.18*sin(t*PI)
				foot_pitch = lerpf(0.25,-0.22,t)
		var dy := 0.042+lift-(hips.position.y-0.05)
		var d := clampf(Vector2(dy,z).length(),0.01,LEG*2-0.004)
		var bend := acos(clampf(d/(2*LEG),-1,1))
		thighs[i].rotation.x = atan2(-z,-dy)-bend
		knees[i].rotation.x = 2*bend
		ankles[i].rotation.x = -thighs[i].rotation.x-knees[i].rotation.x+foot_pitch
		var sign_value := -1.0 if i==0 else 1.0
		arms[i].rotation = Vector3(-0.10+sign_value*wave*0.48 if walk else -0.08+wave*0.035,0,sign_value*0.13)
		elbows[i].rotation.x = -0.20-0.08*absf(wave) if walk else -0.22
		coat_tails[i].rotation = Vector3(0.08+0.18*sin(phase*TAU+i*PI) if walk else 0.02*wave,0,sign_value*0.035)
		# One intentional blink in an idle cycle; face geometry stays constant.
		eyes[i].scale.y = 0.12 if action=="idle" and phase>=0.75 and phase<0.875 else 1.0
	if action=="attack":
		var punch := sin(phase*PI)
		chest.rotation.y = -0.28*punch
		arms[1].rotation.x = -0.15-1.20*punch
		elbows[1].rotation.x = -0.25-0.30*punch
		arms[0].rotation.x = -0.25-0.6*punch
		head.rotation.x = -0.06*punch
	elif action=="seal":
		# Both hands come together in front of the chest before the staff lifts.
		var charge := minf(phase*3,1.0)
		for i in range(2):
			arms[i].rotation.x = lerpf(-0.1,-0.65,charge)
			arms[i].rotation.z = (0.55 if i==0 else -0.55)*charge
			elbows[i].rotation.x = lerpf(-0.2,-1.35,charge)
		chest.rotation.x = -0.05
		head.rotation.x = 0.10-0.16*phase
	elif action=="hurt":
		var recoil:=sin(phase*PI)*pow(1.0-phase,0.35)
		hips.position.z=-0.10*recoil
		chest.rotation.x=-0.35*recoil
		chest.rotation.z=0.13*recoil
		head.rotation.x=-0.28*recoil
		arms[0].rotation.x=-0.4*recoil
		arms[1].rotation.x=0.25*recoil
		elbows[0].rotation.x=-0.7*recoil
	elif action=="death":
		# Knees buckle first; torso follows; the body settles on its side.
		var fall:=smoothstep(0.12,0.78,phase)
		var buckle:=sin(minf(phase/0.5,1.0)*PI)*0.5
		hips.position.y=0.89-0.65*fall-0.15*buckle
		hips.position.z=-0.18*fall
		hips.rotation=Vector3(-1.24*fall,0,0.36*fall)
		chest.rotation.x=0.18*buckle
		head.rotation.x=-0.28*fall
		for i in range(2):
			thighs[i].rotation.x=-0.45*buckle+0.1*fall
			knees[i].rotation.x=0.9*buckle+0.40*fall
			arms[i].rotation.z=(-0.7 if i==0 else 0.7)*fall
			elbows[i].rotation.x=-0.35*fall
			eyes[i].scale.y=0.1
