class_name ResourceDatabase
extends Resource
## 说明：`ResourceDatabase` 是 内容注册 的资源数据库，负责把一组资源交给 ContentService 批量注册。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在内容注册中复用这段契约或状态时使用它。
## 示例：`var instance := ResourceDatabase.new()`

## 资源数据库自身的稳定 id；用于区分资源来源和校验重复配置。
@export var database_id: String = ""
## 直接内嵌注册的资源列表；每个资源应能提供非空 content id。
@export var resources: Array[Resource] = []
## 延迟加载并注册的资源路径列表；每项应指向可 load 的 Resource。
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
