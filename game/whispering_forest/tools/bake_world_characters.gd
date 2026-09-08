extends SceneTree

const Rig = preload("res://game/whispering_forest/art/characters/living_rig.gd")
const Motion = preload("res://game/whispering_forest/art/characters/motion_spec.gd")
const Stage = preload("res://game/whispering_forest/art/city/render_stage.gd")

func _initialize() -> void:
	bake.call_deferred()

func bake() -> void:
	if RenderingServer.get_current_rendering_method()!=Stage.SETTINGS.renderer:
		push_error("Use the shared renderer: --rendering-method "+str(Stage.SETTINGS.renderer))
		quit(1); return
	var vp := SubViewport.new()
	vp.size=Vector2i(256,256)
	vp.transparent_bg=true
	vp.own_world_3d=true
	vp.msaa_3d=Viewport.MSAA_4X
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage := Stage.new()
	vp.add_child(stage)
	stage.build()
	stage.frame_canvas(vp.size,Motion.TARGET)
	await process_frame
	if not stage.verify_projection():
		push_error("Character camera does not share the city's 2:1 basis")
		quit(1); return
	var requested: PackedStringArray=[]
	var selected := ""
	var preview := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--actions="): requested=arg.trim_prefix("--actions=").split(",")
		if arg.begins_with("--kind="): selected=arg.trim_prefix("--kind=")
		if arg.begins_with("--preview="): preview=arg.trim_prefix("--preview=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Motion.OUTPUT))
	var record := {"profile":Stage.profile_record(),"actors":{}}
	record.sources={}
	for path in ["living_rig.gd","mage_sculpt.gd","long_staff.gd","expressive_rig.gd","character_rig.gd","motion_spec.gd","painted_cloth.gdshader"]:
		var source_path: String="res://game/whispering_forest/art/characters/"+path
		record.sources[source_path]=FileAccess.get_sha256(source_path)
	var manifest := Motion.OUTPUT+"manifest.json"
	if FileAccess.file_exists(manifest): record.actors=JSON.parse_string(FileAccess.get_file_as_string(manifest)).actors
	for kind in ["mage","mentor","goblin"]:
		if not selected.is_empty() and selected!=kind: continue
		var rig := Rig.new()
		rig.build(kind)
		rig.scale=Vector3.ONE*Motion.model_scale(kind)
		stage.add_child(rig)
		if not preview.is_empty():
			vp.size=Vector2i(768,768)
			# Inspection enlargement only: same pose/projection as the 256 px export.
			rig.pose("idle",0,7)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(preview)
			print("WF_WORLD_CHARACTER_PREVIEW_OK")
			quit(); return
		var clips: Dictionary = Motion.clips_for(kind)
		var actor_record := {"source":"res://game/whispering_forest/art/characters/living_rig.gd","model_to_metres":Motion.model_scale(kind),"shadow":"runtime ground shadow only; self-shadows baked","directions":["S","SW","W","NW","N","NE","E","SE"],"clips":{}}
		if record.actors.has(kind): actor_record.clips=record.actors[kind].clips
		for action in clips:
			if not requested.is_empty() and action not in requested: continue
			var spec: Dictionary = clips[action]
			var cell: int = spec.cell
			var count: int = spec.frames
			vp.size=Vector2i(cell,cell)
			stage.frame_canvas(vp.size,Motion.TARGET)
			await process_frame
			var origin := stage.camera.unproject_position(Vector3.ZERO)
			if origin.distance_to(Motion.origin(cell))>0.01:
				push_error("Ground-origin mismatch")
				quit(1); return
			var sheet := Image.create(cell*count,cell*8,false,Image.FORMAT_RGBA8)
			var staff_tips: Array=[]
			for direction in range(8):
				var direction_tips: Array=[]
				for frame in range(count):
					var phase := frame/float(count if spec.loop else count-1)
					rig.pose(action,phase,direction)
					if kind!="mage": rig.rotation.y+=PI/4
					if kind=="mage":
						var tip: Vector2=stage.camera.unproject_position(rig.staff.to_global(rig.LongStaff.TIP))-origin
						direction_tips.append([tip.x,tip.y])
					await process_frame
					await process_frame
					await RenderingServer.frame_post_draw
					var rendered := vp.get_texture().get_image()
					rendered.convert(Image.FORMAT_RGBA8)
					var bounds := rendered.get_used_rect()
					if bounds.size==Vector2i.ZERO or bounds.position.x<2 or bounds.position.y<2 or bounds.end.x>cell-2 or bounds.end.y>cell-2:
						push_error("Clipped frame %s %s %d/%d: %s" % [kind,action,direction,frame,bounds])
						quit(1); return
					sheet.blit_rect(rendered,Rect2i(0,0,cell,cell),Vector2i(frame*cell,direction*cell))
				if kind=="mage": staff_tips.append(direction_tips)
			var path: String = Motion.OUTPUT+kind+"-"+action+".png"
			if sheet.save_png(path)!=OK: quit(1); return
			actor_record.clips[action]={"file":path,"cell":cell,"frames":count,"seconds":spec.seconds,"loop":spec.loop,"pivot":[origin.x,origin.y],"sha256":FileAccess.get_sha256(path)}
			if kind=="mage": actor_record.clips[action].staff_tips=staff_tips
			print("WF_WORLD_CHARACTER_BAKED %s %s %d frames" % [kind,action,count*8])
		record.actors[kind]=actor_record
		stage.remove_child(rig)
		rig.queue_free()
	var file := FileAccess.open(manifest,FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"\t")+"\n")
	file.close()
	vp.queue_free()
	await process_frame
	await process_frame
	print("WF_WORLD_CHARACTERS_OK: shared city camera/light/density, 8 real rotations, anchors and alpha verified")
	quit()
