extends CanvasLayer

var _visibility_pairs: Array[Array] = []


func _ready() -> void:
	_add_sibling_panel("StatsPanelBackdrop", "StatsPanel", 12, Color(0.04, 0.06, 0.08, 0.78))
	_add_sibling_panel("InstructionsBackdrop", "Instructions", 12, Color(0.05, 0.07, 0.07, 0.7))
	_add_inner_panel("QuestLogPanel", 10, Color(0.05, 0.08, 0.08, 0.68))
	_add_inner_panel("DialoguePanel", 12, Color(0.06, 0.05, 0.08, 0.84))
	_add_inner_panel("ShopPanel", 10, Color(0.05, 0.07, 0.06, 0.82))
	_style_text(self)


func _process(_delta: float) -> void:
	for pair in _visibility_pairs:
		var panel := pair[0] as Control
		var target := pair[1] as Control
		if panel != null and target != null:
			panel.visible = target.visible


func _add_sibling_panel(name: String, target_path: String, padding: int, color: Color) -> void:
	var target := get_node_or_null(NodePath(target_path)) as Control
	if target == null:
		return
	var panel := _make_panel(name, color)
	panel.anchor_left = target.anchor_left
	panel.anchor_top = target.anchor_top
	panel.anchor_right = target.anchor_right
	panel.anchor_bottom = target.anchor_bottom
	panel.offset_left = target.offset_left - padding
	panel.offset_top = target.offset_top - padding
	panel.offset_right = target.offset_right + padding
	panel.offset_bottom = target.offset_bottom + padding
	panel.z_index = target.z_index - 1
	add_child(panel)
	move_child(panel, target.get_index())
	_visibility_pairs.append([panel, target])


func _add_inner_panel(target_path: String, padding: int, color: Color) -> void:
	var target := get_node_or_null(NodePath(target_path)) as Control
	if target == null:
		return
	var panel := _make_panel("%sBackdrop" % str(target.name), color)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = -padding
	panel.offset_top = -padding
	panel.offset_right = padding
	panel.offset_bottom = padding
	panel.z_index = -1
	target.add_child(panel)
	target.move_child(panel, 0)


func _make_panel(name: String, color: Color) -> Panel:
	var panel := Panel.new()
	panel.name = name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.76, 0.82, 0.72, 0.18)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _style_text(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.9, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.03, 0.95))
		label.add_theme_constant_override("outline_size", 4)
	for child in node.get_children():
		_style_text(child)
