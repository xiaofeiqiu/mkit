extends SceneTree

const Rig = preload("res://game/whispering_forest/art/characters/living_rig.gd")
const Motion = preload("res://game/whispering_forest/art/characters/motion_spec.gd")
var failures: Array[String]=[]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size=Vector2i(256,256)
	root.add_child(viewport)
	var stage := Motion.STAGE.new()
	viewport.add_child(stage)
	stage.build()
	stage.frame_canvas(viewport.size,Motion.TARGET)
	var rig := Rig.new()
	rig.build("mage")
	stage.add_child(rig)
	await process_frame
	if not stage.verify_projection(): failures.append("The scene basis is not 2:1")
	var origin := stage.camera.unproject_position(Vector3.ZERO)
	if origin.distance_to(Motion.origin(256))>0.01: failures.append("Baked and runtime ground origins differ")
	var worst := 0.0
	var stance_slide := 0.0
	var staff_tilt := 0.0
	var lowest_staff := 100.0
	var neutral: Array[Vector3]=[]
	for action in ["idle","look","walk","run"]:
		var stance_z := NAN
		for frame in range(160):
			var phase := frame/160.0
			rig.pose(action,phase,0)
			for i in range(2):
				var at: Vector3=rig.global_transform.affine_inverse()*rig.ankles[i].global_position
				worst=maxf(worst,at.distance_to(rig.contact_targets[i]))
				if action=="idle":
					if frame==0: neutral.append(at)
					elif at.distance_to(neutral[i])>0.002: failures.append("Idle slides a planted foot")
			if action in ["walk","run"] and rig.contact_planted[0]:
				var at: Vector3=rig.global_transform.affine_inverse()*rig.ankles[0].global_position
				var z: float=at.z+phase*(Motion.RUN_STRIDE if action=="run" else Motion.WALK_STRIDE)
				if is_nan(stance_z): stance_z=z
				stance_slide=maxf(stance_slide,absf(z-stance_z))
	if worst>0.006: failures.append("Two-link foot reach error: %.6f model units" % worst)
	if stance_slide>0.003: failures.append("Stance foot slides in world space: %.6f" % stance_slide)
	# Measure the visible head at game density, including torso rotation. Foot IK
	# alone cannot catch a body that vibrates above correctly planted feet.
	var head_range := 0.0
	var head_step := 0.0
	var fourth_harmonic := 0.0
	for action in ["walk","run"]:
		for direction in range(8):
			var heights: Array[float]=[]
			for frame in range(160):
				rig.pose(action,frame/160.0,direction)
				heights.append(stage.camera.unproject_position(rig.head.global_position).y/Motion.STAGE.SUPERSAMPLE)
			head_range=maxf(head_range,heights.max()-heights.min())
			var sine := 0.0
			var cosine := 0.0
			for frame in range(160):
				var angle := frame/160.0*TAU*4
				sine+=heights[frame]*sin(angle)
				cosine+=heights[frame]*cos(angle)
				if frame%10==0:
					head_step=maxf(head_step,absf(heights[(frame+10)%160]-heights[frame]))
			fourth_harmonic=maxf(fourth_harmonic,2.0*Vector2(sine,cosine).length()/160)
	print("WF_HEAD_STABILITY: range %.3f px; adjacent baked frame %.3f px; extra 4x bob %.3f px at game density" % [head_range,head_step,fourth_harmonic])
	if head_range>1.5: failures.append("Locomotion head bounce exceeds 1.5 game pixels")
	if head_step>0.65: failures.append("Locomotion head jumps more than 0.65 pixels between baked frames")
	if fourth_harmonic>0.10: failures.append("Extra high-frequency body bob above 0.10 pixels")
	for action in ["idle","look","walk","run","attack","cast_walk","ready"]:
		for frame in range(160):
			rig.pose(action,frame/159.0,0)
			var up: Vector3=rig.staff.global_basis.y.normalized()
			staff_tilt=maxf(staff_tilt,rad_to_deg(up.angle_to(Vector3.UP)))
			lowest_staff=minf(lowest_staff,rig.staff.to_global(rig.LongStaff.FOOT).y)
	if staff_tilt>3.0: failures.append("Staff is not upright: %.2f degrees" % staff_tilt)
	if lowest_staff< -0.015: failures.append("Staff penetrates the floor: %.5f metres" % lowest_staff)
	# Every facing must aim down the same screen ray used by runtime input.
	for direction in range(8):
		rig.pose("idle",0,direction)
		var forward: Vector3=rig.global_basis*Vector3.BACK
		var ray := stage.camera.unproject_position(forward)-origin
		var expected := Vector2(-sin(direction*PI/4),cos(direction*PI/4))
		if ray.normalized().dot(expected)<0.99999: failures.append("Facing does not agree with world projection: %d" % direction)
	if failures.is_empty(): print("WF_MOTION_GEOMETRY_OK: 640 foot poses + 1120 staff poses; 8 facing rays; shared 2:1 camera; IK error %.6f; stance slide %.6f; staff tilt %.2f degrees; floor clearance %.4f metres" % [worst,stance_slide,staff_tilt,lowest_staff])
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
