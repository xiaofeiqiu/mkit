class_name ContentService
extends Node
## 说明：`ContentService` 是 内容注册 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(ContentService.SERVICE_ID, ContentService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `ContentService`。
const SERVICE_ID: String = "content"
var _by_id: Dictionary = {}
var _by_type: Dictionary = {}
var _resource_path_by_id: Dictionary = {}


## 读取传入配置、资源或存档 payload 并写入运行时表；无效输入会返回失败或被跳过。
func load_database(database: ResourceDatabase) -> void:
	for res in database.get_all_resources():
		register_resource(res)


## 注册 `resource` 到运行时表；后续查询、路由或 facade 会使用该实例。
func register_resource(res: Resource) -> void:
	var content_id := _extract_content_id(res)
	if content_id == "":
		push_error("Resource missing stable content id: %s" % res)
		return
	if _by_id.has(content_id):
		push_error("Duplicate content id: %s" % content_id)
		return
	_by_id[content_id] = res
	for type_name in _get_resource_type_names(res):
		if not _by_type.has(type_name):
			_by_type[type_name] = []
		_by_type[type_name].append(res)
	if res.resource_path != "":
		_resource_path_by_id[content_id] = res.resource_path


## 读取当前对象中的 `resource`；未找到时返回 null、空集合或该 API 的默认值。
func get_resource(content_id: String) -> Resource:
	if not _by_id.has(content_id):
		push_warning("Content id not found: %s" % content_id)
		return null
	return _by_id[content_id]


## 读取当前对象中的 `typed_resource`；未找到时返回 null、空集合或该 API 的默认值。
func get_typed_resource(content_id: String, expected_script: Script) -> Resource:
	var res := get_resource(content_id)
	if res == null:
		return null
	if expected_script != null and res.get_script() != expected_script:
		push_error("ContentService: type mismatch for '%s'" % content_id)
		return null
	return res


## 读取当前对象中的 `all_by_type`；未找到时返回 null、空集合或该 API 的默认值。
func get_all_by_type(type_name: String) -> Array:
	if not _by_type.has(type_name):
		return []
	return _by_type[type_name]


## 执行 `has` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func has(content_id: String) -> bool:
	return _by_id.has(content_id)


## 执行 `validate_all` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func validate_all() -> ContentValidationResult:
	var result := ContentValidationResult.new()
	result.success = true
	for id in _by_id.keys():
		var res: Resource = _by_id[id]
		if id == "":
			result.add_error("Empty content id")
		if res == null:
			result.add_error("Null resource for id %s" % id)
	return result


func _extract_content_id(res: Resource) -> String:
	var def := res as ContentDefinition
	if def == null:
		return ""
	return def.get_content_id()


func _get_resource_type_names(res: Resource) -> Array[String]:
	if res == null:
		return ["Unknown"]
	var names: Array[String] = []
	var script := res.get_script() as Script
	if script != null:
		var global_name := str(script.get_global_name())
		if global_name != "":
			names.append(global_name)
		if script.resource_path != "":
			var file_name := script.resource_path.get_file().get_basename()
			if file_name != "" and not names.has(file_name):
				names.append(file_name)
	if names.is_empty():
		names.append(res.get_class())
	return names
