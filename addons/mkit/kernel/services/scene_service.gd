class_name SceneService
extends Node
## 说明：`SceneService` 是 基础服务 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(SceneService.SERVICE_ID, SceneService.new())`

## 当 `SceneService` 发生 `scene change requested` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal scene_change_requested(scene_path: String)
## 当 `SceneService` 发生 `scene changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal scene_changed(scene_path: String)
## 当 `SceneService` 发生 `scene change failed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal scene_change_failed(scene_path: String, reason: String)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `SceneService`。
const SERVICE_ID: String = "scenes"
## SceneService 当前加载场景的 res:// 路径；切换完成后更新。
var current_scene_path: String = ""
## 场景切换锁；为 true 时拒绝重入式切换请求。
var transition_locked: bool = false


## 执行 `change_scene` 对应的公开操作，并保持 `SceneService` 的领域契约一致。
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


## 执行 `reload_current_scene` 对应的公开操作，并保持 `SceneService` 的领域契约一致。
func reload_current_scene() -> bool:
	if current_scene_path == "":
		return false
	return change_scene(current_scene_path)
