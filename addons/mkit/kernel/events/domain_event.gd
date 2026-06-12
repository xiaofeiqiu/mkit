class_name DomainEvent
extends RefCounted
## 说明：`DomainEvent` 是 事件总线 的领域事件载荷，负责承载 EventService 发布和订阅时传递的数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在事件总线中复用这段契约或状态时使用它。
## 示例：`var instance := DomainEvent.new()`

## 事件类型字符串；发布或匹配 DomainEvent 时必须与订阅方约定一致。
var event_type: String = ""
## DomainEvent 的唯一追踪 id；用于日志、去重和测试断言。
var event_id: String = ""
## 事件或命令创建时的时间戳，单位为秒；用于排序、调试和历史记录。
var timestamp: float = 0.0
## 事件、命令或修饰器来源 id；通常对应 EntityIdentity、系统或内容定义。
var source_id: String = ""
## 事件或命令目标 id；CommandService 可用它定位接收者。
var target_id: String = ""
## 附加上下文数据；key 由创建该对象的系统约定，读取前应检查是否存在。
var payload: Dictionary = {}


## 创建并返回新的运行时对象，并保持 `DomainEvent` 的领域契约一致。
static func create(
	type: String, source: String = "", target: String = "", data: Dictionary = {}
) -> DomainEvent:
	var e := DomainEvent.new()
	e.event_type = type
	e.event_id = "%s_%d" % [type, Time.get_ticks_usec()]
	e.timestamp = Time.get_ticks_msec() / 1000.0
	e.source_id = source
	e.target_id = target
	e.payload = data
	return e
