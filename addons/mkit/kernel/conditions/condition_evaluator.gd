class_name ConditionEvaluator
extends RefCounted
## 说明：`ConditionEvaluator` 是 条件系统 的公开 API 类型，负责承载该领域的可复用运行时数据或行为。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在条件系统中复用这段契约或状态时使用它。
## 示例：`var instance := ConditionEvaluator.new()`



## 执行 `evaluate_all` 对应的公开操作，并保持 `ConditionEvaluator` 的领域契约一致。
static func evaluate_all(conditions: Array[Condition], context: GameplayContext) -> bool:
	for condition in conditions:
		if condition == null:
			continue
		if not condition.evaluate(context):
			return false
	return true


## 执行 `collect_failures` 对应的公开操作，并保持 `ConditionEvaluator` 的领域契约一致。
static func collect_failures(
	conditions: Array[Condition], context: GameplayContext
) -> Array[String]:
	var failures: Array[String] = []
	for condition in conditions:
		if condition != null and not condition.evaluate(context):
			failures.append(condition.get_failure_reason(context))
	return failures
