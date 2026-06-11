class_name ResourcePoolComponent
extends SaveableComponent
## 说明：`ResourcePoolComponent` 是 生命与资源系统 的实体组件，负责挂在实体场景下保存状态并暴露局部能力。
## 上游：通常由实体根节点、控制器、状态机或领域服务创建或调用。
## 下游：会连接EventService、SaveService、controller 或实体展示层，不直接依赖具体游戏内容。
## 使用：当项目实体需要持有可保存或可被 controller 查询的局部状态时使用它。
## 示例：`var instance := ResourcePoolComponent.new()`

## 当 `ResourcePoolComponent` 发生 `resource changed` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal resource_changed(resource_id: String, current: float, max_value: float)
## 当 `ResourcePoolComponent` 发生 `resource spent` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal resource_spent(resource_id: String, amount: float)
## 当 `ResourcePoolComponent` 发生 `resource restored` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal resource_restored(resource_id: String, amount: float)
## 编辑器配置：`starting_values` 表示 `ResourcePoolComponent` 的字段值，由 `ResourcePoolComponent` 的公开 API 读取或维护。
@export var starting_values: Dictionary = {}
## 运行时状态：`resources` 表示 `ResourcePoolComponent` 的字段值，由 `ResourcePoolComponent` 的公开 API 读取或维护。
var resources: ResourceSet = null
## 运行时状态：`stats` 表示 `ResourcePoolComponent` 的字段值，由 `ResourcePoolComponent` 的公开 API 读取或维护。
var stats: StatsComponent = null


func _ready() -> void:
	stats = EntityContract.get_component(owner, "StatsComponent") as StatsComponent
	resources = ResourceSet.new()
	resources.set_max_provider(_resolve_max_resource)
	resources.from_save_data(starting_values)


## 返回 `current` 对应的数据或对象，并保持 `ResourcePoolComponent` 的领域契约一致。
func get_current(resource_id: String) -> float:
	if resources == null:
		return get_max_resource(resource_id)
	return resources.get_current(resource_id)


## 返回 `max_resource` 对应的数据或对象，并保持 `ResourcePoolComponent` 的领域契约一致。
func get_max_resource(resource_id: String) -> float:
	if stats == null:
		return 0.0
	return stats.get_stat_value("max_%s" % resource_id, 0.0)


## 判断是否存在 `resource`，并保持 `ResourcePoolComponent` 的领域契约一致。
func has_resource(resource_id: String, amount: float) -> bool:
	if resources == null:
		return amount <= 0.0
	return resources.has(resource_id, amount)


## 扣除指定资源或货币，并保持 `ResourcePoolComponent` 的领域契约一致。
func spend(resource_id: String, amount: float) -> bool:
	if resources == null:
		return false
	if not resources.spend(resource_id, amount):
		return false
	set_current(resource_id, resources.get_current(resource_id))
	resource_spent.emit(resource_id, amount)
	return true


## 执行 `restore` 对应的公开操作，并保持 `ResourcePoolComponent` 的领域契约一致。
func restore(resource_id: String, amount: float) -> void:
	if resources == null:
		return
	var before := resources.get_current(resource_id)
	resources.restore(resource_id, amount)
	var after := resources.get_current(resource_id)
	set_current(resource_id, after)
	resource_restored.emit(resource_id, after - before)


## 设置 `current` 对应的数据或对象，并保持 `ResourcePoolComponent` 的领域契约一致。
func set_current(resource_id: String, value: float) -> void:
	var max_value := get_max_resource(resource_id)
	if resources == null:
		resources = ResourceSet.new()
		resources.set_max_provider(_resolve_max_resource)
	resources.set_current(resource_id, value)
	resource_changed.emit(resource_id, resources.get_current(resource_id), max_value)


## 导出当前运行时状态，供 SaveService 写入存档，并保持 `ResourcePoolComponent` 的领域契约一致。
func to_save_data() -> Dictionary:
	if resources == null:
		return {}
	return resources.to_save_data()


## 从 SaveService 读出的 payload 恢复运行时状态，并保持 `ResourcePoolComponent` 的领域契约一致。
func from_save_data(data: Dictionary) -> void:
	if resources == null:
		resources = ResourceSet.new()
		resources.set_max_provider(_resolve_max_resource)
	resources.from_save_data(data)


func _resolve_max_resource(resource_id: String) -> float:
	return get_max_resource(resource_id)
