extends Node2D

@export_enum("village", "field", "room", "trial_01", "trial_02", "trial_03")
var scene_style: String = "village"


func _ready() -> void:
	match scene_style:
		"field":
			_build_field()
		"room":
			_build_room()
		"trial_01":
			_build_trial(Color(0.35, 0.54, 0.86, 0.22), Color(0.15, 0.17, 0.23, 1.0))
		"trial_02":
			_build_trial(Color(0.25, 0.78, 0.66, 0.2), Color(0.12, 0.2, 0.22, 1.0))
		"trial_03":
			_build_trial(Color(0.92, 0.32, 0.28, 0.2), Color(0.22, 0.14, 0.16, 1.0))
		_:
			_build_village()


func _build_village() -> void:
	_ellipse("RoomFocusGlow", Vector2(320, 174), Vector2(78, 46), Color(1.0, 0.76, 0.32, 0.24), -2)
	_ellipse("FieldGateFocusGlow", Vector2(610, 260), Vector2(78, 56), Color(0.28, 0.84, 0.78, 0.2), -2)
	_ellipse("ShopFocusGlow", Vector2(105, 185), Vector2(62, 42), Color(1.0, 0.85, 0.42, 0.2), -2)
	_poly(
		"VillageCenterLight",
		PackedVector2Array([
			Vector2(170, 172), Vector2(508, 142), Vector2(660, 252), Vector2(458, 392),
			Vector2(128, 342)
		]),
		Color(1.0, 0.87, 0.48, 0.1),
		-3
	)
	for point in [
		Vector2(238, 354), Vector2(272, 372), Vector2(526, 354), Vector2(706, 336),
		Vector2(72, 312), Vector2(444, 148), Vector2(758, 210)
	]:
		_flower_cluster(point)


func _build_field() -> void:
	_rect("FieldBase", Rect2(-220, -130, 1160, 750), Color(0.07, 0.18, 0.2, 1.0), -40)
	_poly(
		"MainTrail",
		PackedVector2Array([
			Vector2(116, 244), Vector2(226, 214), Vector2(380, 206), Vector2(560, 228),
			Vector2(600, 304), Vector2(382, 334), Vector2(202, 324), Vector2(90, 304)
		]),
		Color(0.43, 0.39, 0.27, 0.9),
		-20
	)
	_poly(
		"CaveTrail",
		PackedVector2Array([
			Vector2(504, 196), Vector2(610, 100), Vector2(700, 122), Vector2(654, 190),
			Vector2(560, 246)
		]),
		Color(0.35, 0.32, 0.27, 0.78),
		-19
	)
	_ellipse("CombatArena", Vector2(470, 246), Vector2(138, 86), Color(0.19, 0.45, 0.38, 0.62), -18)
	_ellipse("CaveAura", Vector2(650, 135), Vector2(102, 76), Color(0.52, 0.34, 0.95, 0.28), -18)
	_ellipse("GateAura", Vector2(160, 280), Vector2(88, 58), Color(0.3, 0.8, 0.82, 0.22), -18)
	for point in [
		Vector2(-64, 12), Vector2(18, 430), Vector2(770, 42), Vector2(806, 408),
		Vector2(278, 90), Vector2(684, 344)
	]:
		_tree(point)
	for point in [
		Vector2(300, 298), Vector2(338, 184), Vector2(584, 174), Vector2(704, 242),
		Vector2(198, 216), Vector2(542, 342), Vector2(442, 134)
	]:
		_stone(point)
	for point in [
		Vector2(228, 374), Vector2(328, 356), Vector2(622, 72), Vector2(726, 184),
		Vector2(92, 216), Vector2(514, 396)
	]:
		_grass(point)


func _build_room() -> void:
	_rect("RoomBase", Rect2(-220, -130, 1160, 750), Color(0.14, 0.13, 0.18, 1.0), -40)
	for x in range(-180, 880, 80):
		_rect("FloorPlank%s" % x, Rect2(x, -90, 44, 650), Color(0.2, 0.18, 0.24, 0.28), -30)
	_poly(
		"RugBorder",
		PackedVector2Array([
			Vector2(96, 154), Vector2(546, 154), Vector2(566, 338), Vector2(100, 350)
		]),
		Color(0.62, 0.36, 0.2, 0.62),
		-20
	)
	_poly(
		"RugCenter",
		PackedVector2Array([
			Vector2(128, 182), Vector2(516, 180), Vector2(524, 318), Vector2(126, 320)
		]),
		Color(0.42, 0.15, 0.24, 0.82),
		-19
	)
	_rect("BookcaseLeft", Rect2(606, 96, 74, 202), Color(0.24, 0.15, 0.1, 1.0), -5)
	_rect("BookcaseRight", Rect2(704, 118, 74, 174), Color(0.25, 0.16, 0.1, 1.0), -5)
	for i in range(5):
		_rect("BookLeft%s" % i, Rect2(616, 116 + i * 31, 54, 12), _book_color(i), -4)
		_rect("BookRight%s" % i, Rect2(714, 136 + i * 27, 54, 12), _book_color(i + 2), -4)
	_ellipse("HearthGlow", Vector2(406, 194), Vector2(170, 104), Color(1.0, 0.62, 0.22, 0.22), -4)
	_ellipse("DoorGlow", Vector2(180, 364), Vector2(82, 52), Color(0.95, 0.52, 0.24, 0.18), -4)
	_rect("Desk", Rect2(334, 216, 148, 48), Color(0.34, 0.2, 0.12, 1.0), -3)
	_rect("Parchment", Rect2(382, 222, 54, 26), Color(0.82, 0.7, 0.48, 1.0), -2)


func _build_trial(accent: Color, base: Color) -> void:
	_rect("TrialBase", Rect2(-80, -60, 840, 560), base, -40)
	_rect("TopWall", Rect2(-80, -60, 840, 74), Color(0.06, 0.06, 0.08, 0.76), -22)
	_rect("BottomWall", Rect2(-80, 432, 840, 68), Color(0.05, 0.05, 0.07, 0.82), -22)
	_rect("LeftWall", Rect2(-80, -60, 72, 560), Color(0.04, 0.04, 0.06, 0.74), -22)
	_rect("RightWall", Rect2(688, -60, 72, 560), Color(0.04, 0.04, 0.06, 0.74), -22)
	_ellipse("CenterRuneOuter", Vector2(410, 258), Vector2(172, 108), accent, -18)
	_ellipse("CenterRuneInner", Vector2(410, 258), Vector2(98, 60), Color(accent.r, accent.g, accent.b, 0.18), -17)
	for point in [Vector2(100, 90), Vector2(660, 90), Vector2(100, 390), Vector2(660, 390)]:
		_torch(point, accent)
	for point in [
		Vector2(216, 152), Vector2(312, 374), Vector2(584, 212), Vector2(496, 360)
	]:
		_stone(point)


func _rect(name: String, rect: Rect2, color: Color, z: int) -> ColorRect:
	var node := ColorRect.new()
	node.name = name
	node.offset_left = rect.position.x
	node.offset_top = rect.position.y
	node.offset_right = rect.position.x + rect.size.x
	node.offset_bottom = rect.position.y + rect.size.y
	node.color = color
	node.z_index = z
	add_child(node)
	return node


func _poly(name: String, points: PackedVector2Array, color: Color, z: int) -> Polygon2D:
	var node := Polygon2D.new()
	node.name = name
	node.polygon = points
	node.color = color
	node.z_index = z
	add_child(node)
	return node


func _ellipse(name: String, center: Vector2, radii: Vector2, color: Color, z: int) -> Polygon2D:
	var points := PackedVector2Array()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return _poly(name, points, color, z)


func _tree(center: Vector2) -> void:
	_ellipse("TreeShadow%s" % str(center), center + Vector2(0, 32), Vector2(64, 24), Color(0, 0, 0, 0.24), -16)
	_rect("TreeTrunk%s" % str(center), Rect2(center.x - 10, center.y + 12, 20, 46), Color(0.24, 0.14, 0.07, 1.0), -13)
	_ellipse("TreeCanopyA%s" % str(center), center + Vector2(-18, -8), Vector2(54, 42), Color(0.12, 0.36, 0.2, 1.0), -12)
	_ellipse("TreeCanopyB%s" % str(center), center + Vector2(24, -2), Vector2(52, 40), Color(0.16, 0.48, 0.24, 1.0), -11)
	_ellipse("TreeCanopyC%s" % str(center), center + Vector2(2, -30), Vector2(48, 36), Color(0.24, 0.58, 0.26, 1.0), -10)


func _stone(center: Vector2) -> void:
	_poly(
		"Stone%s" % str(center),
		PackedVector2Array([
			center + Vector2(-18, 4), center + Vector2(-10, -12), center + Vector2(12, -14),
			center + Vector2(22, 2), center + Vector2(8, 14), center + Vector2(-14, 12)
		]),
		Color(0.46, 0.48, 0.45, 1.0),
		-8
	)


func _grass(center: Vector2) -> void:
	_ellipse("Grass%s" % str(center), center, Vector2(46, 22), Color(0.18, 0.44, 0.24, 0.74), -15)
	_flower_cluster(center + Vector2(4, -4))


func _flower_cluster(center: Vector2) -> void:
	for i in range(5):
		var offset := Vector2(cos(float(i) * 1.7) * 18.0, sin(float(i) * 1.3) * 10.0)
		_ellipse(
			"Flower%s_%d" % [str(center), i],
			center + offset,
			Vector2(4, 3),
			[Color(1.0, 0.78, 0.22, 1.0), Color(0.96, 0.42, 0.48, 1.0), Color(0.62, 0.74, 1.0, 1.0)][i % 3],
			-7
		)


func _torch(center: Vector2, accent: Color) -> void:
	_rect("TorchPost%s" % str(center), Rect2(center.x - 6, center.y - 16, 12, 48), Color(0.28, 0.16, 0.08, 1.0), -8)
	_ellipse("TorchGlow%s" % str(center), center + Vector2(0, -28), Vector2(44, 36), accent, -7)
	_poly(
		"TorchFlame%s" % str(center),
		PackedVector2Array([
			center + Vector2(0, -56), center + Vector2(12, -34), center + Vector2(0, -20),
			center + Vector2(-12, -34)
		]),
		Color(1.0, 0.74, 0.24, 0.92),
		-6
	)


func _book_color(index: int) -> Color:
	var colors := [
		Color(0.58, 0.16, 0.12, 1.0),
		Color(0.18, 0.36, 0.64, 1.0),
		Color(0.56, 0.46, 0.18, 1.0),
		Color(0.28, 0.54, 0.32, 1.0)
	]
	return colors[index % colors.size()]
