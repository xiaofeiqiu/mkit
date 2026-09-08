extends SceneTree

const Rig = preload("res://game/whispering_forest/art/characters/expressive_rig.gd")
const OUT := "res://game/whispering_forest/assets/characters/performance/"
const MAGE_OUT := "res://game/whispering_forest/assets/characters/mage-v2/"
const CELL := 256

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if "--validate" in OS.get_cmdline_user_args():
		var model := Rig.new()
		model.build("mage")
		model.pose("attack",3.0/7.0,7)
		model.free()
		print("WF_PERFORMANCE_RIG_OK")
		quit()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAGE_OUT))
	var vp := SubViewport.new()
	vp.size = Vector2i(CELL,CELL)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c5d5ec")
	env.environment.ambient_light_energy = 0.58
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42,-35,0)
	light.light_color = Color("fffaf3")
	light.light_energy = 1.10
	stage.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20,140,0)
	fill.light_color = Color("9ebfe8")
	fill.light_energy = 0.32
	stage.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.2
	camera.position = Vector3(0,6.30,8.660254)
	stage.add_child(camera)
	camera.look_at(Vector3(0,1.30,0))
	camera.make_current()
	var preview_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model-preview="): preview_path = arg.trim_prefix("--model-preview=")
	for kind in ["mage","goblin","mentor"]:
		if "--mage-only" in OS.get_cmdline_user_args() and kind!="mage": continue
		var model := Rig.new()
		model.build(kind)
		stage.add_child(model)
		if not preview_path.is_empty():
			vp.size = Vector2i(768,768)
			model.pose("ready",0.13,7)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(preview_path)
			print("WF_MAGE_MODEL_PREVIEW_OK "+preview_path)
			quit()
			return
		var actions := ["idle","walk","attack","seal","hurt","death"]
		if kind=="mage": actions.append_array(["ready","cast_walk","start","stop","dodge"])
		if "--death-only" in OS.get_cmdline_user_args(): actions = ["death"]
		if "--attacks-only" in OS.get_cmdline_user_args(): actions = ["attack","cast_walk"]
		for action in actions:
			var cell := 384 if action=="death" else CELL
			if kind=="mage" and action in ["attack","cast_walk"]: cell = 320
			vp.size = Vector2i(cell,cell)
			camera.size = cell/80.0 # identical pixels per world unit; extra fall margin
			var sheet := Image.create(cell*8,cell*8,false,Image.FORMAT_RGBA8)
			for direction in range(8):
				for frame in range(8):
					var looping: bool = action in ["idle","walk","ready"]
					model.pose(action,frame/(8.0 if looping else 7.0),direction)
					await process_frame
					await process_frame
					await RenderingServer.frame_post_draw
					var rendered := vp.get_texture().get_image()
					if rendered.is_invisible():
						push_error("Empty render: "+kind+" "+action)
						quit(1)
						return
					rendered.convert(Image.FORMAT_RGBA8)
					sheet.blit_rect(rendered,Rect2i(0,0,cell,cell),Vector2i(frame*cell,direction*cell))
			var path: String = (MAGE_OUT if kind=="mage" else OUT)+kind+"-"+action+".png"
			if sheet.save_png(path)!=OK:
				quit(1)
				return
			print("WF_PERFORMANCE_BAKED "+kind+" "+action)
		stage.remove_child(model)
		model.queue_free()
	vp.queue_free()
	await process_frame
	await process_frame
	print("WF_PERFORMANCE_BAKE_OK")
	quit()
