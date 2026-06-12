class_name TargetInRangeCondition
extends Condition
## 说明：`TargetInRangeCondition` 是 条件系统 的条件对象，负责在 action、effect 或内容入口执行前判断是否允许继续。
## 上游：通常由 ConditionEvaluator、GameEffect、AbilityController 或内容定义创建或调用。
## 下游：会连接GameplayContext、组件和失败原因字符串，不直接依赖具体游戏内容。
## 使用：当项目内容入口需要在执行前做可复用的规则判断时使用它。
## 示例：`var instance := TargetInRangeCondition.new()`

## 有效距离，单位为像素；0 或负数通常表示不做距离限制。
@export var range: float = 64.0


## 子类覆写的实际条件判断入口，并保持 `TargetInRangeCondition` 的领域契约一致。
func _evaluate_impl(context: GameplayContext) -> bool:
	var source_2d := context.source as Node2D
	var target_2d := context.target as Node2D
	if source_2d == null or target_2d == null:
		return false
	return source_2d.global_position.distance_to(target_2d.global_position) <= range


## 返回 `failure_reason` 对应的数据或对象，并保持 `TargetInRangeCondition` 的领域契约一致。
func get_failure_reason(context: GameplayContext) -> String:
	return "target_out_of_range"
