class_name Condition
extends Resource
## 说明：`Condition` 是 条件系统 的条件对象，负责在 action、effect 或内容入口执行前判断是否允许继续。
## 上游：通常由 ConditionEvaluator、GameEffect、AbilityController 或内容定义创建或调用。
## 下游：会连接GameplayContext、组件和失败原因字符串，不直接依赖具体游戏内容。
## 使用：当项目内容入口需要在执行前做可复用的规则判断时使用它。
## 示例：`var instance := Condition.new()`

## 条件资源的稳定 id；日志、调试和需要按 id 引用条件的配置会使用它。
@export var condition_id: String = ""
## 是否反转条件结果；开启后 true/false 会在返回前互换。
@export var invert: bool = false


## 执行条件判断入口；会调用子类 hook 并记录失败原因。
func evaluate(context: GameplayContext) -> bool:
	var result := _evaluate_impl(context)
	if invert:
		return not result
	return result


## Condition 子类实现此 hook 完成实际判断；evaluate() 会调用它并记录失败原因。
func _evaluate_impl(context: GameplayContext) -> bool:
	return true


## 读取当前对象中的 `failure_reason`；未找到时返回 null、空集合或该 API 的默认值。
func get_failure_reason(context: GameplayContext) -> String:
	return "Condition failed: %s" % condition_id
