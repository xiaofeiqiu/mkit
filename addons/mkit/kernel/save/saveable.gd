class_name Saveable
extends Node
## 说明：`Saveable` 是 存档系统 的存档参与者，负责提供 SaveService 可调用的存取档接口。
## 上游：通常由 SaveService 创建或调用。
## 下游：会连接SaveService 的 roots/entities/scopes 存档 envelope，不直接依赖具体游戏内容。
## 使用：当项目节点或对象需要参与 SaveService 的保存与恢复流程时使用它。
## 示例：`var instance := Saveable.new()`

## 编辑器配置：`save_id` 表示稳定 id，由 `Saveable` 的公开 API 读取或维护。
@export var save_id: String = ""
## 编辑器配置：`save_scope` 表示 `Saveable` 的字段值，由 `Saveable` 的公开 API 读取或维护。
@export var save_scope: String = ""
## 编辑器配置：`restore_order` 表示 `Saveable` 的字段值，由 `Saveable` 的公开 API 读取或维护。
@export var restore_order: int = 0


## 返回 `save_scope` 对应的数据或对象，并保持 `Saveable` 的领域契约一致。
func get_save_scope() -> String:
	var normalized_scope := save_scope.strip_edges()
	if normalized_scope == "":
		return "global"
	return normalized_scope


## 返回 `save_scopes` 对应的数据或对象，并保持 `Saveable` 的领域契约一致。
func get_save_scopes() -> Array[String]:
	return [get_save_scope()]


## 返回 `save_payload_for_scope` 对应的数据或对象，并保持 `Saveable` 的领域契约一致。
func get_save_payload_for_scope(scope: String) -> Dictionary:
	if get_save_scope() == scope.strip_edges():
		return to_save_data()
	return {}


## 把输入数据或效果应用到目标对象，并保持 `Saveable` 的领域契约一致。
func apply_save_payload_for_scope(scope: String, data: Dictionary) -> bool:
	if get_save_scope() != scope.strip_edges():
		return false
	from_save_data(data)
	return true


## 多 scope payload 子类的注册辅助方法；从 `_ready()` / `_exit_tree()` 调用，用来保持 SaveService scope 注册同步。
func register_save_scopes() -> void:
	var save_service := ServiceRegistry.get_port(SaveService.SERVICE_ID) as SaveService
	if save_service != null:
		save_service.register_saveable_scope(self)


## 注销 `save_scopes`，停止后续查询或路由使用它，并保持 `Saveable` 的领域契约一致。
func unregister_save_scopes() -> void:
	var save_service := ServiceRegistry.get_port(SaveService.SERVICE_ID) as SaveService
	if save_service != null:
		save_service.unregister_saveable_scope(self)


## 返回 `save_id` 对应的数据或对象，并保持 `Saveable` 的领域契约一致。
func get_save_id() -> String:
	if save_id == "":
		return owner.name if owner != null else name
	return save_id


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `Saveable` 的领域契约一致。
func to_save_data() -> Dictionary:
	return {}


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `Saveable` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	pass
