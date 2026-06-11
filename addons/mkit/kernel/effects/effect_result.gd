class_name EffectResult
extends RefCounted
## 说明：`EffectResult` 是 效果管线 的结果对象，负责承载一次领域操作的成功状态和输出数据。
## 上游：通常由同领域服务、controller、组件或内容资源创建或调用。
## 下游：会连接 mkit 的服务、组件、资源或事件管线，不直接依赖具体游戏内容。
## 使用：当项目需要在效果管线中复用这段契约或状态时使用它。
## 示例：`var instance := EffectResult.new()`

## 运行时状态：`success` 表示 `EffectResult` 的字段值，由 `EffectResult` 的公开 API 读取或维护。
var success: bool = true
## 运行时状态：`effect_id` 表示稳定 id，由 `EffectResult` 的公开 API 读取或维护。
var effect_id: String = ""
## 运行时状态：`failure_reason` 表示 `EffectResult` 的字段值，由 `EffectResult` 的公开 API 读取或维护。
var failure_reason: String = ""
## 运行时状态：`payload` 表示事件或存档载荷，由 `EffectResult` 的公开 API 读取或维护。
var payload: Dictionary = {}
## 运行时状态：`child_results` 表示执行结果集合，由 `EffectResult` 的公开 API 读取或维护。
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
