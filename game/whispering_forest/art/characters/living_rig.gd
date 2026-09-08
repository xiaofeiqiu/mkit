extends "res://game/whispering_forest/art/characters/expressive_rig.gd"

const Motion = preload("res://game/whispering_forest/art/characters/motion_spec.gd")
const LongStaff = preload("res://game/whispering_forest/art/characters/long_staff.gd")
var motion_ready := false
var hair_pivots: Array[Node3D] = []
var contact_targets: Array[Vector3] = [Vector3.ZERO,Vector3.ZERO]
var contact_planted: Array[bool] = [true,true]

func build(actor_kind: String) -> void:
	super.build(actor_kind)
	if actor_kind!="mage": return
	scale=Vector3.ONE*Motion.MODEL_TO_METRES
	LongStaff.new().rebuild(staff,self)
	LongStaff.new().rebuild(back_staff,self)
	back_staff.rotation=Vector3(0,0,-0.14)
	for i in range(8):
		var lock: Node3D = head.get_node("SweptHairLock%d" % i)
		var pivot := Node3D.new()
		pivot.name="HairFollow%d" % i
		pivot.position=Vector3(0,0.35,0)
		head.add_child(pivot)
		lock.reparent(pivot,false)
		lock.position=-pivot.position
		hair_pivots.append(pivot)
	motion_ready=true
	pose("idle",0,7)

func pose(action: String, phase: float, direction: int, stride: float=-1.0) -> void:
	var base_action := "walk" if action=="run" else ("idle" if action=="look" or action.begins_with("stop_") else action)
	super.pose(base_action,phase,direction,stride)
	if not motion_ready: return
	# Same fixed camera as buildings: rotate the model into its 45-degree basis.
	rotation.y=yaw_for_facing(direction)+PI/4
	for pivot in hair_pivots: pivot.rotation=Vector3.ZERO
	chest.scale=Vector3.ONE
	if action in ["idle","ready","look"]:
		settled_pose(phase,action)
	elif action in ["walk","run"]:
		travel_pose(phase,action=="run")
	elif action in ["attack","cast_walk"]:
		if action=="cast_walk": travel_pose(fposmod(phase*0.42/0.52,1.0),true)
		else: settled_pose(0,"idle")
		staff_cast(phase,action=="cast_walk")
	elif action=="start":
		settled_pose(0,"idle")
		var before := capture(body_joints())
		travel_pose(phase*0.25,true)
		blend_from(before,smoothstep(0,0.8,phase))
	elif action=="stop" or action.begins_with("stop_"):
		var quarter := 0 if action=="stop" else int(action.trim_prefix("stop_"))
		travel_pose(quarter*0.25,true)
		var before := capture(body_joints())
		settled_pose(0,"idle")
		blend_from(before,smoothstep(0,1,phase))
	# A short complete blink, never a 400 ms closed-eye hold.
	if action!="death":
		var closure := blink(phase,0.81,0.052) if action in ["idle","ready"] else 0.0
		if action=="look": closure=maxf(blink(phase,0.13,0.075),blink(phase,0.72,0.075))
		for eye in eyes: eye.scale.y=lerpf(1.0,0.07,closure)
	for i in range(hair_pivots.size()):
		var amount := 0.008 if action in ["walk","run","cast_walk"] else 0.004
		hair_pivots[i].rotation.x=amount*sin(phase*TAU-0.8-i*0.17)
		hair_pivots[i].rotation.z=amount*0.45*sin(phase*TAU-0.9-i*0.23)
	if action!="death":
		var lean := 0.025*sin(phase*TAU-0.4) if action in ["walk","run","cast_walk"] else 0.0
		orient_staff(Vector3(lean,0,0.018))

func settled_pose(phase: float, action: String) -> void:
	var breath := sin(phase*TAU)
	var look := smoothstep(0.12,0.34,phase)*(1.0-smoothstep(0.65,0.94,phase)) if action=="look" else 0.0
	var ready := action=="ready"
	hips.position=Vector3(-0.042+0.017*sin(phase*TAU-0.6)+look*0.065,0.84+0.012*breath,0.018)
	hips.rotation=Vector3(0,0.012*breath,0)
	chest.rotation=Vector3(-0.045 if ready else 0.015,0.035*breath+0.10*look,0.036-0.025*breath)
	chest.scale=Vector3(1.0+0.010*breath,1.0+0.010*breath,1.0+0.020*breath)
	head.position.y=1.02-0.004*breath
	head.rotation=Vector3(-0.05+0.027*sin(phase*TAU-0.3),0.045+0.025*sin(phase*TAU-0.7)+0.34*look,-0.035-0.05*look)
	arms[0].rotation=Vector3(-0.05+0.055*sin(phase*TAU-0.5)-0.32*look,0,-0.105)
	arms[1].rotation=Vector3(-0.32-0.060*sin(phase*TAU-0.35)-0.23*look,0,0.15)
	elbows[0].rotation=Vector3(-0.20-0.055*breath-0.52*look,0,0)
	elbows[1].rotation=Vector3(-0.68-0.065*sin(phase*TAU-0.2)-0.25*look,0,0)
	if ready:
		chest.rotation.x=-0.10
		arms[1].rotation.x-=0.20
		elbows[1].rotation.x-=0.20
		arms[0].rotation.x-=0.18
	for i in range(2):
		var side := -1.0 if i==0 else 1.0
		plant_leg(i,Vector3(side*0.18,0,-0.015 if i==0 else 0.065),0,side*0.07)
		contact_planted[i]=true
		coat_tails[i].rotation=Vector3(0.055+0.04*sin(phase*TAU-0.6+i*0.55),0,side*0.04)
	scarf.rotation=Vector3(0.10+0.065*sin(phase*TAU-0.65),0,0.04*sin(phase*TAU-0.4))
	for pupil in pupils: pupil.position.x=0.004+0.012*look+0.003*sin(phase*TAU-0.7)

func travel_pose(phase: float, running: bool) -> void:
	var wave := sin(phase*TAU)
	# One smooth rise per step. The old stance/flight piecewise curves added
	# a second rise within each step (four jolts per stride, almost 8 Hz).
	var base_height := 0.76 if running else 0.78
	var height := base_height+(0.014 if running else -0.016)*cos(phase*TAU*2)
	hips.position=Vector3(0.010*wave,height,0)
	hips.rotation=Vector3(0,0.055*wave,0)
	chest.rotation=Vector3(0.07 if running else 0.035,-0.065*wave,-0.012*wave)
	# Neck compensation steadies the gaze while knees, arms and coat carry the gait.
	head.position.y=1.02-0.55*(height-base_height)
	head.rotation=Vector3(-0.07,0.018*wave,0.010*wave)
	for i in range(2):
		var p := fposmod(phase+i*0.5,1.0)
		var duty := 0.30 if running else 0.60
		var stride_length := Motion.RUN_STRIDE if running else Motion.WALK_STRIDE
		var half := stride_length*duty*0.5
		var z := stride_length*(duty*0.5-p)
		var lift := 0.0
		var pitch := 0.0
		if p<duty:
			pitch=-0.20*(1-smoothstep(0,0.07,p))+0.30*smoothstep(duty-0.08,duty,p)
		else:
			var t := (p-duty)/(1-duty)
			z=lerpf(-half,half,smoothstep(0,1,t))-0.10*sin(TAU*t)
			lift=(0.34 if running else 0.19)*sin(t*PI)
			pitch=lerpf(0.30,-0.20,smoothstep(0,1,t))
		var side := -1.0 if i==0 else 1.0
		var sole_clearance := maxf(0,maxf(sin(pitch)*0.33,-sin(pitch)*0.15))
		plant_leg(i,Vector3(side*(0.18+0.018*sin(p*TAU)),lift+sole_clearance,z),pitch,side*0.035)
		contact_planted[i]=p<duty
		var swing := cos((phase+i*0.5)*TAU-0.10)
		arms[i].rotation=Vector3(-0.10+swing*(0.66 if running else 0.42),0,side*(0.11+0.035*cos(phase*TAU*2)))
		elbows[i].rotation=Vector3(-0.62-0.20*maxf(0,-swing) if running else -0.30-0.16*maxf(0,-swing),0,0)
		coat_tails[i].rotation=Vector3(-0.17+(0.21 if running else 0.12)*sin(phase*TAU+i*PI-0.55),0,side*0.05+0.03*wave)
	# The holding arm swings less than the free arm; it still has a living wrist.
	arms[1].rotation.x=-0.38-0.09*cos(phase*TAU-0.10)
	elbows[1].rotation.x=-0.94-0.08*sin(phase*TAU-0.5)
	scarf.rotation=Vector3(-0.24+0.09*sin(phase*TAU-0.7),0,0.055*sin(phase*TAU-0.8))

func orient_staff(angles: Vector3) -> void:
	var node: Node3D=staff.get_parent()
	var parent_basis := Basis.IDENTITY
	while node!=self:
		parent_basis=node.basis*parent_basis
		node=node.get_parent()
	staff.basis=parent_basis.inverse()*Basis.from_euler(angles)

func staff_cast(phase: float, mobile: bool=false) -> void:
	var times := [0.0,0.28,3.0/7.0,0.60,1.0]
	# Lift the upright staff, press it down on release, then recover its weight.
	arms[1].rotation.x=sample_keys(phase,times,[-0.32,-0.60,-0.10,-0.16,-0.32])
	elbows[1].rotation.x=sample_keys(phase,times,[-0.68,-1.04,-0.09,-0.28,-0.68])
	if mobile:
		arms[1].rotation.x-=0.10
		elbows[1].rotation.x-=0.75*sin(phase*PI)
	arms[1].rotation.z=0.20
	chest.rotation.y=sample_keys(phase,times,[-0.02,0.12,-0.13,-0.05,-0.02])
	chest.rotation.x=0.04*sin(phase*PI)
	arms[0].rotation=Vector3(-0.15-0.60*sin(phase*PI),0,-0.22)
	elbows[0].rotation.x=-0.30-0.55*sin(phase*PI)
	head.rotation=Vector3(-0.04,-chest.rotation.y*0.45,-0.025)

func bone_basis(axis: Vector3) -> Basis:
	var y := -axis.normalized()
	var x := (Vector3.RIGHT-y*y.x).normalized()
	return Basis(x,y,x.cross(y)).orthonormalized()

func plant_leg(index: int, ankle_target: Vector3, pitch: float, toe_yaw: float) -> void:
	# Solve both links in pelvis space. Lateral breathing/weight shifts therefore
	# do not drag planted feet sideways; target is in the model's ground space.
	contact_targets[index]=ankle_target
	var hip: Vector3 = thighs[index].position
	var target := hips.transform.affine_inverse()*ankle_target
	var delta := target-hip
	var distance := clampf(delta.length(),0.01,LEG*2-0.001)
	var along := delta.normalized()
	var pole := (Vector3.BACK-along*along.dot(Vector3.BACK)).normalized()
	var knee := hip+along*distance*0.5+pole*sqrt(maxf(0,LEG*LEG-distance*distance*0.25))
	var upper := bone_basis(knee-hip)
	var lower := bone_basis(target-knee)
	thighs[index].basis=upper
	knees[index].basis=upper.inverse()*lower
	ankles[index].basis=lower.inverse()*hips.basis.inverse()*Basis(Vector3.UP,toe_yaw)*Basis(Vector3.RIGHT,pitch)

func blink(phase: float, center: float, width: float) -> float:
	return 1.0-smoothstep(0,width*0.5,absf(phase-center))

func body_joints() -> Array:
	return [hips,chest,head,arms[0],arms[1],elbows[0],elbows[1],thighs[0],thighs[1],knees[0],knees[1],ankles[0],ankles[1],scarf,coat_tails[0],coat_tails[1]]

func capture(nodes: Array) -> Array:
	var result: Array=[]
	for node in nodes: result.append([node,node.transform])
	return result

func restore(snapshot: Array) -> void:
	for item in snapshot: item[0].transform=item[1]

func blend_from(snapshot: Array, weight: float) -> void:
	for item in snapshot: item[0].transform=item[1].interpolate_with(item[0].transform,weight)
