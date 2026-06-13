class_name Saveable
extends Node
## 说明：`Saveable` 是 存档系统 的存档参与者，负责提供 SaveService 可调用的存取档接口。
## 上游：通常由 SaveService 创建或调用。
## 下游：会连接SaveService 的 roots/entities/scopes 存档 envelope，不直接依赖具体游戏内容。
## 使用：当项目节点或对象需要参与 SaveService 的保存与恢复流程时使用它。
## 示例：`var instance := Saveable.new()`

## 存档系统定位该对象时使用的稳定 id；同一 save_scope 内应保持唯一。
@export var save_id: String = ""
## 保存分组名称；为空时使用 SaveService 的默认范围。
@export var save_scope: String = ""
## 恢复存档时的排序权重；数值越小越早恢复。
@export var restore_order: int = 0


## 读取当前对象中的 `save_scope`；未找到时返回 null、空集合或该 API 的默认值。
func get_save_scope() -> String:
	var normalized_scope := save_scope.strip_edges()
	if normalized_scope == "":
		return "global"
	return normalized_scope


## 读取当前对象中的 `save_scopes`；未找到时返回 null、空集合或该 API 的默认值。
func get_save_scopes() -> Array[String]:
	return [get_save_scope()]


## 读取当前对象中的 `save_payload_for_scope`；未找到时返回 null、空集合或该 API 的默认值。
func get_save_payload_for_scope(scope: String) -> Dictionary:
	if get_save_scope() == scope.strip_edges():
		return to_save_data()
	return {}


## 将传入 payload 或 effect 应用到目标对象；返回值、signal 或 event 表示实际结果。
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


## 从运行时表注销 `save_scopes`；后续查询或路由会走缺失分支。
func unregister_save_scopes() -> void:
	var save_service := ServiceRegistry.get_port(SaveService.SERVICE_ID) as SaveService
	if save_service != null:
		save_service.unregister_saveable_scope(self)


## 读取当前对象中的 `save_id`；未找到时返回 null、空集合或该 API 的默认值。
func get_save_id() -> String:
	if save_id == "":
		return owner.name if owner != null else name
	return save_id


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
func to_save_data() -> Dictionary:
	return {}


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
func from_save_data(data: Dictionary) -> void:
	pass
