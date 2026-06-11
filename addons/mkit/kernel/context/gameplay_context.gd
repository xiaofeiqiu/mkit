class_name GameplayContext
extends RefCounted
## 说明：`GameplayContext` 是 执行上下文 的上下文对象，负责承载一次执行链路中的来源、目标、服务和附加数据。
## 上游：通常由命令、动作、效果、服务或测试夹具创建或调用。
## 下游：会连接ActionService、EffectService、GameEffect 和领域服务，不直接依赖具体游戏内容。
## 使用：当项目一次动作、效果或服务调用需要携带来源、目标和附加数据时使用它。
## 示例：`var instance := GameplayContext.new()`

## 运行时状态：`source` 表示 `GameplayContext` 的字段值，由 `GameplayContext` 的公开 API 读取或维护。
var source: Node = null
## 运行时状态：`target` 表示 `GameplayContext` 的字段值，由 `GameplayContext` 的公开 API 读取或维护。
var target: Node = null
## 运行时状态：`instigator` 表示 `GameplayContext` 的字段值，由 `GameplayContext` 的公开 API 读取或维护。
var instigator: Node = null
## 运行时状态：`position` 表示 `GameplayContext` 的字段值，由 `GameplayContext` 的公开 API 读取或维护。
var position: Vector2 = Vector2.ZERO
## 运行时状态：`direction` 表示 `GameplayContext` 的字段值，由 `GameplayContext` 的公开 API 读取或维护。
var direction: Vector2 = Vector2.ZERO
## 运行时状态：`tags` 表示标签集合，由 `GameplayContext` 的公开 API 读取或维护。
var tags: Array[String] = []
## 运行时状态：`payload` 表示事件或存档载荷，由 `GameplayContext` 的公开 API 读取或维护。
var payload: Dictionary = {}


## 执行 `from_nodes` 对应的公开操作，并保持 `GameplayContext` 的领域契约一致。
static func from_nodes(source_node: Node = null, target_node: Node = null) -> GameplayContext:
	var ctx := GameplayContext.new()
	ctx.source = source_node
	ctx.target = target_node
	return ctx


## 执行 `from_context` 对应的公开操作，并保持 `GameplayContext` 的领域契约一致。
static func from_context(context: GameplayContext = null) -> GameplayContext:
	return context if context != null else GameplayContext.new()


## 执行 `from_command` 对应的公开操作，并保持 `GameplayContext` 的领域契约一致。
static func from_command(
	command: GameCommand, source_node: Node = null, target_node: Node = null
) -> GameplayContext:
	var ctx := from_nodes(source_node, target_node)
	ctx.payload = command.payload.duplicate(true)
	ctx.direction = command.get_vector2("direction", Vector2.ZERO)
	ctx.position = command.get_vector2("position", Vector2.ZERO)
	return ctx


## 执行 `with_source` 对应的公开操作，并保持 `GameplayContext` 的领域契约一致。
func with_source(node: Node) -> GameplayContext:
	source = node
	return self


## 执行 `with_target` 对应的公开操作，并保持 `GameplayContext` 的领域契约一致。
func with_target(node: Node) -> GameplayContext:
	target = node
	return self


## 执行 `with_payload_value` 对应的公开操作，并保持 `GameplayContext` 的领域契约一致。
func with_payload_value(key: String, value) -> GameplayContext:
	payload[key] = value
	return self


## 返回 `payload_value` 对应的数据或对象，并保持 `GameplayContext` 的领域契约一致。
func get_payload_value(key: String, default_value = null):
	if payload.has(key):
		return payload[key]
	return default_value


## 判断是否存在 `tag`，并保持 `GameplayContext` 的领域契约一致。
func has_tag(tag: String) -> bool:
	return tags.has(tag)
