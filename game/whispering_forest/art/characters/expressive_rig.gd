extends "res://game/whispering_forest/art/characters/character_rig.gd"

# Performance layer over the shared, editable skeleton. No mirrored hands.
# Attack contact is frame 3 of 8 (phase 3/7), also used by combat timing.
var brows: Array[MeshInstance3D] = []
var pupils: Array[MeshInstance3D] = []
var lids: Array[MeshInstance3D] = []

func build(actor_kind: String) -> void:
	super.build(actor_kind)
	if actor_kind=="mage":
		preload("res://game/whispering_forest/art/characters/mage_sculpt.gd").new().rebuild(self)
		pose("idle",0,7)
		return
	if kind == "mage":
		mats.skin.albedo_color = Color("e9b499")
		mats.skin_shadow.albedo_color = Color("b87466")
		mats.blue.albedo_color = Color("347fa1")
		mats.blue_dark.albedo_color = Color("263f62")
		mats.hair.albedo_color = Color("743529")
		mats.hair_light.albedo_color = Color("ab5136")
		mats.cream.albedo_color = Color("eee8d5")
	# Reduce the exposed eye white; the upper lid gives a focused gaze.
	for i in range(eyes.size()):
		var eye: Node3D = eyes[i]
		var side := -1.0 if i == 0 else 1.0
		eye.position.y = 0.038
		eye.get_child(0).scale = Vector3(0.060,0.060,0.017)
		var pupil := eye.get_child(1) as MeshInstance3D
		pupil.scale = Vector3(0.034,0.046,0.011)
		pupils.append(pupil)
		var lid := oval(eye,Vector3(0,0.059,0.018),Vector3(0.061,0.009,0.010),mats.hair)
		lids.append(lid)
		for child in head.get_children():
			if child is MeshInstance3D and child.mesh is BoxMesh and absf(child.position.x-side*0.155)<0.01:
				child.position.y = 0.139
				child.scale.y = 0.70
				brows.append(child)
	if kind == "mage":
		# A tapered lower face, less circular cheeks, and a quiet half-smile.
		var face := head.get_child(0) as MeshInstance3D
		face.scale = Vector3(0.408,0.382,0.354)
		for child in head.get_children():
			if child is MeshInstance3D and child.position.y < -0.19 and child.position.z > 0.30:
				child.rotation.z = -0.10
				child.position.x = 0.010
		# Broad cuff silhouettes hide the toy-like elbow transition.
		for elbow in elbows:
			oval(elbow,Vector3(0,-0.035,0),Vector3(0.118,0.115,0.105),mats.cream)
	pose("idle",0,7)

func pose(action: String, phase: float, direction: int, stride: float = -1.0) -> void:
	var locomotion := action in ["walk", "cast_walk"]
	var leg_phase := phase if stride<0 else stride
	super.pose("walk" if locomotion else ("idle" if action in ["ready","start","stop","dodge"] else action),leg_phase if locomotion else phase,direction)
	var wave := sin(phase*TAU)
	# Looking and weight shifts are deliberately asymmetrical.
	if action in ["idle","ready"]:
		hips.position.x = -0.035 + 0.009*wave
		chest.rotation.z = 0.035
		chest.rotation.y = -0.07 + 0.018*wave
		head.rotation = Vector3(-0.10,0.055+0.10*sin(phase*TAU-0.7),-0.035)
		arms[0].rotation.z = -0.13
		arms[1].rotation.x = -0.22
		elbows[1].rotation.x = -0.57
		staff.rotation.x = 0.12
		if action == "ready":
			chest.rotation.x = -0.12
			head.rotation.y = 0.0
			arms[0].rotation.x = -0.32
			arms[1].rotation.x = -0.48
			elbows[0].rotation.x = -0.60
			elbows[1].rotation.x = -0.90
	elif locomotion:
		chest.rotation.x = -0.12
		head.rotation.x = -0.05
		arms[1].rotation.x = -0.32-0.16*sin(leg_phase*TAU)
		elbows[1].rotation.x = -0.62
		scarf.rotation.x = 0.35+0.18*sin(leg_phase*TAU-0.8)
	elif action in ["start","stop","dodge"]:
		var push := sin(phase*PI)
		chest.rotation.x = -0.22*push if action!="stop" else 0.12*push
		head.rotation.x = -0.09
		arms[0].rotation.x = -0.25-0.4*push
		elbows[1].rotation.x = -0.65
		if action == "dodge":
			hips.position.y -= 0.16*push
			chest.rotation.z = -0.18*push
			arms[0].rotation.z = -0.5*push
	if action in ["attack","cast_walk"]:
		# Anticipation -> snap -> overshoot -> relaxed recovery, not a sine swing.
		var times := [0.0,0.28,3.0/7.0,0.60,1.0]
		var chest_keys := [-0.07,0.28,-0.36,-0.24,-0.07]
		var arm_keys := [-0.22,0.10,-1.55,-1.20,-0.22]
		var elbow_keys := [-0.57,-1.20,-0.26,-0.45,-0.57]
		chest.rotation.y = sample_keys(phase,times,chest_keys)
		chest.rotation.x = -0.08*sin(phase*PI)
		arms[1].rotation.x = sample_keys(phase,times,arm_keys)
		elbows[1].rotation.x = sample_keys(phase,times,elbow_keys)
		arms[0].rotation.x = -0.20-0.72*sin(phase*PI)
		elbows[0].rotation.x = -0.35-0.45*sin(phase*PI)
		head.rotation = Vector3(-0.08,-chest.rotation.y*0.55,0)
		scarf.rotation.x = 0.12+0.35*sin(maxf(0,phase-0.16)*PI)
	elif action == "seal":
		# The gaze follows the hands, then lifts toward the falling meteor.
		head.rotation.x = lerpf(0.15,-0.32,smoothstep(0.4,0.9,phase))
		chest.rotation.x = -0.06-0.10*smoothstep(0.55,1.0,phase)
		scarf.rotation.x = 0.16+0.40*smoothstep(0.3,1.0,phase)
	elif action == "hurt":
		var recoil := (1.0-smoothstep(0.15,1.0,phase))
		chest.rotation.x = -0.40*recoil
		chest.rotation.z = 0.18*recoil
		head.rotation.x = -0.32*recoil
	for i in range(pupils.size()):
		var focused := action in ["attack","cast_walk","ready","seal"]
		pupils[i].position.x = (-0.006 if i==1 else 0.006) + (0.009*sin(phase*TAU-0.7) if action=="idle" else 0.0)
		lids[i].position.y = 0.051 if focused else 0.059
		if i<brows.size():
			brows[i].rotation.z = (-1.0 if i==0 else 1.0)*(0.22 if focused else 0.07)
	if kind=="mage":
		staff.rotation = Vector3(0,0,0.06)

func sample_keys(phase: float, times: Array, values: Array) -> float:
	for i in range(times.size()-1):
		if phase <= float(times[i+1]):
			var t := inverse_lerp(float(times[i]),float(times[i+1]),phase)
			return lerpf(float(values[i]),float(values[i+1]),smoothstep(0,1,t))
	return float(values.back())
