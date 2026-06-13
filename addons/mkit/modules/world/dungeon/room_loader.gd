class_name RoomLoader
extends RefCounted
## 说明：`RoomLoader` 是 房间与一局流程系统 的加载器，负责把定义或路径解析为运行时场景。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在房间与一局流程系统中复用这段契约或状态时使用它。
## 示例：`var instance := RoomLoader.new()`


## 最近一次加载房间失败的错误文本；成功后应清空。
var last_error: String = ""


## 读取传入配置、资源或存档 payload 并写入运行时表；无效输入会返回失败或被跳过。
func load_room(room_definition_id: String, container: Node) -> RoomController:
	last_error = ""
	if room_definition_id.strip_edges() == "":
		last_error = "empty_room_definition_id"
		return null
	var content: ContentService = null
	content = Mkit.content()
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
