class_name CooldownReadyCondition
extends Condition
## 说明：`CooldownReadyCondition` 是 能力系统 的条件对象，负责在 action、effect 或内容入口执行前判断是否允许继续。
## 上游：通常由 ConditionEvaluator、GameEffect、AbilityController 或内容定义创建或调用。
## 下游：会连接GameplayContext、组件和失败原因字符串，不直接依赖具体游戏内容。
## 使用：当项目内容入口需要在执行前做可复用的规则判断时使用它。
## 示例：`var instance := CooldownReadyCondition.new()`

## 编辑器配置：`ability_id` 表示稳定 id，由 `CooldownReadyCondition` 的公开 API 读取或维护。
@export var ability_id: String = ""


## 子类覆写的实际条件判断入口，并保持 `CooldownReadyCondition` 的领域契约一致。
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


## 返回 `failure_reason` 对应的数据或对象，并保持 `CooldownReadyCondition` 的领域契约一致。
func get_failure_reason(context: GameplayContext) -> String:
	var id := ability_id if ability_id != "" else str(context.get_payload_value("ability_id", ""))
	return "Cooldown not ready: %s" % id
