class_name UIManager
extends Node
signal screen_opened(screen_id: String)
signal screen_closed(screen_id: String)
@export var screen_root_path: NodePath = NodePath("ScreenRoot")
@export var screen_scene_map: Dictionary = {}
var screen_stack: Array[String] = []
var active_screens: Dictionary = {}
var modal_screens: Array[String] = []


func _ready() -> void:
	if not ServiceRegistry.has_service("ui"):
		ServiceRegistry.register_service("ui", self)


func open_screen(screen_id: String, data: Dictionary = {}, modal: bool = false) -> Node:
	if active_screens.has(screen_id):
		return active_screens[screen_id]
	if not screen_scene_map.has(screen_id):
		push_error("UIManager: unknown screen '%s'" % screen_id)
		return null
	var scene := load(screen_scene_map[screen_id]) as PackedScene
	if scene == null:
		push_error("UIManager: failed to load scene for screen '%s'" % screen_id)
		return null
	var screen := scene.instantiate()
	get_node(screen_root_path).add_child(screen)
	if screen.has_method("setup"):
		screen.setup(data)
	active_screens[screen_id] = screen
	screen_stack.append(screen_id)
	if modal:
		modal_screens.append(screen_id)
		_set_gameplay_paused(true)
	screen_opened.emit(screen_id)
	return screen


func close_screen(screen_id: String) -> void:
	if not active_screens.has(screen_id):
		return
	var screen := active_screens[screen_id] as Node
	active_screens.erase(screen_id)
	screen_stack.erase(screen_id)
	modal_screens.erase(screen_id)
	screen.queue_free()
	if modal_screens.is_empty():
		_set_gameplay_paused(false)
	screen_closed.emit(screen_id)


func close_top_screen() -> void:
	if screen_stack.is_empty():
		return
	close_screen(screen_stack[-1])


func is_screen_open(screen_id: String) -> bool:
	return active_screens.has(screen_id)


func _set_gameplay_paused(value: bool) -> void:
	if not ServiceRegistry.has_service("time"):
		return
	var time := ServiceRegistry.get_service("time") as TimeService
	if time != null:
		time.set_paused(value)
