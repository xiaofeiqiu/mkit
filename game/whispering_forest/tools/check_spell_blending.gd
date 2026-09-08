extends SceneTree

const Visual = preload("res://game/whispering_forest/scripts/combat/spell_visual.gd")
const Frames = preload("res://game/whispering_forest/scripts/combat/vfx_frames.gd")
const Timing = preload("res://game/whispering_forest/scripts/combat/skill_tuning.gd")

func _initialize() -> void:
	check_blend.call_deferred()

func check_blend() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(480,480)
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var holder:=Node2D.new()
	holder.position=Vector2(220,350)
	vp.add_child(holder)
	var stone:=Visual.new()
	stone.setup("earth",Vector2.ZERO,38,1,1.95)
	stone.impact_at=0.95
	stone.variant=0.15; stone.rock_index=0
	holder.add_child(stone)
	for at_age in [0.5,0.7,1.80]:
		stone.advance(at_age-stone.age)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image:=vp.get_texture().get_image()
		var settled:=clampf((at_age-stone.impact_at)/0.30,0,1)
		var pixel: Vector2i=Vector2i(holder.position+stone.meteor_position(at_age)+Vector2(0,settled*7))
		var actual:=image.get_pixelv(pixel).a
		if absf(actual-stone.opacity())>0.035:
			push_error("WF_SPELL_BLEND_FAILED: centre alpha %.3f differs from intended %.3f" % [actual,stone.opacity()])
			quit(1); return
	stone.queue_free()
	await process_frame
	var ice:=Visual.new()
	ice.setup("ice",Vector2.ZERO,36,1,Timing.ICE_LIFE)
	holder.add_child(ice)
	# Sample solid interiors from the actual imported atlas and compare the
	# rendered alpha. Exclude AA borders and ground ripples. This catches both
	# translucent source pixels and a runtime modulation that reintroduces fade.
	var samples:=0
	for at_age in [0.42,0.65,0.94,1.29]:
		ice.advance(at_age-ice.age)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered:=vp.get_texture().get_image()
		var frame: AtlasTexture=ice.art_frames[int(ice.ice_frame())]
		var original:=frame.atlas.get_image().get_region(Rect2i(frame.region))
		var checked:=0
		for y in range(24,280,4):
			for x in range(64,320,4):
				var solid:=true
				# Check the whole neighbourhood: a diagonal fracture can cross
				# between four cardinal probes and enter the bilinear footprint.
				for dy in range(-3,4):
					for dx in range(-3,4):
						if original.get_pixel(x+dx,y+dy).a<0.995: solid=false
				if not solid: continue
				var at: Vector2=holder.position+(Vector2(x,y)-Frames.pivot("ice"))*0.5
				var actual: float=rendered.get_pixelv(Vector2i(at)).a
				if actual<0.985:
					push_error("WF_ICE_OPACITY_FAILED: solid ice at %.2fs rendered with alpha %.3f" % [at_age,actual])
					quit(1); return
				checked+=1
		if checked==0:
			push_error("WF_ICE_OPACITY_FAILED: no opaque interior in authored pose at %.2fs" % at_age)
			quit(1); return
		samples+=checked
	print("WF_ICE_OPACITY_OK: %d GPU interior samples opaque at peak and throughout fracture/removal" % samples)
	print("WF_SPELL_BLEND_OK: opaque between poses; stone fade retained; ice has no alpha fade")
	quit()
