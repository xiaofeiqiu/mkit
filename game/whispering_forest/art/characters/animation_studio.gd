extends Node2D

const Frames = preload("res://game/whispering_forest/scripts/combat/performance_frames.gd")
const KINDS := ["mage","mentor","goblin"]
const ACTIONS := ["idle","walk","run","look","attack","seal"]
var kind := 0
var action := 1
var language := "zh"
var clock := 0.0
var elapsed := 0.0
var paused := false
var movie := false
var capture_path := ""
var font: Font
var sprites: Array[Sprite2D] = []
var controls: Array[Button] = []
var clips: Dictionary

func text(zh: String, en: String) -> String:
	return zh if language=="zh" else en

func _ready() -> void:
	DisplayServer.window_set_title("Whispering Forest · 八方向人物动画")
	font = load("res://game/whispering_forest/assets/NotoSansCJKsc-Regular.otf")
	for arg in OS.get_cmdline_user_args():
		if arg=="--studio-movie":
			movie = true
		if arg.begins_with("--studio-capture="):
			capture_path = arg.trim_prefix("--studio-capture=")
	for i in range(8):
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.offset = -Frames.pivot_for("idle")
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.material = Frames.outline()
		sprite.position = anchor(i)
		add_child(sprite)
		sprites.append(sprite)
	for i in range(3):
		var index := i
		add_button(Vector2(43+i*139,627),132,func(): select(index,action))
	for i in range(6):
		var index := i
		add_button(Vector2(470+i*105,627),99,func(): select(kind,index))
	add_button(Vector2(1108,627),126,func(): language="en" if language=="zh" else "zh")
	select(0,0)
	if not capture_path.is_empty():
		await get_tree().create_timer(0.65).timeout
		set_process(false)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_path)
		print("WF_ANIMATION_CAPTURE: "+capture_path)
		get_tree().quit()

func anchor(index: int) -> Vector2:
	return Vector2(169+(index%4)*314,282+(index/4)*270)

func add_button(at: Vector2, width: float, callback: Callable) -> void:
	var button := Button.new()
	button.position = at
	button.size = Vector2(width,38)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font",font)
	button.add_theme_font_size_override("font_size",15)
	button.pressed.connect(callback)
	add_child(button)
	controls.append(button)

func select(actor_index: int, action_index: int) -> void:
	kind = actor_index
	action = action_index
	clock = 0
	clips = Frames.for_kind(KINDS[kind])
	if not clips.has(ACTIONS[action]): action=1
	if KINDS[kind]=="mentor": action=0
	for sprite in sprites:
		sprite.scale = Vector2.ONE # shared 2x inspection zoom, all model sizes preserved

func _process(delta: float) -> void:
	elapsed += delta
	if movie:
		var next_kind := 0 if elapsed<15 else (1 if elapsed<18 else 2)
		var next_action := 0 if elapsed<3.2 or next_kind==1 else (3 if elapsed<5.2 else (1 if elapsed<8.4 or elapsed>=15 else (2 if elapsed<11.5 else (4 if elapsed<13.2 else 5))))
		if next_kind!=kind or next_action!=action:
			select(next_kind,next_action)
		if elapsed>=21:
			print("WF_ANIMATION_MOVIE_OK: 8 directions, idle, walk, attack, seal, 3 characters")
			get_tree().quit()
	if not paused:
		clock += delta
	var spec: Dictionary = Frames.Motion.clips_for(KINDS[kind])[ACTIONS[action]]
	var cycle: float = spec.seconds
	var phase := fposmod(clock/cycle,1.0)
	var frame := mini(int(phase*int(spec.frames)),int(spec.frames)-1)
	if KINDS[kind]=="mentor": frame=0
	for i in range(8):
		sprites[i].texture = clips[ACTIONS[action]][i][frame]
		sprites[i].offset = -Frames.pivot_for(ACTIONS[action],KINDS[kind])
	var kind_names := [text("玩家法师","Mage"),text("导师梅尔","Mel"),text("哥布林","Goblin")]
	var action_names := [text("待机","Idle"),text("慢走","Walk"),text("轻跑","Run"),text("观察","Look"),text("攻击","Attack"),text("结印","Seal")]
	for i in range(3):
		controls[i].text = ("● " if i==kind else "")+kind_names[i]
	for i in range(6):
		controls[3+i].text = ("● " if i==action else "")+action_names[i]
		controls[3+i].disabled = not clips.has(ACTIONS[i]) or (KINDS[kind]=="mentor" and i!=0)
	controls[9].text = "EN / 中文"
	queue_redraw()

func label(at: Vector2, value: String, size: int, color: Color) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
	if font==null:
		return
	draw_rect(Rect2(0,0,1280,720),Color("e8ede6"))
	draw_rect(Rect2(0,0,1280,94),Color("243f43"))
	label(Vector2(43,39),text("八方向 · 人物动作审阅","EIGHT DIRECTIONS · CHARACTER MOTION REVIEW"),27,Color("f5edda"))
	label(Vector2(43,70),text("共用城市 30° 正交相机与光照 · 固定世界比例 · 待机、慢走与轻跑","Shared city camera and lighting · fixed world scale · breathing, walking and running"),14,Color("bfd7d3"))
	var names := [text("南 · 正面","S · Front"),text("西南","SW"),text("西 · 侧面","W · Side"),text("西北","NW"),text("北 · 背面","N · Back"),text("东北","NE"),text("东 · 侧面","E · Side"),text("东南","SE")]
	for i in range(8):
		var at := anchor(i)
		draw_style_box(card(),Rect2(at-Vector2(143,172),Vector2(286,245)))
		draw_colored_polygon(PackedVector2Array([at+Vector2(-86,0),at+Vector2(0,-43),at+Vector2(86,0),at+Vector2(0,43)]),Color("d6dfcd"))
		draw_set_transform(at,0,Vector2(1,0.35))
		draw_circle(Vector2.ZERO,27,Color(0.12,0.20,0.18,0.18))
		draw_set_transform(Vector2.ZERO)
		label(at+Vector2(-font.get_string_size(names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,16).x/2,60),names[i],16,Color("345251"))
	label(Vector2(43,699),text("1–6 切换动作 · Tab 换人物 · 空格 暂停 · L 中英 · Esc 退出","1–6 Action · Tab Character · Space Pause · L Language · Esc Exit"),14,Color("476164"))

func card() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4f4eb")
	style.border_color = Color("ccd6c9")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: get_tree().quit()
			KEY_SPACE: paused = not paused
			KEY_TAB: select((kind+1)%3,action)
			KEY_L: language = "en" if language=="zh" else "zh"
			KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6: select(kind,event.physical_keycode-KEY_1)
