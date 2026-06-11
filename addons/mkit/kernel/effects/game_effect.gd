class_name GameEffect
extends Resource
## 说明：`GameEffect` 是 效果管线 的效果基类，负责统一执行条件检查并把子类效果落到具体领域。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在效果管线中复用这段契约或状态时使用它。
## 示例：`var instance := GameEffect.new()`

## 编辑器配置：`effect_id` 表示稳定 id，由 `GameEffect` 的公开 API 读取或维护。
@export var effect_id: String = ""
## 编辑器配置：`conditions` 表示执行条件列表，由 `GameEffect` 的公开 API 读取或维护。
@export var conditions: Array[Condition] = []
## 编辑器配置：`tags` 表示标签集合，由 `GameEffect` 的公开 API 读取或维护。
@export var tags: Array[String] = []


## 把输入数据或效果应用到目标对象，并保持 `GameEffect` 的领域契约一致。
func apply(context: GameplayContext) -> EffectResult:
	if not ConditionEvaluator.evaluate_all(conditions, context):
		var failures := ConditionEvaluator.collect_failures(conditions, context)
		return EffectResult.fail(effect_id, ", ".join(failures))
	return _apply_impl(context)


## 子类覆写的实际效果入口，并保持 `GameEffect` 的领域契约一致。
func _apply_impl(context: GameplayContext) -> EffectResult:
	return EffectResult.ok(effect_id)
