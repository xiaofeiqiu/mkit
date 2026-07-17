class_name CooldownReadyCondition
extends Condition
## 说明：`CooldownReadyCondition` 是 能力系统 的条件对象，负责在 action、effect 或内容入口执行前判断是否允许继续。
## 上游：通常由 ConditionEvaluator、GameEffect、AbilityController 或内容定义创建或调用。
## 下游：会连接GameplayContext、组件和失败原因字符串，不直接依赖具体游戏内容。
## 使用：当项目内容入口需要在执行前做可复用的规则判断时使用它。
## 示例：`var instance := CooldownReadyCondition.new()`

## 引用的 AbilityDefinition id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
@export var ability_id: String = ""


## Condition 子类实现此 hook 完成实际判断；evaluate() 会调用它并记录失败原因。
func _evaluate_impl(context: GameplayContext) -> bool:
	var id := ability_id if ability_id != "" else str(context.get_payload_value("ability_id", ""))
	if id == "" or context.source == null:
		return false
	var controller := (
		EntityContract.get_controller(context.source, "AbilityController") as AbilityController
	)
	if controller == null:
		return false
	return controller.is_cooldown_ready(id)


## 读取当前对象中的 `failure_reason`；未找到时返回 null、空集合或该 API 的默认值。
func get_failure_reason(context: GameplayContext) -> String:
	var id := ability_id if ability_id != "" else str(context.get_payload_value("ability_id", ""))
	return "Cooldown not ready: %s" % id
