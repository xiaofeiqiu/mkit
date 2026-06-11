class_name DomainEvent
extends RefCounted
## 说明：`DomainEvent` 是 事件总线 的领域事件载荷，负责承载 EventService 发布和订阅时传递的数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在事件总线中复用这段契约或状态时使用它。
## 示例：`var instance := DomainEvent.new()`

## 运行时状态：`event_type` 表示 `DomainEvent` 的字段值，由 `DomainEvent` 的公开 API 读取或维护。
var event_type: String = ""
## 运行时状态：`event_id` 表示稳定 id，由 `DomainEvent` 的公开 API 读取或维护。
var event_id: String = ""
## 运行时状态：`timestamp` 表示 `DomainEvent` 的字段值，由 `DomainEvent` 的公开 API 读取或维护。
var timestamp: float = 0.0
## 运行时状态：`source_id` 表示稳定 id，由 `DomainEvent` 的公开 API 读取或维护。
var source_id: String = ""
## 运行时状态：`target_id` 表示稳定 id，由 `DomainEvent` 的公开 API 读取或维护。
var target_id: String = ""
## 运行时状态：`payload` 表示事件或存档载荷，由 `DomainEvent` 的公开 API 读取或维护。
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
