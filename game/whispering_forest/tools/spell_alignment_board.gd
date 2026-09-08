extends SceneTree

const Frames = preload("res://game/whispering_forest/scripts/combat/vfx_frames.gd")
var sheet: Node2D

func _initialize() -> void:
	build.call_deferred()

func build() -> void:
	root.size=Vector2i(1280,760)
	root.transparent_bg=false
	root.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	sheet=Node2D.new()
	root.add_child(sheet)
	sheet.draw.connect(draw_board)
	sheet.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://game/whispering_forest/preview/ice-eight-fixed-pivot.png")
	print("WF_ICE_ALIGNMENT_BOARD_OK")
	quit()

func draw_board() -> void:
	sheet.draw_rect(Rect2(0,0,1280,760),Color("18252c"))
	var font:=ThemeDB.fallback_font
	sheet.draw_string(font,Vector2(32,42),"ICE / 8 KEY POSES / ONE FIXED GROUND ORIGIN",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("effaff"))
	sheet.draw_string(font,Vector2(32,70),"Model origin = cyan cross. Same camera, canvas, pixel density and pivot in every frame.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("9eb4be"))
	var frames:=Frames.clip("ice")
	var labels := ["01  White seal","02  Expanded seal","03  Emergence","04  Upward eruption","05  Tall peak","06  Retraction","07  Settled cone","08  Before fade"]
	for i in range(8):
		var rect:=Rect2(20+(i%4)*315,90+int(i/4)*328,300,315)
		sheet.draw_style_box(panel(),rect)
		var ground: Vector2=rect.position+Vector2(150,255)
		sheet.draw_line(ground+Vector2(-120,0),ground+Vector2(120,0),Color("35505a"),1)
		sheet.draw_line(ground+Vector2(0,-225),ground+Vector2(0,24),Color("35505a"),1)
		var scale_value:=0.75
		sheet.draw_texture_rect(frames[i],Rect2(ground-Frames.pivot("ice")*scale_value,frames[i].get_size()*scale_value),false)
		sheet.draw_line(ground-Vector2(8,0),ground+Vector2(8,0),Color("49e5d7"),2)
		sheet.draw_line(ground-Vector2(0,8),ground+Vector2(0,8),Color("49e5d7"),2)
		sheet.draw_string(font,rect.position+Vector2(14,296),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("effaff"))

func panel() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("20323b")
	style.set_corner_radius_all(8)
	return style
