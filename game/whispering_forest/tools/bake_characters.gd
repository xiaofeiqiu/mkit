extends SceneTree

const Rig = preload("res://game/whispering_forest/art/characters/character_rig.gd")
const CELL := 256
var viewport: SubViewport
var stage: Node3D

func _initialize() -> void:
	bake.call_deferred()

func bake() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(CELL,CELL)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("becde2")
	env.environment.ambient_light_energy = 0.65
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42,-35,0)
	light.light_color = Color("fff2dc")
	light.light_energy = 1.25
	stage.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20,140,0)
	fill.light_color = Color("99b7df")
	fill.light_energy = 0.32
	stage.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.2
	camera.position = Vector3(0,1.30+5.0,8.660254)
	stage.add_child(camera)
	camera.look_at(Vector3(0,1.30,0))
	camera.make_current()
	var preview := ""
	var actions: Array[String] = ["idle","walk","attack","seal"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			preview = arg.trim_prefix("--preview=")
		if arg.begins_with("--action="):
			actions = [arg.trim_prefix("--action=")]
	var kinds := ["mage","mentor","goblin"]
	if not preview.is_empty():
		kinds = ["mage"]
	for kind in kinds:
		var rig := Rig.new()
		rig.build(kind)
		stage.add_child(rig)
		if not preview.is_empty():
			viewport.size = Vector2i(768,768)
			rig.pose("walk",0.12,7)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(preview)
			print("WF_RIG_PREVIEW: "+preview)
		else:
			for action in actions:
				var sheet := Image.create(CELL*8,CELL*8,false,Image.FORMAT_RGBA8)
				for direction in range(8):
					for frame in range(8):
						rig.pose(action,frame/8.0,direction)
						await process_frame
						await process_frame
						await RenderingServer.frame_post_draw
						var rendered := viewport.get_texture().get_image()
						rendered.convert(Image.FORMAT_RGBA8)
						sheet.blit_rect(rendered,Rect2i(0,0,CELL,CELL),Vector2i(frame*CELL,direction*CELL))
				var path := "res://game/whispering_forest/assets/characters/%s-%s.png" % [kind,action]
				var error := sheet.save_png(path)
				if error!=OK:
					push_error("WF_BAKE_FAILED: "+path)
					quit(1)
					return
				print("WF_BAKED: %s (8 directions x 8 frames)" % path)
		stage.remove_child(rig)
		rig.queue_free()
	viewport.queue_free()
	await process_frame
	await process_frame
	print("WF_BAKE_OK")
	quit()
