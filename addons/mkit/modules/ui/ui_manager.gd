class_name UIManager
extends Node
## 说明：`UIManager` 是 UI 系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在UI 系统中复用这段契约或状态时使用它。
## 示例：`var instance := UIManager.new()`

## 当 `UIManager` 发生 `screen opened` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal screen_opened(screen_id: String)
## 当 `UIManager` 发生 `screen closed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal screen_closed(screen_id: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `UIManager`。
const SERVICE_ID: String = "ui"
## 编辑器配置：`screen_root_path` 表示资源或节点路径，由 `UIManager` 的公开 API 读取或维护。
@export var screen_root_path: NodePath = NodePath("ScreenRoot")
## 编辑器配置：`screen_scene_map` 表示 `UIManager` 的字段值，由 `UIManager` 的公开 API 读取或维护。
@export var screen_scene_map: Dictionary = {}
## 运行时状态：`screen_stack` 表示 `UIManager` 的字段值，由 `UIManager` 的公开 API 读取或维护。
var screen_stack: Array[String] = []
## 运行时状态：`active_screens` 表示是否启用或当前激活状态，由 `UIManager` 的公开 API 读取或维护。
var active_screens: Dictionary = {}
## 运行时状态：`modal_screens` 表示 `UIManager` 的字段值，由 `UIManager` 的公开 API 读取或维护。
var modal_screens: Array[String] = []


func _ready() -> void:
	if not ServiceRegistry.has_service(SERVICE_ID):
		ServiceRegistry.register_service(SERVICE_ID, self)


## 打开对应 UI 或流程入口，并保持 `UIManager` 的领域契约一致。
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


## 关闭对应 UI 或流程入口，并保持 `UIManager` 的领域契约一致。
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


## 关闭对应 UI 或流程入口，并保持 `UIManager` 的领域契约一致。
func close_top_screen() -> void:
	if screen_stack.is_empty():
		return
	close_screen(screen_stack[-1])


## 判断 `screen_open` 当前是否成立，并保持 `UIManager` 的领域契约一致。
func is_screen_open(screen_id: String) -> bool:
	return active_screens.has(screen_id)


func _set_gameplay_paused(value: bool) -> void:
	var time := Mkit.time()
	if time == null:
		return
	time.set_paused(value)
