extends SceneTree

class Board:
	extends Node2D
	var previous: Texture2D
	var revised: Texture2D
	var font: Font
	func label(at: Vector2, value: String, size: int, color: Color = Color("264b53")) -> void:
		draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
	func actor(texture: Texture2D, anchor: Vector2, scale_value: float) -> void:
		draw_set_transform(anchor,0,Vector2(1,0.33))
		draw_circle(Vector2.ZERO,scale_value*20,Color(0.1,0.20,0.21,0.14))
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect_region(texture,Rect2(anchor-Vector2(128,218)*scale_value,Vector2.ONE*256*scale_value),Rect2(0,7*256,256,256))
	func _draw() -> void:
		draw_rect(Rect2(0,0,1200,800),Color("e8efeb"))
		draw_rect(Rect2(0,0,1200,94),Color("203e49"))
		label(Vector2(42,42),"玩家模型重做 · 前后对比",28,Color("f4ecd9"))
		label(Vector2(43,73),"MODEL REVISION · same camera, pose and scale",16,Color("c3d9d7"))
		for x in [34,622]:
			draw_style_box(card(),Rect2(x,112,544,553))
		label(Vector2(62,153),"上一版",22)
		label(Vector2(650,153),"新版 · 晶石魔杖",22)
		label(Vector2(62,179),"PREVIOUS MODEL",13,Color("6d7b7d"))
		label(Vector2(650,179),"REBUILT MESH · AETHER WAND",13,Color("547677"))
		actor(previous,Vector2(298,635),1.93)
		actor(revised,Vector2(875,635),1.93)
		actor(previous,Vector2(114,770),72.0/216.0)
		actor(revised,Vector2(208,770),72.0/216.0)
		label(Vector2(270,710),"重新制作：脸型、眼睛、成束头发、披肩、短袍与握杖手",18)
		label(Vector2(270,742),"魔杖：缠绕握柄 · 弯曲杖身 · 金属爪座 · 切面晶石",18)
		label(Vector2(270,774),"左下为游戏显示尺寸；全部八方向动作使用同一个新模型。",15,Color("627b79"))
	func card() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f8faf5")
		style.set_corner_radius_all(12)
		style.border_color = Color("cfdbd5")
		style.set_border_width_all(1)
		return style

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1200,800)
	root.content_scale_size = Vector2i(1200,800)
	var board := Board.new()
	board.font = load("res://game/whispering_forest/assets/NotoSansCJKsc-Regular.otf")
	board.previous = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://game/whispering_forest/assets/characters/performance/mage-idle.png")))
	board.revised = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://game/whispering_forest/assets/characters/mage-v2/mage-idle.png")))
	root.add_child(board)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://game/whispering_forest/preview/mage-model-v2-comparison.png")
	print("WF_MAGE_COMPARISON_OK")
	quit()
