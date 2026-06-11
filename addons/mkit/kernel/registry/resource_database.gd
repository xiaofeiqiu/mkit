class_name ResourceDatabase
extends Resource
## 说明：`ResourceDatabase` 是 内容注册 的资源数据库，负责把一组资源交给 ContentService 批量注册。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在内容注册中复用这段契约或状态时使用它。
## 示例：`var instance := ResourceDatabase.new()`

## 编辑器配置：`database_id` 表示稳定 id，由 `ResourceDatabase` 的公开 API 读取或维护。
@export var database_id: String = ""
## 编辑器配置：`resources` 表示 `ResourceDatabase` 的字段值，由 `ResourceDatabase` 的公开 API 读取或维护。
@export var resources: Array[Resource] = []
## 编辑器配置：`resource_paths` 表示资源或节点路径列表，由 `ResourceDatabase` 的公开 API 读取或维护。
@export var resource_paths: Array[String] = []


## 返回 `all_resources` 对应的数据或对象，并保持 `ResourceDatabase` 的领域契约一致。
func get_all_resources() -> Array[Resource]:
	var result: Array[Resource] = []
	result.append_array(resources)
	for path in resource_paths:
		var res: Resource = load(path)
		if res != null:
			result.append(res)
		else:
			push_warning("Failed to load resource: %s" % path)
	return result
