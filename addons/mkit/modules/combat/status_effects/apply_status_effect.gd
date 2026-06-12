class_name ApplyStatusEffect
extends GameEffect
## 说明：`ApplyStatusEffect` 是 状态效果系统 的效果对象，负责由 EffectService 执行并把结果落到服务或组件。
## 上游：通常由 GameAction、EffectService、对话、任务、物品或奖励定义创建或调用。
## 下游：会连接GameplayContext、ConditionEvaluator、领域服务和 EffectResult，不直接依赖具体游戏内容。
## 使用：当项目内容资源需要以数据驱动方式改变世界、实体或服务状态时使用它。
## 示例：`var instance := ApplyStatusEffect.new()`

## 引用的 StatusEffectDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var status_id: String = ""
## 状态或效果层数；应大于 0，并受定义的最大层数限制。
@export var stacks: int = 1
## 覆盖状态默认持续时间的秒数；负数表示使用 StatusEffectDefinition.duration。
@export var duration_override: float = -1.0


## 子类覆写的实际效果入口，并保持 `ApplyStatusEffect` 的领域契约一致。
func _apply_impl(context: GameplayContext) -> EffectResult:
	var target := context.target
	if target == null:
		return EffectResult.fail(effect_id, "no_target")
	var controller := (
		EntityContract.get_controller(target, "StatusEffectController") as StatusEffectController
	)
	if controller == null:
		return EffectResult.fail(effect_id, "no_status_controller")
	var ok := controller.apply_status(status_id, context.source, stacks, duration_override)
	if not ok:
		return EffectResult.fail(effect_id, "apply_failed:%s" % status_id)
	return EffectResult.ok(effect_id, {"status_id": status_id})
