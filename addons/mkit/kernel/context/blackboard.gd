class_name Blackboard
extends RefCounted
## 说明：`Blackboard` 是 执行上下文 的黑板数据，负责为状态机和 AI 保存可共享的键值状态。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在执行上下文中复用这段契约或状态时使用它。
## 示例：`var instance := Blackboard.new()`

var _data: Dictionary = {}


## 更新当前对象中的 `value`；输入值按该对象规则校验或夹取。
func set_value(key: String, value) -> void:
	_data[key] = value


## 读取当前对象中的 `value`；未找到时返回 null、空集合或该 API 的默认值。
func get_value(key: String, default_value = null):
	if _data.has(key):
		return _data[key]
	return default_value


## 检查当前集合或对象是否包含 `value`；缺失或空值时返回 false。
func has_value(key: String) -> bool:
	return _data.has(key)


## 执行 `erase_value` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func erase_value(key: String) -> void:
	_data.erase(key)


## 清空本对象持有的运行时表和缓存；通常在测试或重新 bootstrap 前调用。
func clear() -> void:
	_data.clear()


## 导出面向调试显示的 Dictionary；不会改变运行时状态。
func to_debug_dict() -> Dictionary:
	return _data.duplicate(true)
