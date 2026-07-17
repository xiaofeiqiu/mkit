class_name RewardSelectionUI
extends Control
var options: Array[RewardOption] = []
var run_director: RunDirector = null


func setup(data: Dictionary) -> void:
	options = data.get("options", [])
	run_director = data.get("run_director", null)
	_render_options()


func _render_options() -> void:
	for i in range(options.size()):
		var option := options[i]
		var button := Button.new()
		button.text = "%d. %s\n%s" % [i + 1, option.display_name, option.description]
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82, 1.0))
		button.pressed.connect(func(): _on_option_selected(option))
		$OptionContainer.add_child(button)


func _on_option_selected(option: RewardOption) -> void:
	if run_director != null:
		run_director.select_reward(option)
	var ui: UIManager = null
	ui = Mkit.ui()
	if ui != null:
		ui.close_screen("reward_selection")
	else:
		queue_free()
