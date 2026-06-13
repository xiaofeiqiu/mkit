class_name EffectService
extends RefCounted
## 说明：`EffectService` 是 效果管线 的运行时服务，负责集中处理该领域的跨节点规则和查询。
## 上游：通常由 GameBootstrap、ModuleBootstrap、Mkit 门面或其他领域服务创建或调用。
## 下游：会连接 ContentService、EventService、组件、定义资源或场景节点，不直接依赖具体游戏内容。
## 使用：当项目需要从多个节点共享同一套领域规则或查询入口时使用它。
## 示例：`ServiceRegistry.register_service(EffectService.SERVICE_ID, EffectService.new())`

## 服务注册 id，供 GameBootstrap、ModuleBootstrap、ServiceRegistry 和 Mkit 查找 `EffectService`。
const SERVICE_ID: String = "effects"
## 已执行 effect 的调试环形缓冲区；默认关闭，调试 UI 或测试可显式开启。
var trace_enabled: bool = false
## EffectService 最近执行结果的环形历史；用于调试和测试观察。
var recent_results: Array[EffectResult] = []
## EffectService 保留的结果数量上限；超过后丢弃最旧结果。
var max_recent_results: int = 100


## 执行单个 GameEffect；effect 为空时返回失败 EffectResult，成功路径由 effect.apply(context) 决定。
func execute(effect: GameEffect, context: GameplayContext) -> EffectResult:
	if effect == null:
		return EffectResult.fail("null_effect", "Effect is null")
	var result := effect.apply(context)
	_record_result(result)
	return result


## 按顺序执行 GameEffect 列表并返回每个 EffectResult；stop_on_failure 为 true 时遇到失败立即停止。
func execute_many(
	effects: Array[GameEffect], context: GameplayContext, stop_on_failure: bool = false
) -> Array[EffectResult]:
	var results: Array[EffectResult] = []
	for effect in effects:
		var result := execute(effect, context)
		results.append(result)
		if stop_on_failure and not result.success:
			break
	return results


## 清空 recent_results 调试历史；不会影响 effect 执行逻辑或 trace_enabled 设置。
func clear_recent_results() -> void:
	recent_results.clear()


func _record_result(result: EffectResult) -> void:
	if not trace_enabled:
		return
	recent_results.append(result)
	if recent_results.size() > max_recent_results:
		recent_results.pop_front()
