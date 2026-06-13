class_name ActionContext
extends GameplayContext
## 说明：`ActionContext` 是 执行上下文 的上下文对象，负责承载一次执行链路中的来源、目标、服务和附加数据。
## 上游：通常由命令、动作、效果、服务或测试夹具创建或调用。
## 下游：会连接ActionService、EffectService、GameEffect 和领域服务，不直接依赖具体游戏内容。
## 使用：当项目一次动作、效果或服务调用需要携带来源、目标和附加数据时使用它。
## 示例：`var instance := ActionContext.new()`

## 动作请求的持续时间，单位为秒；0 表示调用方没有指定持续时间。
var duration: float = 0.0
## 动作或上下文当前阶段名称；空字符串表示没有显式阶段。
var phase: String = ""


## 从 source/target Node 创建上下文对象；payload 初始化为空，由后续 pipeline 写入字段。
static func from_nodes(source_node: Node = null, target_node: Node = null) -> ActionContext:
	var ctx := ActionContext.new()
	ctx.source = source_node
	ctx.target = target_node
	return ctx


## 复制已有上下文的 source、target 和 payload；传入 null 时返回空上下文。
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


## 从 GameCommand 构造执行上下文；会把 command payload 复制给 action/effect 使用。
static func from_command(
	command: GameCommand, source_node: Node = null, target_node: Node = null
) -> ActionContext:
	return from_context(GameplayContext.from_command(command, source_node, target_node))
