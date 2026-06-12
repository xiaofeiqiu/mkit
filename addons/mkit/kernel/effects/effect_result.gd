class_name EffectResult
extends RefCounted
## 说明：`EffectResult` 是 效果管线 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在效果管线中复用这段契约或状态时使用它。
## 示例：`var instance := EffectResult.new()`

## 执行或校验是否成功；失败时同时查看 errors、warnings 或 failure_reason。
var success: bool = true
## 引用的 effect id；为空字符串表示未绑定，使用前应由调用方处理缺失情况。
var effect_id: String = ""
## 失败原因文本；success 为 false 时用于日志、测试断言或 UI 提示。
var failure_reason: String = ""
## 附加上下文数据；key 由创建该对象的系统约定，读取前应检查是否存在。
var payload: Dictionary = {}
## 复合效果产生的子结果列表；用于追踪每个子效果的成功与失败。
var child_results: Array[EffectResult] = []


## 执行 `ok` 对应的公开操作，并保持 `EffectResult` 的领域契约一致。
static func ok(id: String = "", data: Dictionary = {}) -> EffectResult:
	var r := EffectResult.new()
	r.success = true
	r.effect_id = id
	r.payload = data
	return r


## 执行 `fail` 对应的公开操作，并保持 `EffectResult` 的领域契约一致。
static func fail(id: String, reason: String) -> EffectResult:
	var r := EffectResult.new()
	r.success = false
	r.effect_id = id
	r.failure_reason = reason
	return r
