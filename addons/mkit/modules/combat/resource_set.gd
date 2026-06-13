class_name ResourceSet
extends RefCounted
## 说明：`ResourceSet` 是 战斗系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在战斗系统中复用这段契约或状态时使用它。
## 示例：`var instance := ResourceSet.new()`

## 资源当前值表；key 为资源 id，value 为数值。
var current: Dictionary = {}
## 查询资源上限的回调；未设置时 ResourceSet 只能使用传入的默认上限。
var max_value_provider: Callable = Callable()


## 更新当前对象中的 `max_provider`；输入值按该对象规则校验或夹取。
func set_max_provider(value: Callable) -> void:
	max_value_provider = value


## 读取当前对象中的 `current`；未找到时返回 null、空集合或该 API 的默认值。
func get_current(resource_id: String) -> float:
	return float(current.get(resource_id, get_max(resource_id)))


## 读取当前对象中的 `max`；未找到时返回 null、空集合或该 API 的默认值。
func get_max(resource_id: String) -> float:
	if max_value_provider == null or not max_value_provider.is_valid():
		return 0.0
	return float(max_value_provider.call(resource_id))


## 执行 `has` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func has(resource_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
	return get_current(resource_id) >= amount


## 更新当前对象中的 `current`；输入值按该对象规则校验或夹取。
func set_current(resource_id: String, value: float) -> void:
	var max_value := get_max(resource_id)
	current[resource_id] = clamp(value, 0.0, max_value)


## 尝试扣除指定资源或货币；成功会更新余额，失败保持原状态。
func spend(resource_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return true
	if not has(resource_id, amount):
		return false
	set_current(resource_id, get_current(resource_id) - amount)
	return true


## 执行 `restore` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func restore(resource_id: String, amount: float) -> void:
	if amount <= 0.0:
		return
	set_current(resource_id, get_current(resource_id) + amount)


## 清空本对象持有的运行时表和缓存；通常在测试或重新 bootstrap 前调用。
func clear() -> void:
	current.clear()


## 导出当前运行时状态给 SaveService；只包含恢复该对象所需字段。
func to_save_data() -> Dictionary:
	return current.duplicate(true)


## 从 SaveService 读出的 payload 恢复运行时字段；缺失字段保留当前默认值。
func from_save_data(data: Dictionary) -> void:
	current = {}
	for key in data.keys():
		current[str(key)] = float(data.get(key))
