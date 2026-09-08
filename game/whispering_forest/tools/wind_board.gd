extends SceneTree

const Frames = preload("res://game/whispering_forest/scripts/combat/vfx_frames.gd")
var board: Node2D

func _initialize() -> void:
	build.call_deferred()

func build() -> void:
	root.size=Vector2i(1280,720)
	root.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	board=Node2D.new()
	root.add_child(board)
	board.draw.connect(draw_board)
	board.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://game/whispering_forest/preview/wind-eight-v4.png")
	print("WF_WIND_BOARD_OK")
	quit()

func draw_board() -> void:
	board.draw_rect(Rect2(0,0,1280,720),Color("20343c"))
	var font:=ThemeDB.fallback_font
	board.draw_string(font,Vector2(30,40),"TORNADO / 8 POSES / 8 FPS / FIXED GROUND ORIGIN",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color.WHITE)
	board.draw_string(font,Vector2(30,70),"Broad curved wind bands, open gaps, same model and canvas. Cross = ground anchor.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b8d6d9"))
	var frames:=Frames.clip("wind")
	for i in range(8):
		var at:=Vector2(165+(i%4)*315,340+int(i/4)*305)
		var scale_value:=1.0
		board.draw_line(at+Vector2(-120,0),at+Vector2(120,0),Color("52737b"),1)
		board.draw_texture_rect(frames[i],Rect2(at-Frames.pivot("wind")*scale_value,frames[i].get_size()*scale_value),false)
		board.draw_line(at-Vector2(7,0),at+Vector2(7,0),Color("49e5d7"),2)
		board.draw_line(at-Vector2(0,7),at+Vector2(0,7),Color("49e5d7"),2)
		board.draw_string(font,at+Vector2(-117,25),"%02d  /  %.3f s" % [i+1,i*0.125],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
