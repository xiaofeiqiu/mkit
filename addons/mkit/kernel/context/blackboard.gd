class_name Blackboard
extends RefCounted
## 说明：`Blackboard` 是 执行上下文 的黑板数据，负责为状态机和 AI 保存可共享的键值状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在执行上下文中复用这段契约或状态时使用它。
## 示例：`var instance := Blackboard.new()`

var _data: Dictionary = {}


## 设置 `value` 对应的数据或对象，并保持 `Blackboard` 的领域契约一致。
func set_value(key: String, value) -> void:
	_data[key] = value


## 返回 `value` 对应的数据或对象，并保持 `Blackboard` 的领域契约一致。
func get_value(key: String, default_value = null):
	if _data.has(key):
		return _data[key]
	return default_value


## 判断是否存在 `value`，并保持 `Blackboard` 的领域契约一致。
func has_value(key: String) -> bool:
	return _data.has(key)


## 执行 `erase_value` 对应的公开操作，并保持 `Blackboard` 的领域契约一致。
func erase_value(key: String) -> void:
	_data.erase(key)


## 清理当前保存的运行时状态或缓存，并保持 `Blackboard` 的领域契约一致。
func clear() -> void:
	_data.clear()


## 执行 `to_debug_dict` 对应的公开操作，并保持 `Blackboard` 的领域契约一致。
func to_debug_dict() -> Dictionary:
	return _data.duplicate(true)
