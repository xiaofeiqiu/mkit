extends Node
## 说明：`ServiceRegistry` 是 基础服务 的服务注册表，负责保存内核和模块服务实例并提供低层查找入口。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在基础服务中复用这段契约或状态时使用它。
## 示例：`var instance := ServiceRegistry.new()`


var _services: Dictionary = {}


## 以 service_id 注册新的服务实例；空 id、null service 或重复 id 会输出 error 并返回 false。
func register_service(service_id: String, service: Object) -> bool:
	var id := service_id.strip_edges()
	if id == "":
		push_error("ServiceRegistry.register_service: service_id is empty")
		return false
	if service == null:
		push_error("ServiceRegistry.register_service: service is null for id %s" % service_id)
		return false
	if _services.has(id):
		push_error("Service already registered: %s. Use replace_service() for intentional overrides." % id)
		return false
	_services[id] = service
	return true


## 显式替换已经注册的服务；目标 id 缺失、空 id 或 null service 会输出 error 并返回 false。
func replace_service(service_id: String, service: Object) -> bool:
	var id := service_id.strip_edges()
	if id == "":
		push_error("ServiceRegistry.replace_service: service_id is empty")
		return false
	if service == null:
		push_error("ServiceRegistry.replace_service: service is null for id %s" % service_id)
		return false
	if not _services.has(id):
		push_error("ServiceRegistry.replace_service: missing service id %s" % id)
		return false
	_services[id] = service
	return true


## 检查去空白后的 service_id 是否已经注册；不会输出 missing-service warning。
func has_service(service_id: String) -> bool:
	return _services.has(service_id.strip_edges())


## 低层服务查找入口；缺失时会输出 warning。kernel 内部可直接使用，game/module 代码优先使用 `Mkit` 门面。
func get_port(service_id: String) -> Object:
	var id := service_id.strip_edges()
	if id == "":
		push_warning("ServiceRegistry.get_port: service_id is empty")
		return null
	var service := _services.get(id, null) as Object
	if service == null:
		push_warning("Missing service: %s" % id)
		return null
	return service


## 返回当前已注册 service id 的排序列表，供调试、文档示例和测试断言使用。
func get_registered_service_ids() -> Array[String]:
	var ids: Array[String] = []
	for service_id in _services.keys():
		ids.append(str(service_id))
	ids.sort()
	return ids


## 移除指定 service_id；空 id 会输出 warning，缺失 id 不报错。
func unregister_service(service_id: String) -> void:
	var id := service_id.strip_edges()
	if id == "":
		push_warning("ServiceRegistry.unregister_service: service_id is empty")
		return
	_services.erase(id)


## 清空本对象持有的运行时表和缓存；通常在测试或重新 bootstrap 前调用。
func clear() -> void:
	_services.clear()
