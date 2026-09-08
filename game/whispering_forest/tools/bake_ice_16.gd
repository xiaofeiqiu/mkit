extends SceneTree

const Model = preload("res://game/whispering_forest/art/combat/ice_spear_16.gd")
const Stage = preload("res://game/whispering_forest/art/city/render_stage.gd")
const OUT := "res://game/whispering_forest/art/combat/ice-16/base/"
const CELL := 384

func _initialize() -> void: bake.call_deferred()

func bake() -> void:
	if RenderingServer.get_current_rendering_method()!=Stage.SETTINGS.renderer:
		push_error("Ice export requires the shared forward_plus renderer"); quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var vp:=SubViewport.new()
	vp.size=Vector2i(CELL,CELL); vp.transparent_bg=true; vp.own_world_3d=true
	vp.msaa_3d=Viewport.MSAA_4X
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage:=Stage.new()
	vp.add_child(stage); stage.build()
	stage.frame_canvas(vp.size,Vector3(0,1.35,0))
	var model:=Model.new()
	stage.add_child(model); model.build()
	await process_frame
	if not stage.verify_projection(): quit(1); return
	var pivot: Vector2=stage.camera.unproject_position(Vector3.ZERO)
	for i in range(16):
		model.pose(i)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img:=vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var box:=img.get_used_rect()
		if box.has_area() and (box.position.x<2 or box.position.y<2 or box.end.x>CELL-2 or box.end.y>CELL-2):
			push_error("Ice pose clipped: "+str(i)); quit(1); return
		if img.save_png(OUT+"ice-%02d.png" % i)!=OK: quit(1); return
	var spec: Dictionary={"frames":16,"cell":CELL,"pivot":[pivot.x,pivot.y],"times":Model.TIMES,"duration_seconds":Model.Motion.LIFE,"heights_metres":Model.REVEAL,"peak_frame":Model.Motion.PEAK_FRAME,"runtime_scale":1.0/Stage.SUPERSAMPLE,"profile":Stage.profile_record(),"sources":{}}
	for path in ["res://game/whispering_forest/art/combat/ice_spear_16.gd","res://game/whispering_forest/art/combat/ice_motion.gd","res://game/whispering_forest/art/combat/ice_emerge.gdshader","res://game/whispering_forest/tools/bake_ice_16.gd"]:
		spec.sources[path]=FileAccess.get_sha256(path)
	var file:=FileAccess.open(OUT+"projection.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(spec,"\t")+"\n"); file.close()
	print("WF_ICE_BASE_OK: 16 emergence poses; fixed full-sized mesh, projected ground root "+str(pivot))
	quit()
