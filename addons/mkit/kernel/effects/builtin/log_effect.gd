class_name LogEffect
extends GameEffect
## 说明：`LogEffect` 是 效果管线 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := LogEffect.new()`

## 写入日志事件的文本内容；用于调试效果链或测试执行顺序。
@export var message: String = "log"
## 事件类型字符串；发布或匹配 DomainEvent 时必须与订阅方约定一致。
@export var event_type: String = "log"


## 子类覆写的实际效果入口，并保持 `LogEffect` 的领域契约一致。
func _apply_impl(context: GameplayContext) -> EffectResult:
	var source_id := _node_name(context.source)
	var target_id := _node_name(context.target)
	var events := ServiceRegistry.get_port(EventService.SERVICE_ID) as EventService
	if events != null:
		events.emit_domain_event(
			DomainEvent.create(event_type, source_id, target_id, {"message": message})
		)
	print("[LogEffect] %s (source=%s target=%s)" % [message, source_id, target_id])
	return EffectResult.ok(effect_id, {"message": message, "event_type": event_type})


func _node_name(node: Node) -> String:
	if node == null:
		return ""
	return str(node.name)
