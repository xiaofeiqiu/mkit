class_name GameEffect
extends Resource
## 说明：`GameEffect` 是 效果管线 的效果基类，负责统一执行条件检查并把子类效果落到具体领域。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在效果管线中复用这段契约或状态时使用它。
## 示例：`var instance := GameEffect.new()`

## 效果的稳定 id；用于日志、调试和需要按 id 引用效果的配置。
@export var effect_id: String = ""
## 执行前按顺序求值的条件列表；任一条件失败时阻止本对象继续产生效果。
@export var conditions: Array[Condition] = []
## 标签集合，用于条件筛选、事件追踪和 UI 分组；建议使用短小稳定的 String 标识。
@export var tags: Array[String] = []


## 执行 effect 前置条件；任一 condition 失败时返回失败 EffectResult，全部通过后调用 `_apply_impl()`。
func apply(context: GameplayContext) -> EffectResult:
	var failures := ConditionEvaluator.collect_failures(conditions, context)
	if not failures.is_empty():
		return EffectResult.fail(effect_id, ", ".join(failures))
	return _apply_impl(context)


## GameEffect 子类实现此 hook 完成实际效果；apply() 会调用它并返回 EffectResult。
func _apply_impl(context: GameplayContext) -> EffectResult:
	return EffectResult.ok(effect_id)
