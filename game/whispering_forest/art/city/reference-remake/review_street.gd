extends SceneTree

# Real gameplay layout, swapped only inside this review process. No save file
# or active runtime registry is changed during staged visual review.
const PACK := "res://game/whispering_forest/assets/city-reference-remake/"
const OUT := "res://game/whispering_forest/art/city/reference-remake/review/"
var frames: Dictionary
var textures := {}

func _initialize() -> void:
	review.call_deferred()

func texture(id: String) -> Texture2D:
	if not textures.has(id):textures[id]=ImageTexture.create_from_image(Image.load_from_file(PACK+id+".png"))
	return textures[id]

func sprite_for(id: String) -> Sprite2D:
	var s := Sprite2D.new()
	var f: Dictionary=frames[id]
	s.texture=texture(id)
	s.centered=false
	s.offset=-Vector2(f.pivot[0],f.pivot[1])
	s.scale=Vector2.ONE*f.scale
	s.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	return s

func replace_art(node: Node) -> void:
	var id=node.get("asset")
	if id is String and frames.has(id):
		for child in node.get_children():
			if child is Sprite2D:child.hide()
		node.add_child(sprite_for(id))
	if node.name=="RaisedCurbsAndRoundedCorners":
		node.hide()
		var curbs := Node2D.new()
		curbs.z_index=-7
		node.get_parent().add_child(curbs)
		for placement in node.placements:
			var s := sprite_for(placement.asset)
			s.position=WFIso.project(placement.at)
			curbs.add_child(s)
	if node.get_script()!=null and node.get_script().resource_path.ends_with("city_shadows.gd"):
		node.silhouettes.clear()
		for prop in node.get_parent().get_children():
			var asset=prop.get("asset")
			if not asset is String or not frames.has(asset):continue
			var points := PackedVector2Array()
			for p in frames[asset].shadow_outline:points.append(WFIso.project(prop.ground+Vector2(p[0],p[1])))
			if points.size()>2:node.silhouettes.append(points)
		node.queue_redraw()
	for child in node.get_children():
		if not child is Sprite2D:replace_art(child)

func review() -> void:
	var live := "--live" in OS.get_cmdline_user_args()
	frames=JSON.parse_string(FileAccess.get_file_as_string(PACK+"frames.json"))
	root.size=Vector2i(1440,900)
	change_scene_to_file("res://game/whispering_forest/bootstrap.tscn")
	for i in range(12):await process_frame
	var world=root.find_child("BellwakeVillage",true,false)
	if world==null:push_error("Missing actual game world");quit(1);return
	world.simulation=true
	world.dialogue.clear()
	world.arrival_glow=0
	world.hud.hide()
	world.effects.hide()
	if not live:replace_art(world.sorted_world)
	for shot in [
		["overview",Vector2(0,0),0.42],
		["guild",Vector2(0,-210),1.10],
		["market",Vector2(-540,120),1.10],
		["inn",Vector2(390,-245),1.10],
		["gate",Vector2(-830,40),1.10]
	]:
		world.player.ground=Vector2(-60,60) if shot[0] in ["overview","guild"] else Vector2(-535,40) if shot[0]=="market" else Vector2(-795,40)
		world.player.position=WFIso.project(world.player.ground)
		world.player.step(0.016)
		world.camera.position=WFIso.project(shot[1])+Vector2(0,-95)
		world.camera.zoom=Vector2.ONE*shot[2]
		world.camera.offset=Vector2.ZERO
		for i in range(4):await process_frame
		await RenderingServer.frame_post_draw
		var output: String=("res://game/whispering_forest/preview/city-daylight-" if live else OUT)+shot[0]+".png"
		root.get_texture().get_image().save_png(output)
		print("WF_REFERENCE_STREET_CAPTURE ",shot[0])
	quit()
