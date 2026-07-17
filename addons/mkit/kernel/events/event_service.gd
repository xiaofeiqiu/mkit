class_name EventService
extends Node
## 说明：`EventService` 是 事件总线 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(EventService.SERVICE_ID, EventService.new())`

## 当 `EventService` 发生 `domain event emitted` 事件时发出，供 UI、音频、VFX、任务或测试订阅。
signal domain_event_emitted(event: DomainEvent)
## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `EventService`。
const SERVICE_ID: String = "events"
## 稳定标识 `ANY_EVENT`；用于事件、命令、类型或存档字段，调用方应引用常量避免手写字符串。
const ANY_EVENT: String = "*"
## EventService 最近发布的事件历史；用于调试、测试和轻量观察。
var recent_events: Array[DomainEvent] = []
## EventService 保留的事件数量上限；超过后丢弃最旧事件。
var max_recent_events: int = 100
var _subscribers: Dictionary = {}


## 发布 DomainEvent 到精确类型订阅者和 ANY_EVENT 订阅者，并同步发出 event_published signal。
func emit_domain_event(event: DomainEvent) -> void:
	if event == null:
		push_warning("EventService.emit_domain_event: event is null")
		return
	recent_events.append(event)
	if recent_events.size() > max_recent_events:
		recent_events.pop_front()
	domain_event_emitted.emit(event)
	_dispatch_to_subscribers(event)


## 便捷事件发布入口，会在方法内部构造 DomainEvent。
func emit_event(
	event_type: String, source_id: String = "", target_id: String = "", payload: Dictionary = {}
) -> void:
	emit_domain_event(DomainEvent.create(event_type, source_id, target_id, payload))


## 订阅指定事件类型；事件发出时调用 `callable(event: DomainEvent)`，重复订阅同一个 callable 不会产生重复注册。
func subscribe(event_type: String, callable: Callable) -> void:
	if event_type == "" or not callable.is_valid():
		push_warning("EventService.subscribe: invalid event_type or callable")
		return
	var listeners: Array = _subscribers.get(event_type, [])
	if listeners.has(callable):
		return
	listeners.append(callable)
	_subscribers[event_type] = listeners


## 执行 `unsubscribe` API；读取当前运行时状态，并通过返回值、signal 或事件报告结果。
func unsubscribe(event_type: String, callable: Callable) -> void:
	var listeners: Array = _subscribers.get(event_type, [])
	listeners.erase(callable)
	if listeners.is_empty():
		_subscribers.erase(event_type)


## 检查当前对象是否满足 `subscribed` 状态；调用方可据此选择后续流程。
func is_subscribed(event_type: String, callable: Callable) -> bool:
	var listeners: Array = _subscribers.get(event_type, [])
	return listeners.has(callable)


func _dispatch_to_subscribers(event: DomainEvent) -> void:
	var delivered: Array = []
	_dispatch_listener_group(event, event.event_type, delivered)
	if event.event_type != ANY_EVENT:
		_dispatch_listener_group(event, ANY_EVENT, delivered)


func _dispatch_listener_group(event: DomainEvent, event_type: String, delivered: Array) -> void:
	var listeners: Array = _subscribers.get(event_type, [])
	if listeners.is_empty():
		return
	var stale: Array = []
	for callable: Callable in listeners.duplicate():
		if delivered.has(callable):
			continue
		if callable.is_valid():
			callable.call(event)
			delivered.append(callable)
		else:
			stale.append(callable)
	for callable: Callable in stale:
		unsubscribe(event_type, callable)
