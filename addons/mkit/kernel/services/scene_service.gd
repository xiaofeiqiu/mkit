class_name SceneService
extends Node
signal scene_change_requested(scene_path: String)
signal scene_changed(scene_path: String)
signal scene_change_failed(scene_path: String, reason: String)
var current_scene_path: String = ""
var transition_locked: bool = false


func change_scene(scene_path: String) -> bool:
	if transition_locked:
		scene_change_failed.emit(scene_path, "transition_locked")
		return false
	if scene_path == "":
		scene_change_failed.emit(scene_path, "empty_scene_path")
		return false
	transition_locked = true
	scene_change_requested.emit(scene_path)
	var error := get_tree().change_scene_to_file(scene_path)
	transition_locked = false
	if error != OK:
		scene_change_failed.emit(scene_path, "error_%d" % error)
		return false
	current_scene_path = scene_path
	scene_changed.emit(scene_path)
	return true


func reload_current_scene() -> bool:
	if current_scene_path == "":
		return false
	return change_scene(current_scene_path)
