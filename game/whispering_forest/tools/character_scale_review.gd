extends SceneTree

const Stage = preload("res://game/whispering_forest/art/city/render_stage.gd")
const Rig = preload("res://game/whispering_forest/art/characters/living_rig.gd")

func _initialize() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	run.call_deferred()

func block(parent: Node3D, at: Vector3, size: Vector3, color: String) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size=size
	mesh.mesh=box
	mesh.position=at
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(color)
	material.roughness=0.95
	mesh.material_override=material
	parent.add_child(mesh)

func run() -> void:
	var vp := SubViewport.new()
	vp.size=Vector2i(1920,1600)
	vp.own_world_3d=true
	vp.msaa_3d=Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Stage.new()
	vp.add_child(stage)
	stage.build()
	stage.frame_canvas(vp.size,Vector3(0,2.2,-1))
	for item in [["forge",Vector3(-5,0,-3)],["inn",Vector3(3.7,0,-5.1)]]:
		var building: Node3D=load("res://game/whispering_forest/art/city/models/"+item[0]+".tscn").instantiate()
		building.position=item[1]
		stage.add_child(building)
	block(stage,Vector3(0,-0.09,-1),Vector3(14,0.15,10),"a2b58c")
	# A one-metre ground grid uses the exact same projected axes as gameplay.
	for x in range(-7,8): block(stage,Vector3(x,0.001,-1),Vector3(0.014,0.005,10),"bcccaa")
	for z in range(-6,5): block(stage,Vector3(0,0.001,z),Vector3(14,0.005,0.014),"bcccaa")
	var door_at := Vector3(-1.4,0,2.1)
	var height: float=Stage.SETTINGS.door_metres
	for side in [-1.0,1.0]: block(stage,door_at+Vector3(side*0.76,height*0.5,0),Vector3(0.16,height,0.24),"e9d8b7")
	block(stage,door_at+Vector3(0,height+0.08,0),Vector3(1.68,0.16,0.24),"e9d8b7")
	block(stage,Vector3(2.4,0.5,2.4),Vector3.ONE,"c8c3b5")
	var rig := Rig.new()
	rig.build("mage")
	stage.add_child(rig)
	rig.position=Vector3(-1.2,0,2.9)
	rig.pose("idle",0,7)
	var display := TextureRect.new()
	display.texture=vp.get_texture()
	display.size=Vector2(1920,1600)
	root.add_child(display)
	var font: Font=load("res://game/whispering_forest/assets/NotoSansCJKsc-Regular.otf")
	for item in [[Vector2(34,20),"人物 × 城市 · 同一套三维投影与光照",28],[Vector2(34,60),"30° 正交 / 45° 方位 / 每米 32 逻辑单位 / 统一 2× 导出",17],[Vector2(34,1500),"校准件：标准人物、竖持长法杖、2.35 米门洞、1 米立方体及地面网格",18],[Vector2(34,1534),"背景使用项目现有可编辑建筑模型；本图为引擎三维校准场景直接渲染。",16]]:
		var label := Label.new()
		label.position=item[0]
		label.text=item[1]
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",item[2])
		label.add_theme_color_override("font_color",Color("f0f3de"))
		root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://game/whispering_forest/preview/character-world-calibration.png")
	print("WF_CHARACTER_SCALE_REVIEW_OK")
	quit()
