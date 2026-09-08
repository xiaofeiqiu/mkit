extends Control

const INK := Color("eae3c8")
const MUTED := Color("aaba9e")
const GOLD := Color("dfbb75")
var world: Node
var font: Font
var title_font: Font
var locale_button: Button
var sound_button: Button
var help_button: Button
var reset_button: Button
var return_button: Button
var slot_buttons: Array[Button] = []
var travel_buttons: Array[Button] = []
var travel_close: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font = load("res://game/whispering_forest/assets/NotoSansCJKsc-Regular.otf")
	title_font = SystemFont.new()
	title_font.font_names = PackedStringArray(["Georgia","Hiragino Mincho ProN","Hiragino Sans GB"])
	title_font.fallbacks = [font]
	locale_button = button("EN / 中", func(): world.toggle_language())
	sound_button = button("♪", func(): world.toggle_sound())
	help_button = button("?", func(): world.toggle_pause())
	reset_button = button("↺", func(): world.confirm_restart())
	return_button = button("",func(): world.return_to_city())
	for i in range(5):
		var index := i
		var slot := button("", func(): world.cast_skill(index))
		slot.self_modulate = Color(1,1,1,0.01)
		slot_buttons.append(slot)
	for i in range(world.City.STATIONS.size()):
		var index := i
		var destination := button("",func(): world.travel_to(index))
		destination.visible = false
		travel_buttons.append(destination)
	travel_close = button("",func(): world.close_travel())
	travel_close.visible = false
	resized.connect(layout)
	layout()
	# Deferred because the world constructs the expedition system after this HUD.
	_add_combat_hud.call_deferred()

func _add_combat_hud() -> void:
	var overlay=preload("res://game/whispering_forest/scripts/combat/combat_hud.gd").new()
	overlay.world=world
	add_child(overlay)

func button(text_value: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text_value
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font",font)
	node.add_theme_font_size_override("font_size",16)
	node.add_theme_color_override("font_color",INK)
	node.add_theme_stylebox_override("normal",panel(Color(0.075,0.13,0.115,0.93)))
	node.add_theme_stylebox_override("hover",panel(Color(0.19,0.26,0.2,0.98)))
	node.add_theme_stylebox_override("pressed",panel(Color(0.27,0.32,0.2,0.98)))
	node.pressed.connect(callback)
	add_child(node)
	return node

func layout() -> void:
	if locale_button == null:
		return
	locale_button.position = Vector2(size.x-218,25)
	locale_button.size = Vector2(78,36)
	sound_button.position = Vector2(size.x-130,25)
	sound_button.size = Vector2(42,36)
	help_button.position = Vector2(size.x-78,25)
	help_button.size = Vector2(42,36)
	reset_button.position = Vector2(size.x-78,size.y-66)
	reset_button.size = Vector2(42,36)
	return_button.position = Vector2(size.x-354,25)
	return_button.size = Vector2(126,36)
	for i in range(5):
		slot_buttons[i].position = Vector2(size.x/2-197+i*80,size.y-100)
		slot_buttons[i].size = Vector2(70,66)
	for i in range(travel_buttons.size()):
		travel_buttons[i].position = Vector2(size.x/2-224,size.y/2-126+i*57)
		travel_buttons[i].size = Vector2(448,48)
	travel_close.position = Vector2(size.x/2-90,size.y/2+178)
	travel_close.size = Vector2(180,36)

func panel(color: Color = Color(0.075,0.13,0.115,0.91)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color(0.64,0.64,0.39,0.38)
	box.set_border_width_all(1)
	box.set_corner_radius_all(7)
	box.shadow_color = Color(0.015,0.04,0.03,0.2)
	box.shadow_size = 8
	return box

func label_at(at: Vector2, value: String, size_value: int = 16, color: Color = INK, use_title: bool = false) -> void:
	draw_string(title_font if use_title else font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func centered(at: Vector2, value: String, size_value: int = 16, color: Color = INK, use_title: bool = false) -> void:
	var f := title_font if use_title else font
	var width := f.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x
	draw_string(f,at-Vector2(width*0.5,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func _process(_delta: float) -> void:
	return_button.visible = world.area=="dungeon"
	return_button.text = world.say("B  返回城内","B  Return to city")
	for i in range(travel_buttons.size()):
		var station: Dictionary = world.City.STATIONS[i]
		travel_buttons[i].visible = world.travel_open
		travel_buttons[i].disabled = i==world.travel_origin
		travel_buttons[i].tooltip_text = world.say(station.note_zh,station.note_en)
		travel_buttons[i].text = "%d   %s%s" % [i+1,world.say(station.zh,station.en),world.say(" · 当前位置"," · You are here") if i==world.travel_origin else ""]
	travel_close.visible = world.travel_open
	travel_close.text = world.say("Esc  关闭","Esc  Close")
	reset_button.disabled = world.travel_open
	queue_redraw()

func _draw() -> void:
	if world == null or world.player == null or font == null:
		return
	var w := size.x
	var h := size.y
	for i in range(65):
		draw_rect(Rect2(0,h-130+i*2,w,2),Color(0.045,0.09,0.06,0.48*float(i)/65))
	# Portrait / status. Keep the world visible around small, anchored panels.
	draw_style_box(panel(),Rect2(26,25,300,114))
	draw_circle(Vector2(70,69),28,Color("354d40"))
	draw_arc(Vector2(70,69),29,0,TAU,64,GOLD,1,true)
	var portrait: Texture2D = world.portrait_texture()
	draw_texture_rect(portrait,Rect2(43,37,54,64),false)
	label_at(Vector2(112,52),world.say("见习法师","APPRENTICE MAGE"),16,GOLD)
	label_at(Vector2(112,73),world.say("异界旅人 · 晨铃城","Summoned traveler"),13,MUTED)
	draw_style_box(world.bar_style(Color("253b31")),Rect2(112,85,189,8))
	draw_style_box(world.bar_style(Color("b87a63")),Rect2(112,85,189*world.player.health.current_hp/world.player.health.get_max_hp(),8))
	label_at(Vector2(112,116),"HP  %d / %d" % [world.player.health.current_hp,world.player.health.get_max_hp()],12,INK)
	label_at(Vector2(237,116),"LV  01",12,MUTED)
	draw_style_box(panel(Color(0.055,0.12,0.08,0.70)),Rect2(w/2-178,16,356,96))
	centered(Vector2(w/2,39),"W H I S P E R I N G   F O R E S T",12,GOLD)
	centered(Vector2(w/2,74),world.district_name() if world.area=="city" else world.say("哥布林试炼","Goblin Trial"),26,INK,true)
	centered(Vector2(w/2,97),world.say("晨铃城  /  安全区域","BELLWAKE CITY  /  SAFE AREA") if world.area=="city" else world.say("独立任务副本  /  完成后返回城内","QUEST INSTANCE  /  RETURN AFTER THE TRIAL"),11,MUTED)
	# Quest notebook.
	draw_style_box(panel(),Rect2(w-304,86,268,195 if world.stage==3 and world.area=="dungeon" else 150))
	label_at(Vector2(w-284,112),world.say("旅途手记","FIELD NOTES"),12,GOLD)
	draw_line(Vector2(w-284,124),Vector2(w-56,124),Color(0.65,0.67,0.42,0.25),1)
	var titles := [world.say("一顶哥布林帽子","A Goblin's Hat"),world.say("一顶哥布林帽子","A Goblin's Hat"),world.say("带着帽子回来","Return with the hat"),world.say("四元素 · 练习场","The Four Elements")]
	label_at(Vector2(w-284,149),titles[world.stage],18,INK,true)
	var lines: Array
	match world.stage:
		0: lines = [world.say("你被召唤到了晨铃城","You were summoned to Bellwake."),world.say("与梅尔交谈，接取副本任务","Speak to Mel for a quest instance.")]
		1: lines = [world.say("击败戴帽子的哥布林","Defeat the hat-wearing goblin."),world.say("自动普攻 · 留意红色预警","Auto attack · avoid red circles.")]
		2: lines = [world.say("已获得：哥布林的帽子 1 / 1","Goblin hat collected  1 / 1"),world.say("E / B 回城，找梅尔交任务","E / B to city; turn in to Mel.") if world.area=="dungeon" else world.say("返回梅尔身旁，按 E 交付","Return to Mel and press E.")]
		_: lines = [world.say("击中与击杀敌人收集怒气","Hits and kills gather rage."),world.say("怒气满后，按 Q 结印召唤陨石","At full rage, press Q for Meteor.")]
	if world.area=="city" and world.stage in [1,3]:
		lines = [world.say("在城内与梅尔交谈","Speak to Mel in the city."),world.say("接取后传送进入独立副本","Teleport into a separate instance.")]
	label_at(Vector2(w-284,178),lines[0],12,MUTED)
	label_at(Vector2(w-284,204),lines[1],12,MUTED)
	if world.stage == 3 and world.area=="dungeon":
		label_at(Vector2(w-284,266),world.say("第 %d / 5 波   %s   击败 %d" % [world.wave,world.expedition.timer_text(),world.kills],"WAVE %d / 5   %s   KILLS %d" % [world.wave,world.expedition.timer_text(),world.kills]),12,GOLD)
	# Ability tray, drawn independently of the transparent clickable controls.
	draw_style_box(panel(),Rect2(w/2-217,h-148,434,131))
	var rage_color := Color("e8b65b") if world.rage >= 100 else Color("b59561")
	draw_style_box(world.bar_style(Color("2b4033")),Rect2(w/2-194,h-118,387,5))
	draw_style_box(world.bar_style(rage_color),Rect2(w/2-194,h-118,387*world.rage/100,5))
	centered(Vector2(w/2,h-130),world.say("怒气  %d / 100" % world.rage,"RAGE  %d / 100" % world.rage),12,rage_color)
	var names := [world.say("火爆术","Flame Burst"),world.say("龙卷风","Tornado"),world.say("陨石术","Rockfall"),world.say("冰冻术","Ice Pillars"),world.say("火陨石","Meteor")]
	var colors := [Color("efaa65"),Color("a8d8b5"),Color("ccbb80"),Color("8dbacc"),Color("e5b967")]
	for i in range(5):
		var p := Vector2(w/2-197+i*80,h-100)
		var disabled: bool = world.area=="city" or world.stage < 3 or (i == 4 and world.rage < 100)
		draw_style_box(panel(Color("20392e") if not disabled else Color("213329")),Rect2(p,Vector2(70,66)))
		var color: Color = colors[i]
		if disabled:
			color = color.darkened(0.5)
		skill_icon(p+Vector2(35,23),i,color)
		centered(p+Vector2(35,58),names[i],10,MUTED if disabled else INK)
		label_at(p+Vector2(5,13),str(i+1) if i<4 else "Q",10,GOLD)
		if i<4: label_at(p+Vector2(43,13),"L%d" % world.spells.levels[i],9,MUTED)
		if world.skill_cooldowns[i] > 0:
			draw_style_box(panel(Color(0.05,0.1,0.07,0.73)),Rect2(p,Vector2(70,66)))
			centered(p+Vector2(35,37),"%.1f" % world.skill_cooldowns[i],20,INK)
		if world.stage < 3:
			centered(p+Vector2(35,-8),world.say("试炼后开放","LOCKED"),9,MUTED)
	draw_style_box(panel(Color(0.055,0.12,0.08,0.82)),Rect2(24,h-89,369,70))
	draw_style_box(panel(Color(0.055,0.12,0.08,0.82)),Rect2(w-329,h-89,229,70))
	label_at(Vector2(38,h-61),world.say("WASD  移动     Shift  闪避     E  互动","WASD  Move     Shift  Dodge     E  Interact"),13,INK)
	label_at(Vector2(38,h-38),world.say("空格 / 点击  普攻     F  自动攻击","Space / Click  Attack     F  Auto attack"),11,MUTED)
	label_at(Vector2(w-297,h-61),world.say("安全城镇 · 城内没有敌人","SAFE CITY · NO ENEMIES") if world.area=="city" else world.say("自动攻击：开" if world.auto_attack else "自动攻击：关","AUTO ATTACK: ON" if world.auto_attack else "AUTO ATTACK: OFF"),11,GOLD)
	label_at(Vector2(w-297,h-38),world.say("滚轮  缩放  ·  Esc  帮助 / 暂停","Wheel  Zoom  ·  Esc  Help / pause"),10,MUTED)
	if world.toast_timer > 0:
		var text_value: String = world.say(world.toast_zh,world.toast_en)
		var tw := font.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
		draw_style_box(panel(Color(0.12,0.2,0.14,0.96)),Rect2(w/2-tw/2-24,156,tw+48,43))
		centered(Vector2(w/2,183),text_value,15,GOLD)
	if is_instance_valid(world.mentor) and world.player.ground.distance_to(world.mentor.ground) < 65 and world.dialogue.is_empty():
		var screen: Vector2 = world.mentor.get_global_transform_with_canvas().origin
		centered(screen+Vector2(0,27),world.say("E  ·  导师 梅尔","E  ·  Mel, mentor"),13,GOLD)
	if world.area=="dungeon" and (world.stage==2 or world.player.ground.distance_to(world.DUNGEON_START)<70):
		centered(Vector2(w/2,h-166),world.say("E / B  ·  返回晨铃城","E / B  ·  Return to Bellwake"),13,INK)
	if world.area=="city" and world.dialogue.is_empty() and not world.travel_open:
		var nearby: int = world.City.station_near(world.player.ground,75)
		if nearby>=0:
			centered(Vector2(w/2,h-170),world.say("E  ·  使用传送石","E  ·  Use waystone"),15,INK)
		for i in range(world.waystones.size()):
			var at: Vector2 = world.waystones[i].get_global_transform_with_canvas().origin
			if at.x>36 and at.x<w-36 and at.y>160 and at.y<h-165:
				var station: Dictionary = world.City.STATIONS[i]
				centered(at+Vector2(0,23),world.say(station.zh,station.en),12,Color("dbf0e7"))
	if not world.dialogue.is_empty():
		draw_style_box(panel(Color(0.06,0.12,0.09,0.98)),Rect2(w/2-345,h/2+55,690,166))
		label_at(Vector2(w/2-315,h/2+86),world.say("梅尔 · 召唤引导者","MEL · SUMMONING GUIDE"),13,GOLD)
		var entry: Array = world.dialogue[world.dialogue_index]
		var text_value: String = world.say(entry[0],entry[1])
		draw_multiline_string(font,Vector2(w/2-315,h/2+121),text_value,HORIZONTAL_ALIGNMENT_LEFT,630,17,-1,INK)
		label_at(Vector2(w/2+172,h/2+198),world.say("E / 空格  继续","E / Space  Continue"),12,MUTED)
	if world.paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.07,0.045,0.62))
		draw_style_box(panel(Color("172e24")),Rect2(w/2-292,h/2-190,584,376))
		centered(Vector2(w/2,h/2-145),world.say("在钟声之间，歇一会儿","Rest between the bells"),26,INK,true)
		var help_lines := [world.say("WASD / 方向键移动；右键点击地面也可移动。","WASD / Arrows to move; right-click the ground to walk."),world.say("靠近导师按 E。普攻自动瞄准附近敌人。","Press E near the mentor. Auto attacks target nearby foes."),world.say("Shift 闪避红圈。试炼后，1–4 使用四元素技能。","Shift dodges red circles. After the trial, 1–4 cast elements."),world.say("战斗收集怒气；100 怒气时，Q 结印召唤火陨石。","Collect 100 rage in combat, then Q summons a fire meteor."),world.say("L 切换中英。M 静音。进度会自动保存。","L switches language. M mutes. Progress saves automatically."),world.say("晨铃城内安全；接取委托后前往独立副本。","Bellwake is safe. Accept a quest to enter its instance.")]
		for i in range(help_lines.size()):
			centered(Vector2(w/2,h/2-92+i*34),help_lines[i],13,MUTED)
		centered(Vector2(w/2,h/2+151),world.say("Esc / E  继续  ·  副本中 B 回城","Esc / E  Resume  ·  B exits an instance"),15,GOLD)
	if world.travel_open:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.07,0.045,0.68))
		draw_style_box(panel(Color("172e2a")),Rect2(w/2-260,h/2-228,520,456))
		centered(Vector2(w/2,h/2-187),world.say("晨铃城 · 传送石","BELLWAKE · WAYSTONES"),24,INK,true)
		centered(Vector2(w/2,h/2-157),world.say("选择目的地 · 免费城内传送","Choose a destination · free travel within the city"),13,MUTED)
		centered(Vector2(w/2,h/2+170),world.say("点击地点或按 1–5 · 任务副本请找梅尔","Click or press 1–5 · Speak to Mel for quest instances"),11,MUTED)

func skill_icon(at: Vector2, index: int, color: Color) -> void:
	match index:
		0,4:
			draw_colored_polygon(PackedVector2Array([at+Vector2(-10,9),at+Vector2(-13,-2),at+Vector2(-3,-17),at+Vector2(0,-5),at+Vector2(8,-13),at+Vector2(12,2),at+Vector2(7,12),at+Vector2(-4,13)]),color)
			draw_colored_polygon(PackedVector2Array([at+Vector2(-4,9),at+Vector2(0,-5),at+Vector2(5,7)]),Color("f3dfab") if color.v>0.5 else color)
			if index == 4:
				draw_arc(at,21,0,TAU,40,color,1,true)
		1:
			for y in [-7,0,7]:
				draw_line(at+Vector2(-14,y),at+Vector2(10,y-5),color,2,true)
				draw_arc(at+Vector2(9,y-8),4,-PI/2,PI/2,14,color,2,true)
		2:
			draw_colored_polygon(PackedVector2Array([at+Vector2(-16,11),at+Vector2(-5,-11),at+Vector2(2,0),at+Vector2(9,-16),at+Vector2(17,11)]),color)
		3:
			draw_colored_polygon(PackedVector2Array([at+Vector2(0,-18),at+Vector2(-11,0),at+Vector2(-11,8),at+Vector2(-4,14),at+Vector2(5,14),at+Vector2(12,7),at+Vector2(10,-2)]),color)
			draw_arc(at+Vector2(1,3),6,0.2,2.7,16,color.lightened(0.3),1.4,true)
