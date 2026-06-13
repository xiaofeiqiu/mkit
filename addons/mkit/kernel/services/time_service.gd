class_name TimeService
extends RefCounted
## 说明：`TimeService` 是 基础服务 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(TimeService.SERVICE_ID, TimeService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `TimeService`。
const SERVICE_ID: String = "time"
## 玩法时间是否暂停；暂停时 get_scaled_delta 返回 0。
var paused: bool = false
## 玩法时间缩放倍率；1 为原速，0 等价于暂停。
var gameplay_time_scale: float = 1.0
## 按玩法时间缩放累计的运行秒数；暂停时不会增加。
var elapsed_gameplay_time: float = 0.0


## 更新当前对象中的 `paused`；输入值按该对象规则校验或夹取。
func set_paused(value: bool) -> void:
	paused = value


## 更新当前对象中的 `gameplay_time_scale`；输入值按该对象规则校验或夹取。
func set_gameplay_time_scale(value: float) -> void:
	gameplay_time_scale = max(0.0, value)


## 读取当前对象中的 `scaled_delta`；未找到时返回 null、空集合或该 API 的默认值。
func get_scaled_delta(delta: float) -> float:
	if paused:
		return 0.0
	return delta * gameplay_time_scale


## 推进对应目标或流程进度；返回值、signal 或事件会表达实际执行结果。
func advance(delta: float) -> float:
	var scaled := get_scaled_delta(delta)
	elapsed_gameplay_time += scaled
	return scaled


## 读取当前对象中的 `unix_time`；未找到时返回 null、空集合或该 API 的默认值。
func get_unix_time() -> int:
	return Time.get_unix_time_from_system()
