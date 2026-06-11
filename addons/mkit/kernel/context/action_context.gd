class_name ActionContext
extends GameplayContext
## 说明：`ActionContext` 是 执行上下文 的上下文对象，负责承载一次执行链路中的来源、目标、服务和附加数据。
## 上游：通常由命令、动作、效果、服务或测试夹具创建或调用。
## 下游：会连接ActionService、EffectService、GameEffect 和领域服务，不直接依赖具体游戏内容。
## 使用：当项目一次动作、效果或服务调用需要携带来源、目标和附加数据时使用它。
## 示例：`var instance := ActionContext.new()`

## 运行时状态：`duration` 表示持续时间，由 `ActionContext` 的公开 API 读取或维护。
var duration: float = 0.0
## 运行时状态：`phase` 表示 `ActionContext` 的字段值，由 `ActionContext` 的公开 API 读取或维护。
var phase: String = ""


## 执行 `from_nodes` 对应的公开操作，并保持 `ActionContext` 的领域契约一致。
static func from_nodes(source_node: Node = null, target_node: Node = null) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = source_node
	ctx.target = target_node
	return ctx


## 执行 `from_context` 对应的公开操作，并保持 `ActionContext` 的领域契约一致。
static func from_context(context: GameplayContext = null) -> ActionContext:
	var ctx := ActionContext.new()
	if context == null:
		return ctx
	ctx.source = context.source
	ctx.target = context.target
	ctx.instigator = context.instigator
	ctx.position = context.position
	ctx.direction = context.direction
	ctx.tags = context.tags.duplicate()
	ctx.payload = context.payload.duplicate(true) if context.payload != null else {}
	return ctx


## 执行 `from_command` 对应的公开操作，并保持 `ActionContext` 的领域契约一致。
static func from_command(
	command: GameCommand, source_node: Node = null, target_node: Node = null
) -> ActionContext:
	return from_context(GameplayContext.from_command(command, source_node, target_node))
