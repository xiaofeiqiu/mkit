extends Control

var world: Node
var cards: Array[Button] = []
var font: Font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=world.hud.font
	for i in range(3):
		var index:=i
		var button:=Button.new()
		button.add_theme_font_override("font",font)
		button.add_theme_font_size_override("font_size",17)
		button.pressed.connect(func(): world.expedition.choose(index))
		add_child(button)
		cards.append(button)

func _process(_delta: float) -> void:
	var options: Array=world.expedition.card_choices
	for i in range(3):
		cards[i].visible=i<options.size()
		if not cards[i].visible: continue
		var option: Dictionary=options[i]
		var grade: int=option.rarity
		var color: Color=[Color("cddbd9"),Color("e8bc60"),Color("bd87ee")][grade]
		var style: StyleBoxFlat=world.hud.panel(Color("172d2c"))
		style.border_color=color
		style.set_border_width_all(2)
		cards[i].add_theme_stylebox_override("normal",style)
		cards[i].add_theme_stylebox_override("hover",world.hud.panel(Color("304948")))
		cards[i].add_theme_color_override("font_color",color)
		cards[i].position=Vector2(size.x/2-414+i*282,size.y/2-75)
		cards[i].size=Vector2(264,200)
		var grade_name: String=world.say(["白卡","金卡","紫卡"][grade],["COMMON","GOLD","PURPLE"][grade])
		var value: String="+%d" % int(option.value) if option.id in ["projectiles","bounces"] else "+%d%%" % roundi(float(option.value)*100)
		cards[i].text="%d   %s\n\n%s\n\n%s" % [i+1,grade_name,world.say(option.zh,option.en),value]
	queue_redraw()

func _draw() -> void:
	if world.area!="dungeon" or world.stage!=3: return
	var director: Node=world.expedition
	if is_instance_valid(director.boss) and not director.boss.health.dead:
		var rect:=Rect2(size.x/2-225,126,450,10)
		draw_style_box(world.bar_style(Color("33202a")),rect)
		rect.size.x*=director.boss.health.current_hp/director.boss.health.get_max_hp()
		draw_style_box(world.bar_style(Color("c54e60")),rect)
		var title: String=world.say("破门者 · 哥布林首领","GATEBREAKER · GOBLIN CHIEFTAIN")
		var text_width:=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(font,Vector2((size.x-text_width)/2,120),title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f0d1be"))
	if director.card_choices.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.05,0.07,0.86))
	var title: String=world.say("波次完成 · 选择一项远征强化","WAVE COMPLETE · CHOOSE AN UPGRADE")
	var width:=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,25).x
	draw_string(font,Vector2((size.x-width)/2,size.y/2-124),title,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f0e8cf"))
	var note: String=world.say("点击卡片或按 1–3 · 选择期间暂停计时 · 强化在本次远征内有效","Click or press 1–3 · timer paused · upgrades last for this expedition")
	width=font.get_string_size(note,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	draw_string(font,Vector2((size.x-width)/2,size.y/2+162),note,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("aac6c8"))
