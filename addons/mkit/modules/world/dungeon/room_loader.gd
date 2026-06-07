class_name RoomLoader
extends RefCounted

var last_error: String = ""


func load_room(room_definition_id: String, container: Node) -> RoomController:
	last_error = ""
	if room_definition_id.strip_edges() == "":
		last_error = "empty_room_definition_id"
		return null
	var content: ContentService = null
	content = ServiceRegistry.get_port(ServiceRegistry.SERVICE_CONTENT) as ContentService
	if content == null:
		last_error = "missing_content_registry"
		return null
	var def := content.get_resource(room_definition_id) as RoomDefinition
	if def == null:
		last_error = "missing_room_definition:%s" % room_definition_id
		return null
	var scene := load(def.scene_path) as PackedScene
	if scene == null:
		last_error = "missing_room_scene:%s" % def.scene_path
		return null
	for child in container.get_children():
		child.queue_free()
	var room := scene.instantiate()
	if room == null:
		last_error = "cannot_instantiate_room_scene:%s" % def.scene_path
		return null
	container.add_child(room)
	var controller := room.get_node_or_null("RoomController") as RoomController
	if controller == null:
		last_error = "room_missing_controller"
		return null
	controller.setup(room_definition_id)
	return controller
